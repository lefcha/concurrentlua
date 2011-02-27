-- Submodule for process monitoring.
module('concurrent._monitor', package.seeall)

monitors = {}                   -- Active monitors between processes.

-- The calling process starts monitoring the specified process.
function monitor(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if type(monitors[pid]) == 'nil' then
        monitors[pid] = {}
    end
    for _, v in pairs(monitors[pid]) do
        if s == v then
            return
        end
    end
    table.insert(monitors[pid], s)
end

-- Creates a new process which is also monitored by the calling process.
function spawnmonitor(...)
    local pid, errmsg = concurrent.spawn(...)
    if not pid then
        return nil, errmsg
    end
    concurrent.monitor(pid)
    return pid
end

-- The calling process stops monitoring the specified process.
function demonitor(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if monitors[pid] == 'nil' then
        return
    end
    for key, value in pairs(monitors[pid]) do
        if s == value then
            monitors[pid][key] = nil
            return
        end
    end
end

-- Notifies all the monitoring processes about the status change of the
-- specified process.
function notify_all(dead, reason)
    if type(monitors[dead]) == 'nil' then
        return
    end
    for _, v in pairs(monitors[dead]) do
        notify(v, dead, reason)
    end
    monitors[dead] = nil
end

-- Notifies a single process about the status change of the specified process.
function notify(dest, dead, reason)
    concurrent.send(dest, { signal = 'DOWN', from = dead, reason = reason })
end

-- Processes that monitor terminated or aborted processes should be notified.
table.insert(concurrent._process.ondeath, notify_all)
table.insert(concurrent._process.ondestruction, notify_all)

concurrent.monitor = monitor
concurrent.demonitor = demonitor
concurrent.spawnmonitor = spawnmonitor
