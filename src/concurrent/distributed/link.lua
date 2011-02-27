-- Submodule for linking between distributed processes.
module('concurrent._distributed._link', package.seeall)

-- The existing versions of the linking related functions are renamed.
_link = concurrent._link.link
_unlink = concurrent._link.unlink
_signal = concurrent._link.signal

-- Links the calling process with the specified process.  If the destination
-- process is local the old renamed version of the function is called, otherwise
-- a linking request is sent to the node where the destination process is
-- executing under.
function link(dest)
    if type(dest) ~= 'table' then
        return _link(concurrent.whereis(dest))
    end

    local links = concurrent._link.links
    local s = concurrent.self()
    local pid, node = unpack(dest)
    if type(links[s]) == 'nil' then
        links[s] = {}
    end
    for _, v in pairs(links[s]) do
        if type(v) == 'table' and pid == v[1] and node == v[2] then
            return
        end
    end
    concurrent.send({ -1, node }, { subject = 'LINK', to = { pid = pid },
        from = { pid = s, node = concurrent.node() } })
    table.insert(links[s], dest)
end

-- Handles linking requests from a remote process.
function controller_link(msg)
    local links = concurrent._link.links
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then
        return
    end
    if type(links[pid]) == 'nil' then
        links[pid] = {}
    end
    for _, v in pairs(links[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            return
        end
    end
    table.insert(links[pid], { msg.from.pid, msg.from.node })
end

-- Creates a process either local or remote which is also linked to the calling
-- process.
function spawnlink(...)
    local pid, errmsg = concurrent.spawn(...)
    if not pid then
        return nil, errmsg
    end
    concurrent.link(pid)
    return pid
end

-- Uninks the calling process from the specified process.  If the destination
-- process is local the old renamed version of the function is called, otherwise
-- an unlinking request is sent to the node where the destination process is
-- executing under.
function unlink(dest)
    if type(dest) ~= 'table' then
        return _unlink(concurrent.whereis(dest))
    end

    local links = concurrent._link.links
    local s = concurrent.self()
    local pid, node = unpack(dest)
    if type(links[s]) == 'nil' then
        return
    end
    for k, v in pairs(links[s]) do
        if type(v) == 'table' and pid == v[1] and node == v[2] then
            table.remove(links[s], k)
        end
    end
    concurrent.send({ -1, node }, { subject = 'UNLINK', to = { pid = -1 },
        from = { pid = s, node = concurrent.node() } })
end

-- Handles unlinking requests from a remote process. 
function controller_unlink(msg)
    local links = concurrent._link.links
    local pid = concurrent.whereis(msg.to.pid)
    if not pid then
        return
    end
    if type(links[pid]) == 'nil' then
        return
    end
    for k, v in pairs(links[pid]) do
        if type(v) == 'table' and msg.from.pid == v[1] and
            msg.from.node == v[2] then
            table.remove(links[pid], k)
        end
    end
end

-- Signals all processes that are linked to processes in and node to which the
-- connection is lost.
function signal_all(deadnode)
    for k, v in pairs(concurrent._link.links) do
       if v[2] == deadnode then
           signal(k, v, 'noconnection')
       end
    end
end

-- Signals a single process that is linked to processes in a node to which the
-- connection is lost.
function signal(dest, dead, reason)
    if type(dest) ~= 'table' then
        return _signal(concurrent.whereis(dest), dead, reason)
    end

    local pid, node = unpack(dest)
    concurrent.send({ -1, node }, { subject = 'EXIT', to = { pid = pid },
        from = { dead, concurrent.node() }, reason = reason })
end

-- Handles exit requests from distributed processes.
function controller_exit(msg)
    if not concurrent.getoption('trapexit') then
        concurrent._process.kill(concurrent.whereis(msg.to.pid), msg.reason)
    else
        concurrent.send(msg.to.pid, { signal = 'EXIT', from = msg.from,
            reason = msg.reason })
    end
end

-- Controllers to handle link, unlink and exit requests.
concurrent._distributed._network.controllers['LINK'] = controller_link
concurrent._distributed._network.controllers['UNLINK'] = controller_unlink
concurrent._distributed._network.controllers['EXIT'] = controller_exit

-- Signals all processes linked to processes in a node to which the connection
-- is lost.
table.insert(concurrent._distributed._network.onfailure, signal_all)

concurrent.link = link
concurrent.unlink = unlink
concurrent._link.signal = signal
