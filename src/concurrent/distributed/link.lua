-- Submodule for linking between distributed processes.
local link = require 'concurrent.link'
local network = require 'concurrent.distributed.network'
local concurrent, process

-- The existing versions of the linking related functions are renamed.
link._link = link.link
link._spawnlink = link.spawnlink
link._unlink = link.unlink
link._signal = link.signal

-- Links the calling process with the specified process.  If the destination
-- process is local the old renamed version of the function is called, otherwise
-- a linking request is sent to the node where the destination process is
-- executing under.
function link.link(dest)
    concurrent = concurrent or require 'concurrent'
    if type(dest) ~= 'table' then
        return link._link(concurrent.whereis(dest))
    end

    local s = concurrent.self()
    local pid, node = unpack(dest)
    if type(link.links[s]) == 'nil' then link.links[s] = {} end
    for _, v in pairs(link.links[s]) do
        if type(v) == 'table' and pid == v[1] and node == v[2] then return end
    end
    concurrent.send({ -1, node },
                    { subject = 'LINK',
                      to = { pid = pid },
                      from = { pid = s, node = concurrent.node() } })
    table.insert(link.links[s], dest)
end

-- Handles linking requests from a remote process.
function link.controller_link(msg)
    concurrent = concurrent or require 'concurrent'
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then return end
    if type(link.links[pid]) == 'nil' then link.links[pid] = {} end
    for _, v in pairs(link.links[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            return
        end
    end
    table.insert(link.links[pid], { msg.from.pid, msg.from.node })
end

-- Creates a process either local or remote which is also linked to the calling
-- process.
function link.spawnlink(...)
    concurrent = concurrent or require 'concurrent'
    local pid, errmsg = concurrent.spawn(...)
    if not pid then return nil, errmsg end
    concurrent.link(pid)
    return pid
end

-- Uninks the calling process from the specified process.  If the destination
-- process is local the old renamed version of the function is called, otherwise
-- an unlinking request is sent to the node where the destination process is
-- executing under.
function link.unlink(dest)
    concurrent = concurrent or require 'concurrent'
    if type(dest) ~= 'table' then
        return link._unlink(concurrent.whereis(dest))
    end

    local s = concurrent.self()
    local pid, node = unpack(dest)
    if type(link.links[s]) == 'nil' then return end
    for k, v in pairs(link.links[s]) do
        if type(v) == 'table' and pid == v[1] and node == v[2] then
            table.remove(link.links[s], k)
        end
    end
    concurrent.send({ -1, node },
                    { subject = 'UNLINK',
                      to = { pid = -1 },
                      from = { pid = s, node = concurrent.node() } })
end

-- Handles unlinking requests from a remote process. 
function link.controller_unlink(msg)
    concurrent = concurrent or require 'concurrent'
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then return end
    if type(link.links[pid]) == 'nil' then return end
    for k, v in pairs(link.links[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            table.remove(link.links[pid], k)
        end
    end
end

-- Signals all processes that are linked to processes in and node to which the
-- connection is lost.
function link.signal_all(deadnode)
    for k, v in pairs(link.links) do
       if v[2] == deadnode then link.signal(k, v, 'noconnection') end
    end
end

-- Signals a single process that is linked to processes in a node to which the
-- connection is lost.
function link.signal(dest, dead, reason)
    concurrent = concurrent or require 'concurrent'
    if type(dest) ~= 'table' then
        return link._signal(concurrent.whereis(dest), dead, reason)
    end

    local pid, node = unpack(dest)
    concurrent.send({ -1, node },
                    { subject = 'EXIT',
                      to = { pid = pid },
                      from = { dead, concurrent.node() }, reason = reason })
end

-- Handles exit requests from distributed processes.
function link.controller_exit(msg)
    concurrent = concurrent or require 'concurrent'
    process = process or require 'concurrent.process'
    if not concurrent.getoption('trapexit') then
        process.kill(concurrent.whereis(msg.to.pid), msg.reason)
    else
        concurrent.send(msg.to.pid, { signal = 'EXIT',
                                      from = msg.from,
                                      reason = msg.reason })
    end
end

-- Controllers to handle link, unlink and exit requests.
network.controllers['LINK'] = link.controller_link
network.controllers['UNLINK'] = link.controller_unlink
network.controllers['EXIT'] = link.controller_exit

-- Signals all processes linked to processes in a node to which the connection
-- is lost.
table.insert(network.onfailure, link.signal_all)

return link
