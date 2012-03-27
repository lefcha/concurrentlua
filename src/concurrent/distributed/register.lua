-- Submodule for process name registering in distributed mode.
local time = require 'concurrent.time'
local register = require 'concurrent.register'
local option = require 'concurrent.option'
local process = require 'concurrent.process'
local network = require 'concurrent.distributed.network'
local concurrent, scheduler

register.nameslocks = {}        -- Locking during registration negotiations.

option.options.registertimeout = 10 * 1000      -- Registration timeout.
option.options.registerlocktimeout = 30 * 1000  -- Lock timeout.

-- The existing versions of the functions for process registering are renamed.
register._register = register.register
register._unregister = register.unregister
register._whereis = register.whereis

-- Registers a PID with the specified name.  If the process is local the old
-- renamed version of the function is called, otherwise an auxiliary system
-- process, to handle negotiation on the name with the rest of the nodes, is
-- created.  Returns true if successful or false otherwise.
function register.register(name, pid)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'
    if not concurrent.node() or not concurrent.getoption('connectall') then
        return register._register(name, pid)
    end

    if concurrent.whereis(name) then return false end
    if not pid then pid = concurrent.self() end
    if #concurrent.nodes() == 0 then
        register.names[name] = { pid, concurrent.node() }
        return true
    end
    process.spawn_system(register.register_process, concurrent.self(), name,
                         pid)
    local msg = scheduler.wait()
    if msg.status then register.names[name] = { pid, concurrent.node() } end
    return msg.status, msg.errmsg
end

-- The auxiliary system process that negotiates on registering a name with the
-- rest of the nodes.  The negotiation is based on a two phase commit protocol.
-- The role of the coordinator plays the node that the register request
-- originated from.  First the coordinator asks for locking of a specific name
-- from all nodes, and if this was successful and a commit message is then sent
-- to all the nodes.
function register.register_process(parent, name, pid)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'
    local locks = {}
    local commits = {}
    local n = 0

    for k, _ in pairs(network.connections) do
        locks[k] = false
        commits[k] = false
        n = n + 1
    end

    for k, _ in pairs(network.connections) do
        concurrent.send({ -1, k },
                        { subject = 'REGISTER',
                          phase = 'LOCK',
                          from = { pid = concurrent.self(),
                                   node = concurrent.node() },
                          name = name,
                          pid = pid,
                          node = concurrent.node() })
    end

    local i = 0
    local timer = time.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - time.time())
        if msg and msg.phase == 'LOCK' then
            locks[msg.from.node] = true
            i = i + 1
        end
    until time.time() >= timer or i >= n

    for _, v in pairs(locks) do
        if not v then
            scheduler.barriers[parent] = { status = false,
                                           errmsg = 'lock failed' }
            return
        end
    end

    for k, _ in pairs(network.connections) do
        concurrent.send({ -1, k },
                        { subject = 'REGISTER',
                          phase = 'COMMIT',
                          from = { pid = concurrent.self(),
                                   node = concurrent.node() },
                          name = name,
                          pid = pid,
                          node = concurrent.node() })
    end

    local i = 0
    local timer = time.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - time.time())
        if msg and msg.phase == 'COMMIT' then
            commits[msg.from.node] = true
            i = i + 1
        end
    until time.time() >= timer or i >= n

    for _, v in pairs(commits) do
        if not v then
            scheduler.barriers[parent] = { status = false,
                                           errmsg = 'commit failed' }
            return
        end
    end

    scheduler.barriers[parent] = { status = true }
end

-- Handles register requests in distributed mode.
function register.controller_register(msg)
    concurrent = concurrent or require 'concurrent'
    if msg.phase == 'LOCK' then
        if not concurrent.whereis(msg.name) and
           (not register.nameslocks[msg.name] or
           time.time() - register.nameslocks[msg.name]['stamp'] <
           concurrent.getoption('registerlocktimeout'))
        then
            register.nameslocks[msg.name] = { pid = msg.pid, node = msg.node,
                                              stamp = time.time() }
            concurrent.send({ msg.from.pid, msg.from.node },
                            { phase = 'LOCK',
                              from = { node = concurrent.node() } })
        end
    elseif msg.phase == 'COMMIT' then
        if register.nameslocks[msg.name] and
           register.nameslocks[msg.name]['pid'] == msg.pid and
           register.nameslocks[msg.name]['node'] == msg.node
        then
            register._register(msg.name, { msg.pid, msg.node })
            concurrent.send({ msg.from.pid, msg.from.node },
                            { phase = 'COMMIT',
                              from = { node = concurrent.node() } })
            register.nameslocks[msg.name] = nil
        end
    end
end

