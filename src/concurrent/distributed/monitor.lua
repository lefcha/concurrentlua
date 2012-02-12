-- Submodule for monitoring of distributed processes.
local _monitor = {}

-- The existing versions of the monitoring related functions are renamed.
_monitor._monitor = concurrent._monitor.monitor
_monitor._spawnmonitor = concurrent._monitor.spawnmonitor
_monitor._demonitor = concurrent._monitor.demonitor
_monitor._notify = concurrent._monitor.notify

-- Starts monitoring the specified process.  If the destination process is local
-- the old renamed version of the function is called, otherwise a monitor
-- request is sent to the node where the destination process is executing under.
function _monitor.monitor(dest)
    if type(dest) ~= 'table' then
        return _monitor._monitor(concurrent.whereis(dest))
    end

    local s = concurrent.self()
    local pid, node = unpack(dest)
    concurrent.send({ -1, node }, { subject = 'MONITOR', to = { pid = pid },
        from = { pid = s, node = concurrent.node() } })
end

-- Handles monitor requests from a remote process. 
function _monitor.controller_monitor(msg)
    local monitors = concurrent._monitor.monitors
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then
        return
    end
    if type(monitors[pid]) == 'nil' then
        monitors[pid] = {}
    end
    for _, v in pairs(monitors[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            return
        end
    end
    table.insert(monitors[pid], { msg.from.pid, msg.from.node })
end

-- Creates a process either local or remote which is also monitored by the
-- calling process.
function _monitor.spawnmonitor(...)
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
function _monitor.demonitor(dest)
    if type(dest) ~= 'table' then
        return _monitor._demonitor(concurrent.whereis(dest))
    end

    local s = concurrent.self()
    local pid, node = unpack(dest)
    concurrent.send({ -1, node }, { subject = 'DEMONITOR', to = { pid = -1 },
        from = { pid = s, node = concurrent.node() } })
end

-- Handles demonitor requests from a remote process. 
function _monitor.controller_demonitor(msg)
    local monitors = concurrent._monitor.monitors
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then
        return
    end
    if type(monitors[pid]) == 'nil' then
        return
    end
    for k, v in pairs(monitors[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            table.remove(monitors[pid], k)
        end
    end
end

-- Notifies all processes that are monitoring processes in a node to which the
-- connection is lost.
function _monitor.notify_all(deadnode)
    for k, v in pairs(concurrent._monitor.monitors) do
       if v[2] == deadnode then
           _monitor.notify(k, v, 'noconnection')
       end
    end
end

-- Notifies a single process that is monitoring processes in and node to which
-- the connection is lost.
function _monitor.notify(dest, dead, reason)
    if type(dest) ~= 'table' then
        return _monitor._notify(concurrent.whereis(dest), dead, reason)
    end

    concurrent.send(dest, { signal = 'DOWN', from = { dead,
        concurrent.node() }, reason = reason })
end

-- Controllers to handle monitor and demonitor requests.
concurrent._distributed._network.controllers['MONITOR'] =
    _monitor.controller_monitor
concurrent._distributed._network.controllers['DEMONITOR'] =
    _monitor.controller_demonitor

-- Notifies all processes that are monitoring processes in a node to which the
-- connection is lost.
table.insert(concurrent._distributed._network.onfailure, _monitor.notify_all)

concurrent.monitor = _monitor.monitor
concurrent.spawnmonitor = _monitor.spawnmonitor
concurrent.demonitor = _monitor.demonitor
concurrent._monitor.notify =  _monitor.notify

return _monitor
