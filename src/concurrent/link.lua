--Submodule for process linking.
module('concurrent._link', package.seeall)

links = {}                      -- Active links between processes.

concurrent._option.options.trapexit = false     -- Option to trap exit signals.

-- The calling process is linked with the specified process.
function link(dest)
    local t = type(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if type(links[s]) == 'nil' then
        links[s] = {}
    end
    if type(links[pid]) == 'nil' then
        links[pid] = {}
    end
    for _, v in pairs(links[s]) do
        if pid == v then
            return
        end
    end
    table.insert(links[s], pid)
    table.insert(links[pid], s)
end

-- Creates a new process which is also linked to the calling process.
function spawnlink(...)
    local pid, errmsg = concurrent.spawn(...)
    if not pid then
        return nil, errmsg
    end
    concurrent.link(pid)
    return pid
end

-- The calling process is unlinked from the specified process.
function unlink(dest)
    local t = type(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then
        return
    end
    if type(links[s]) == 'nil' or type(links[pid]) == 'nil' then
        return
    end
    for key, value in pairs(links[s]) do
        if pid == value then
            links[s][key] = nil
        end
    end
    for key, value in pairs(links[pid]) do
        if s == value then
            links[pid][key] = nil
        end
    end
end

-- Unlinks the calling process from all other processes. 
function unlink_all()
    local s = concurrent.self()
    if type(links[s]) == 'nil' then
        return
    end
    for _, v in pairs(links[s]) do
        concurrent.unlink(v)
    end
    links[s] = nil
end

-- Signals all the linked processes due to an abnormal exit of a process.
function signal_all(dead, reason)
    if type(links[dead]) == 'nil' then
        return
    end
    for _, v in pairs(links[dead]) do
        signal(v, dead, reason)
    end
    links[dead] = nil
end

-- Signals a single process due to an abnormal exit of a process.
function signal(dest, dead, reason)
    if not concurrent.getoption('trapexit') then
        concurrent._process.kill(dest, reason)
    else
        concurrent.send(dest, { signal = 'EXIT', from = dead,
            reason = reason }) 
    end
end

-- Processes that are linked to terminated or aborted processes should be
-- signaled.  
table.insert(concurrent._process.ondeath, signal_all)
table.insert(concurrent._process.ondestruction, unlink_all)

concurrent.link = link
concurrent.unlink = unlink
concurrent.spawnlink = spawnlink
