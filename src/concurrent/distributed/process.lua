-- Submodule for distributed processes.
local process = require 'concurrent.process'
local network = require 'concurrent.distributed.network'
local concurrent, scheduler, message

process.last = -1               -- Counter for the last auxiliary process. 

-- The existing version of this function for process creation is renamed. 
process._spawn = process.spawn

-- Creates a process either local or remote.  If the process is a local process
-- the old renamed version of the function is used, otherwise an auxiliary
-- system process takes care of the creation of a remote process.  Returns
-- the either the local or the remote PID of the newly created process.
function process.spawn(...)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'
    local args = { ... }
    if type(args[1]) == 'function' then return process._spawn(unpack(args)) end

    local node = args[1]
    table.remove(args, 1)
    local func = args[1]
    table.remove(args, 1)

    local pid, errmsg = process.spawn_system(process.spawn_process,
                                             concurrent.self(),
                                             node, func, args)
    local msg = scheduler.wait()
    if not msg.pid then return nil, msg.errmsg end
    return { msg.pid, node }
end

-- Auxiliary system process that creates a remote process.
function process.spawn_process(parent, node, func, args)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'
    concurrent.send({ -1, node},
                    { subject = 'SPAWN',
                      from = { pid = concurrent.self(),
                               node = concurrent.node() },
                      func = func,
                      args = args })
    local msg = concurrent.receive()
    scheduler.barriers[parent] = msg
end

-- Handles spawn requests from a remote node.
function process.controller_spawn(msg)
    concurrent = concurrent or require 'concurrent'
    local func = loadstring('return ' .. msg.func)
    if func then
        local pid, errmsg = concurrent.spawn(func(), unpack(msg.args))
        concurrent.send({ msg.from.pid, msg.from.node },
                        { pid = pid, errmsg = errmsg })
    end
end

-- Creates auxiliary system functions, that are mostly similar to normal
-- processes, but have a negative number as a PID and lack certain capabilities.
function process.spawn_system(func, ...)
    message = message or require 'concurrent.message'
    scheduler = scheduler or require 'concurrent.scheduler'
    local co = coroutine.create(
        function (...)
            coroutine.yield()
            func(...)
        end
    )

    process.last = process.last - 1
    local pid = process.last

    process.processes[pid] = co
    message.mailboxes[pid] = {}
    scheduler.timeouts[pid] = 0

    local status, errmsg = process.resume(co, ...)
    if not status then return nil, errmsg end
    return pid
end

-- Controller to handle spawn requests.
network.controllers['SPAWN'] = process.controller_spawn

return process
