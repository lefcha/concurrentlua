-- Submodule for process monitoring.
local process = require 'concurrent.process'
local concurrent

local monitor = {}

monitor.monitors = {}           -- Active monitors between processes.

-- The calling process starts monitoring the specified process.
function monitor.monitor(dest)
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then return end
    if type(monitor.monitors[pid]) == 'nil' then monitor.monitors[pid] = {} end
    for _, v in pairs(monitor.monitors[pid]) do if s == v then return end end
    table.insert(monitor.monitors[pid], s)
end

-- Creates a new process which is also monitored by the calling process.
function monitor.spawnmonitor(...)
    concurrent = concurrent or require 'concurrent'
    local pid, errmsg = concurrent.spawn(...)
    if not pid then return nil, errmsg end
    concurrent.monitor(pid)
    return pid
end

-- The calling process stops monitoring the specified process.
function monitor.demonitor(dest)
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then return end
    if monitor.monitors[pid] == 'nil' then return end
    for key, value in pairs(monitor.monitors[pid]) do
        if s == value then
            monitor.monitors[pid][key] = nil
            return
        end
    end
end

-- Notifies all the monitoring processes about the status change of the
-- specified process.
function monitor.notify_all(dead, reason)
    if type(monitor.monitors[dead]) == 'nil' then return end
    for _, v in pairs(monitor.monitors[dead]) do
        monitor.notify(v, dead, reason)
    end
    monitor.monitors[dead] = nil
end

-- Notifies a single process about the status change of the specified process.
function monitor.notify(dest, dead, reason)
    concurrent = concurrent or require 'concurrent'
    concurrent.send(dest, { signal = 'DOWN', from = dead, reason = reason })
end

-- Processes that monitor terminated or aborted processes should be notified.
table.insert(process.ondeath, monitor.notify_all)
table.insert(process.ondestruction, monitor.notify_all)

return monitor
