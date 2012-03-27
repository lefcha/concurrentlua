--Submodule for process linking.
local option = require 'concurrent.option'
local process = require 'concurrent.process'
local concurrent

local link = {}

link.links = {}                 -- Active links between processes.

option.options.trapexit = false -- Option to trap exit signals.

-- The calling process is linked with the specified process.
function link.link(dest)
    concurrent = concurrent or require 'concurrent'
    local t = type(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then return end
    if type(link.links[s]) == 'nil' then link.links[s] = {} end
    if type(link.links[pid]) == 'nil' then link.links[pid] = {} end
    for _, v in pairs(link.links[s]) do
        if pid == v then return end
    end
    table.insert(link.links[s], pid)
    table.insert(link.links[pid], s)
end

-- Creates a new process which is also linked to the calling process.
function link.spawnlink(...)
    concurrent = concurrent or require 'concurrent'
    local pid, errmsg = concurrent.spawn(...)
    if not pid then return nil, errmsg end
    concurrent.link(pid)
    return pid
end

-- The calling process is unlinked from the specified process.
function link.unlink(dest)
    concurrent = concurrent or require 'concurrent'
    local t = type(dest)
    local s = concurrent.self()
    local pid = concurrent.whereis(dest)
    if not pid then return end
    if type(link.links[s]) == 'nil' or type(link.links[pid]) == 'nil' then
        return
    end
    for key, value in pairs(link.links[s]) do
        if pid == value then link.links[s][key] = nil end
    end
    for key, value in pairs(link.links[pid]) do
        if s == value then link.links[pid][key] = nil end
    end
end

-- Unlinks the calling process from all other processes. 
function link.unlink_all()
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    if type(link.links[s]) == 'nil' then return end
    for _, v in pairs(link.links[s]) do concurrent.unlink(v) end
    link.links[s] = nil
end

-- Signals all the linked processes due to an abnormal exit of a process.
function link.signal_all(dead, reason)
    if type(link.links[dead]) == 'nil' then return end
    for _, v in pairs(link.links[dead]) do link.signal(v, dead, reason) end
    link.links[dead] = nil
end

-- Signals a single process due to an abnormal exit of a process.
function link.signal(dest, dead, reason)
    concurrent = concurrent or require 'concurrent'
    if not concurrent.getoption('trapexit') then
        process.kill(dest, reason)
    else
        concurrent.send(dest, { signal = 'EXIT', from = dead, reason = reason }) 
    end
end

-- Processes that are linked to terminated or aborted processes should be
-- signaled.  
table.insert(process.ondeath, link.signal_all)
table.insert(process.ondestruction, link.unlink_all)

return link
