-- Submodule for process name registering in distributed mode.
module('concurrent._distributed._register', package.seeall)

require 'cltime'

nameslocks = {}                 -- Locking during registration negotiations.

concurrent._option.options.registertimeout = 10 * 1000  -- Registration timeout.
concurrent._option.options.registerlocktimeout = 30 * 1000      -- Lock timeout.

-- The existing versions of the functions for process registering are renamed.
_register = concurrent._register.register
_unregister = concurrent._register.unregister
_whereis = concurrent._register.whereis

-- Registers a PID with the specified name.  If the process is local the old
-- renamed version of the function is called, otherwise an auxiliary system
-- process, to handle negotiation on the name with the rest of the nodes, is
-- created.  Returns true if successful or false otherwise.
function register(name, pid)
    if not concurrent.node() and not concurrent.getoption('connectall') then
        return _register(name, pid)
    end

    if concurrent.whereis(name) then
        return false
    end
    if not pid then
        pid = concurrent.self()
    end
    if #concurrent.nodes() == 0 then
        concurrent._register.names[name] = { pid, concurrent.node() }
        return true
    end
    concurrent._distributed._process.spawn_system(register_process,
        concurrent.self(), name, pid)
    local msg = concurrent._scheduler.wait()
    if msg.status then
        concurrent._register.names[name] = { pid, concurrent.node() }
    end
    return msg.status, msg.errmsg
end

-- The auxiliary system process that negotiates on registering a name with the
-- rest of the nodes.  The negotiation is based on a two phase commit protocol.
-- The role of the coordinator plays the node that the register request
-- originated from.  First the coordinator asks for locking of a specific name
-- from all nodes, and if this was successful and a commit message is then sent
-- to all the nodes.
function register_process(parent, name, pid)
    local connections = concurrent._distributed._network.connections
    local barriers = concurrent._scheduler.barriers
    local locks = {}
    local commits = {}
    local n = 0

    for k, _ in pairs(connections) do
        locks[k] = false
        commits[k] = false
        n = n + 1
    end

    for k, _ in pairs(connections) do
        concurrent.send({ -1, k }, { subject = 'REGISTER', phase = 'LOCK',
             from = { pid = concurrent.self(), node = concurrent.node() },
             name = name, pid = pid, node = concurrent.node() })
    end

    local i = 0
    local timer = cltime.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - cltime.time())
        if msg and msg.phase == 'LOCK' then
            locks[msg.from.node] = true
            i = i + 1
        end
    until cltime.time() >= timer or i >= n

    for _, v in pairs(locks) do
        if not v then
            barriers[parent] = { status = false, errmsg = 'lock failed' }
            return
        end
    end

    for k, _ in pairs(connections) do
        concurrent.send({ -1, k }, { subject = 'REGISTER', phase = 'COMMIT', 
            from = { pid = concurrent.self(), node = concurrent.node() },
            name = name, pid = pid, node = concurrent.node() })
    end

    local i = 0
    local timer = cltime.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - cltime.time())
        if msg and msg.phase == 'COMMIT' then
            commits[msg.from.node] = true
            i = i + 1
        end
    until cltime.time() >= timer or i >= n

    for _, v in pairs(commits) do
        if not v then
            barriers[parent] = { status = false, errmsg = 'commit failed' }
            return
        end
    end

    barriers[parent] = { status = true }
end

-- Handles register requests in distributed mode.
function controller_register(msg)
    if msg.phase == 'LOCK' then
        if not concurrent.whereis(msg.name) and not nameslocks[msg.name] or
            cltime.time() - nameslocks[msg.name]['stamp'] <
            concurrent.getoption('registerlocktimeout') then
            nameslocks[msg.name] = { pid = msg.pid, node = msg.node,
                stamp = cltime.time() }
            concurrent.send({ msg.from.pid, msg.from.node }, { phase = 'LOCK',
                from = { node = concurrent.node() } })
        end
    elseif msg.phase == 'COMMIT' then
        if nameslocks[msg.name] and
            nameslocks[msg.name]['pid'] == msg.pid and
            nameslocks[msg.name]['node'] == msg.node then
            concurrent._register.register(msg.name, { msg.pid, msg.node })
            concurrent.send({ msg.from.pid, msg.from.node }, { phase = 'COMMIT',
                from = { node = concurrent.node() } })
            nameslocks[msg.name] = nil
        end
    end
end

-- Unegisters a PID with the specified name.  If the process is local the old
-- renamed version of the function is called, otherwise an auxiliary system
-- process, to handle negotiation on the name with ther rest of the nodes, is
-- created.  Returns true if successful or false otherwise.
function unregister(name)
    if not concurrent.node() and not concurrent.getoption('connectall') then
        return _unregister(name)
    end

    for k, v in pairs(concurrent._register.names) do
        if name == k and concurrent.node() == v[2] then
            if #concurrent.nodes() == 0 then
                concurrent._register.names[name] = nil
                return
            end
            concurrent._distributed._process.spawn_system(unregister_process,
                concurrent.self(), k)
            local msg = concurrent._scheduler.wait()
            if msg.status then
                concurrent._register.names[name] = nil
            end
            return msg.status, msg.errmsg
        end
    end
