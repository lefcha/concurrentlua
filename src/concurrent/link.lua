--Submodule for process linking.
local _link = {}

_link.links = {}                -- Active links between processes.

concurrent._option.options.trapexit = false     -- Option to trap exit signals.

-- The calling process is linked with the specified process.
function _link.link(dest)
    local t = type(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if type(_link.links[s]) == 'nil' then
        _link.links[s] = {}
    end
    if type(_link.links[pid]) == 'nil' then
        _link.links[pid] = {}
    end
    for _, v in pairs(_link.links[s]) do
        if pid == v then
            return
        end
    end
    table.insert(_link.links[s], pid)
    table.insert(_link.links[pid], s)
end

-- Creates a new process which is also linked to the calling process.
function _link.spawnlink(...)
    local pid, errmsg = concurrent.spawn(...)
    if not pid then
        return nil, errmsg
    end
    concurrent.link(pid)
    return pid
end

-- The calling process is unlinked from the specified process.
function _link.unlink(dest)
    local t = type(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if type(_link.links[s]) == 'nil' or type(_link.links[pid]) == 'nil' then
        return
    end
    for key, value in pairs(_link.links[s]) do
        if pid == value then
            _link.links[s][key] = nil
        end
    end
    for key, value in pairs(_link.links[pid]) do
        if s == value then
            _link.links[pid][key] = nil
        end
    end
end

-- Unlinks the calling process from all other processes. 
function _link.unlink_all()
    local s = concurrent.self()
    if type(_link.links[s]) == 'nil' then
        return
    end
    for _, v in pairs(_link.links[s]) do
        concurrent.unlink(v)
    end
    _link.links[s] = nil
end

-- Signals all the linked processes due to an abnormal exit of a process.
function _link.signal_all(dead, reason)
    if type(_link.links[dead]) == 'nil' then
        return
    end
    for _, v in pairs(_link.links[dead]) do
        _link.signal(v, dead, reason)
    end
    _link.links[dead] = nil
end

-- Signals a single process due to an abnormal exit of a process.
function _link.signal(dest, dead, reason)
    if not concurrent.getoption('trapexit') then
        concurrent._process.kill(dest, reason)
    else
        concurrent.send(dest, { signal = 'EXIT', from = dead,
            reason = reason }) 
    end
end

-- Processes that are linked to terminated or aborted processes should be
-- signaled.  
table.insert(concurrent._process.ondeath, _link.signal_all)
table.insert(concurrent._process.ondestruction, _link.unlink_all)

concurrent.link = _link.link
concurrent.unlink = _link.unlink
concurrent.spawnlink = _link.spawnlink

return _link