-- Unegisters a PID with the specified name.  If the process is local the old
-- renamed version of the function is called, otherwise an auxiliary system
-- process, to handle negotiation on the name with ther rest of the nodes, is
-- created.  Returns true if successful or false otherwise.
function register.unregister(name)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'

    if not concurrent.node() or not concurrent.getoption('connectall') then
        return register._unregister(name)
    end

    for k, v in pairs(register.names) do
        if name == k and concurrent.node() == v[2] then
            if #concurrent.nodes() == 0 then
                register.names[name] = nil
                return
            end
            process.spawn_system(register.unregister_process,
                                 concurrent.self(), k)
            local msg = scheduler.wait()
            if msg.status then register.names[name] = nil end
            return msg.status, msg.errmsg
        end
    end
end

-- The auxiliary system process that negotiates on unregistering a name with the
-- rest of the nodes.  The negotiation is similar to the register operation.
function register.unregister_process(parent, name)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'
    local locks = {}
    local commits = {}
    local n = 0

    for k, _ in pairs(network.connections) do
        locks[k] = false
        commits[k] = false
        n = n + 1
    end

    for k, _ in pairs(network.connections) do
        concurrent.send({ -1, k },
                        { subject = 'UNREGISTER',
                          phase = 'LOCK',
                          from = { pid = concurrent.self(),
                                   node = concurrent.node() },
                          name = name })
    end

    local i = 0
    local timer = time.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - time.time())
        if msg and msg.phase == 'LOCK' then
            locks[msg.from.node] = true
            i = i + 1
        end
    until time.time() > timer or i >= n

    for _, v in pairs(locks) do
        if not v then
            scheduler.barriers[parent] = { status = false,
                                           errmsg = 'lock failed' }
            return
        end
    end

    for k, _ in pairs(network.connections) do
        concurrent.send({ -1, k },
                        { subject = 'UNREGISTER',
                          phase = 'COMMIT', 
                          from = { pid = concurrent.self(),
                                   node = concurrent.node() },
                          name = name })
    end

    local i = 0
    local timer = time.time() + concurrent.getoption('registertimeout')
    repeat
        local msg = concurrent.receive(timer - time.time())
        if msg and msg.phase == 'COMMIT' then
            commits[msg.from.node] = true
            i = i + 1
        end
    until time.time() > timer or i >= n

    for _, v in pairs(commits) do
        if not v then
            scheduler.barriers[parent] = { status = false,
                                           errmsg = 'commit failed' }
            return
        end
    end

    scheduler.barriers[parent] = { status = true }
end

-- Handles unregister requests in distributed mode.
function register.controller_unregister(msg)
    concurrent = concurrent or require 'concurrent'
    if msg.phase == 'LOCK' then
        if concurrent.whereis(msg.name) and
           (not register.nameslocks[msg.name] or
           time.time() - register.nameslocks[msg.name]['stamp'] <
           concurrent.getoption('registerlocktimeout'))
        then
            register.nameslocks[msg.name] = { pid = msg.pid, node = msg.node,
                                              stamp = time.time() }
            concurrent.send({ msg.from.pid, msg.from.node },
                            { phase = 'LOCK',
                              from = { node = concurrent.node() } })
        end
    elseif msg.phase == 'COMMIT' then
        if register.nameslocks[msg.name] and
            register.nameslocks[msg.name]['pid'] == msg.pid and
            register.nameslocks[msg.name]['node'] == msg.node
        then
            register._unregister(msg.name)
            concurrent.send({ msg.from.pid, msg.from.node },
                            { phase = 'COMMIT',
                              from = { node = concurrent.node() } })
            register.nameslocks[msg.name] = nil
        end
    end
end


-- Deletes all registered names from processes in a node to which the connection
-- is lost.
function register.delete_all(deadnode)
    for k, v in pairs(register.names) do
       if type(v) == 'table' and v[2] == deadnode then register.delete(k) end
    end
end

-- Deletes a single registered name from processes in a node to which the
-- connection is lost.
function register.delete(name)
    register.names[name] = nil
end

-- Returns the PID of the process specified by its registered name.  If the
-- system is not in distributed mode  or not fully connected, the old renamed 
-- version of the function is called.
function register.whereis(name)
    concurrent = concurrent or require 'concurrent'
    if not concurrent.node() or not concurrent.getoption('connectall') then
        return register._whereis(name)
    end

    if type(name) == 'number' then return name end
    if not register.names[name] then return end
    if register.names[name][2] == concurrent.node() then
        return register.names[name][1]
    end
    return register.names[name]
end

-- Controllers to handle register and unregister requests.
network.controllers['REGISTER'] = register.controller_register
network.controllers['UNREGISTER'] = register.controller_unregister

-- Overwrites the old unregister functions for terminated and aborted processes
-- with the new versions of these functions.
for k, v in ipairs(process.ondeath) do
    if v == register._unregister then
        process.ondeath[k] = register.unregister
    end
end
for k, v in ipairs(process.ondestruction) do
    if v == register._unregister then
        process.ondestruction[k] = register.unregister
    end
end

-- Deletes all registered names from processes in a node to which the
-- connection is lost.
table.insert(network.onfailure, register.delete_all)

return register
