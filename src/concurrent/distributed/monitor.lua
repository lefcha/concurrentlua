-- Submodule for monitoring of distributed processes.
local monitor = require 'concurrent.monitor'
local network = require 'concurrent.distributed.network'
local concurrent

-- The existing versions of the monitoring related functions are renamed.
monitor._monitor = monitor.monitor
monitor._spawnmonitor = monitor.spawnmonitor
monitor._demonitor = monitor.demonitor
monitor._notify = monitor.notify

-- Starts monitoring the specified process.  If the destination process is local
-- the old renamed version of the function is called, otherwise a monitor
-- request is sent to the node where the destination process is executing under.
function monitor.monitor(dest)
    concurrent = concurrent or require 'concurrent'
    if type(dest) ~= 'table' then
        return monitor._monitor(concurrent.whereis(dest))
    end

    local s = concurrent.self()
    local pid, node = unpack(dest)
    concurrent.send({ -1, node }, { subject = 'MONITOR', to = { pid = pid },
        from = { pid = s, node = concurrent.node() } })
end

-- Handles monitor requests from a remote process. 
function monitor.controller_monitor(msg)
    concurrent = concurrent or require 'concurrent'
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then
        return
    end
    if type(monitor.monitors[pid]) == 'nil' then
        monitor.monitors[pid] = {}
    end
    for _, v in pairs(monitor.monitors[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            return
        end
    end
    table.insert(monitor.monitors[pid], { msg.from.pid, msg.from.node })
end

-- Creates a process either local or remote which is also monitored by the
-- calling process.
function monitor.spawnmonitor(...)
    concurrent = concurrent or require 'concurrent'
    local pid, errmsg = concurrent.spawn(...)
    if not pid then
        return nil, errmsg
    end
    concurrent.monitor(pid)
    return pid
end

-- Stops monitoring the specified process.  If the destination process is local
-- the old version of the function is called, otherwise a demonitor request is
-- sent to the node where the destination process is executing under.
function monitor.demonitor(dest)
    concurrent = concurrent or require 'concurrent'
    if type(dest) ~= 'table' then
        return monitor._demonitor(concurrent.whereis(dest))
    end

    local s = concurrent.self()
    local pid, node = unpack(dest)
    concurrent.send({ -1, node }, { subject = 'DEMONITOR', to = { pid = -1 },
        from = { pid = s, node = concurrent.node() } })
end

-- Handles demonitor requests from a remote process. 
function monitor.controller_demonitor(msg)
    concurrent = concurrent or require 'concurrent'
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then
        return
    end
    if type(monitor.monitors[pid]) == 'nil' then
        return
    end
    for k, v in pairs(monitor.monitors[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            table.remove(monitor.monitors[pid], k)
        end
    end
end

-- Notifies all processes that are monitoring processes in a node to which the
-- connection is lost.
function monitor.notify_all(deadnode)
    for k, v in pairs(monitor.monitors) do
       if v[2] == deadnode then
           monitor.notify(k, v, 'noconnection')
       end
    end
end

-- Notifies a single process that is monitoring processes in and node to which
-- the connection is lost.
function monitor.notify(dest, dead, reason)
    concurrent = concurrent or require 'concurrent'
    if type(dest) ~= 'table' then
        return monitor._notify(concurrent.whereis(dest), dead, reason)
    end

    concurrent.send(dest, { signal = 'DOWN', from = { dead,
        concurrent.node() }, reason = reason })
end

-- Controllers to handle monitor and demonitor requests.
network.controllers['MONITOR'] = monitor.controller_monitor
network.controllers['DEMONITOR'] = monitor.controller_demonitor

-- Notifies all processes that are monitoring processes in a node to which the
-- connection is lost.
table.insert(network.onfailure, monitor.notify_all)

return monitor
