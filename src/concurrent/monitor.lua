-- Submodule for process monitoring.
local _monitor = {}

_monitor.monitors = {}          -- Active monitors between processes.

-- The calling process starts monitoring the specified process.
function _monitor.monitor(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if type(_monitor.monitors[pid]) == 'nil' then
        _monitor.monitors[pid] = {}
    end
    for _, v in pairs(_monitor.monitors[pid]) do
        if s == v then
            return
        end
    end
    table.insert(_monitor.monitors[pid], s)
end

-- Creates a new process which is also monitored by the calling process.
function _monitor.spawnmonitor(...)
    local pid, errmsg = concurrent.spawn(...)
    if not pid then
        return nil, errmsg
    end
    concurrent.monitor(pid)
    return pid
end

-- The calling process stops monitoring the specified process.
function _monitor.demonitor(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if _monitor.monitors[pid] == 'nil' then
        return
    end
    for key, value in pairs(_monitor.monitors[pid]) do
        if s == value then
            _monitor.monitors[pid][key] = nil
            return
        end
    end
end

-- Notifies all the monitoring processes about the status change of the
-- specified process.
function _monitor.notify_all(dead, reason)
    if type(_monitor.monitors[dead]) == 'nil' then
        return
    end
    for _, v in pairs(_monitor.monitors[dead]) do
        _monitor.notify(v, dead, reason)
    end
    _monitor.monitors[dead] = nil
end

-- Notifies a single process about the status change of the specified process.
function _monitor.notify(dest, dead, reason)
    concurrent.send(dest, { signal = 'DOWN', from = dead, reason = reason })
end

-- Processes that monitor terminated or aborted processes should be notified.
table.insert(concurrent._process.ondeath, _monitor.notify_all)
table.insert(concurrent._process.ondestruction, _monitor.notify_all)

concurrent.monitor = _monitor.monitor
concurrent.demonitor = _monitor.demonitor
concurrent.spawnmonitor = _monitor.spawnmonitor

return _monitor