end

-- The auxiliary system process that negotiates on unregistering a name with the
-- rest of the nodes.  The negotiation is similar to the register operation.
function unregister_process(parent, name)
    local connections = concurrent._distributed._network.connections
    local barriers = concurrent._scheduler.barriers
    local locks = {}
    local commits = {}
    local n = 0

    for k, _ in pairs(connections) do
        locks[k] = false
        commits[k] = false
        n = n + 1
    end

    for k, _ in pairs(connections) do
        concurrent.send({ -1, k }, { subject = 'UNREGISTER', phase = 'LOCK', 
            from = { pid = concurrent.self(), node = concurrent.node() },
            name = name })
    end

    local i = 0
    local timer = cltime.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - cltime.time())
        if msg and msg.phase == 'LOCK' then
            locks[msg.from.node] = true
            i = i + 1
        end
    until cltime.time() > timer or i >= n

    for _, v in pairs(locks) do
        if not v then
            barriers[parent] = { status = false, errmsg = 'lock failed' }
            return
        end
    end

    for k, _ in pairs(connections) do
        concurrent.send({ -1, k }, { subject = 'UNREGISTER', phase = 'COMMIT', 
            from = { pid = concurrent.self(), node = concurrent.node() },
            name = name })
    end

    local i = 0
    local timer = cltime.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - cltime.time())
        if msg and msg.phase == 'COMMIT' then
            commits[msg.from.node] = true
            i = i + 1
        end
    until cltime.time() > timer or i >= n

    for _, v in pairs(commits) do
        if not v then
            barriers[parent] = { status = false, errmsg = 'commit failed' }
            return
        end
    end

    barriers[parent] = { status = true }
end

-- Handles unregister requests in distributed mode.
function controller_unregister(msg)
    if msg.phase == 'LOCK' then
        if concurrent.whereis(msg.name) and not nameslocks[msg.name] or
            cltime.time() - nameslocks[msg.name]['stamp'] <
            concurrent.getoption('registerlocktimeout') then
            nameslocks[msg.name] = { pid = msg.pid, node = msg.node,
                stamp = cltime.time() }
            concurrent.send({ msg.from.pid, msg.from.node }, { phase = 'LOCK',
                from = { node = concurrent.node() } })
        end
    elseif msg.phase == 'COMMIT' then
        if nameslocks[msg.name] and
            nameslocks[msg.name]['pid'] == msg.pid and
            nameslocks[msg.name]['node'] == msg.node then
            concurrent._register.unregister(msg.name)
            concurrent.send({ msg.from.pid, msg.from.node }, { phase = 'COMMIT',
                from = { node = concurrent.node() } })
            nameslocks[msg.name] = nil
        end
    end
end


-- Deletes all registered names from processes in a node to which the connection
-- is lost.
function delete_all(deadnode)
    for k, v in pairs(concurrent._register.names) do
       if type(v) == 'table' and v[2] == deadnode then
            delete(k)
       end
    end
end

-- Deletes a single registered name from processes in a node to which the
-- connection is lost.
function delete(name)
    concurrent._register.names[name] = nil
end

-- Returns the PID of the process specified by its registered name.  If the
-- system is not in distributed mode  or not fully connected, the old renamed 
-- version of the function is called.
function whereis(name)
    if not concurrent.node() and not concurrent.getoption('connectall') then
        return _whereis(name)
    end

    local names = concurrent._register.names
    if type(name) == 'number' then
        return name
    end
    if not names[name] then
        return
    end
    if names[name][2] == concurrent.node() then
        return names[name][1]
    end
    return names[name]
end

-- Controllers to handle register and unregister requests.
concurrent._distributed._network.controllers['REGISTER'] =
    controller_register
concurrent._distributed._network.controllers['UNREGISTER'] =
    controller_unregister

-- Overwrites the old unregister functions for terminated and aborted processes
-- with the new versions of these functions.
for k, v in ipairs(concurrent._process.ondeath) do
    if v == _unregister then
        concurrent._process.ondeath[k] = unregister
    end
end
for k, v in ipairs(concurrent._process.ondestruction) do
    if v == _unregister then
        concurrent._process.ondestruction[k] = unregister
    end
end

-- Deletes all registered names from processes in a node to which the
-- connection is lost.
table.insert(concurrent._distributed._network.onfailure, delete_all)

concurrent.register = register
concurrent.unregister = unregister
concurrent.whereis = whereis
