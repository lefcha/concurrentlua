-- Submodule for distributed processes.
module('concurrent._distributed._process', package.seeall)

last = -1                       -- Counter for the last auxiliary process. 

-- The existing version of this function for process creation is renamed. 
_spawn = concurrent.spawn

-- Creates a process either local or remote.  If the process is a local process
-- the old renamed version of the function is used, otherwise an auxiliary
-- system process takes care of the creation of a remote process.  Returns
-- the either the local or the remote PID of the newly created process.
function spawn(...)
    local args = { ... }
    if type(args[1]) == 'function' then
        return _spawn(unpack(args))
    end

    local node = args[1]
    table.remove(args, 1)
    local func = args[1]
    table.remove(args, 1)

    local pid, errmsg = spawn_system(spawn_process, concurrent.self(), node,
        func, args)
    local msg = concurrent._scheduler.wait()
    if not msg.pid then
        return nil, msg.errmsg
    end
    return { msg.pid, node }
end

-- Auxiliary system process that creates a remote process.
function spawn_process(parent, node, func, args)
    concurrent.send({ -1, node} , { subject = 'SPAWN',
        from = { pid = concurrent.self(), node = concurrent.node() },
        func = func, args = args })
    local msg = concurrent.receive()
    concurrent._scheduler.barriers[parent] = msg
end

-- Handles spawn requests from a remote node.
function controller_spawn(msg)
    local func = loadstring('return ' .. msg.func)
    if func then
        local pid, errmsg = spawn(func(), unpack(msg.args))
        concurrent.send({ msg.from.pid, msg.from.node }, { pid = pid,
            errmsg = errmsg })
    end
end

-- Creates auxiliary system functions, that are mostly similar to normal
-- processes, but have a negative number as a PID and lack certain capabilities.
function spawn_system(func, ...)
    local co = coroutine.create(
        function (...)
            coroutine.yield()
            func(...)
        end
    )

    last = last - 1
    local pid = last

    concurrent._process.processes[pid] = co
    concurrent._message.mailboxes[pid] = {}
    concurrent._scheduler.timeouts[pid] = 0

    local status, errmsg = concurrent._process.resume(co, ...)
    if not status then
        return nil, errmsg
    end
    return pid
end

-- Controller to handle spawn requests.
concurrent._distributed._network.controllers['SPAWN'] = controller_spawn

concurrent.spawn = spawn
