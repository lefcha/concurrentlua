-- Submodule for node related operations.
module('concurrent._distributed._node', package.seeall)

nodemonitors = {}               -- Nodes monitoring the node.

-- Returns the node's name.
function node()
    return concurrent._distributed._network.nodename
end

-- Returns a table with the names of the nodes that the node is connected to.
function nodes()
    local t = {}
    for k, _ in pairs(concurrent._distributed._network.connections) do
        table.insert(t, k)
    end
    return t
end

-- Returns a true if the node has been initialized or false otherwise.
function isnodealive()
    return node() ~= nil
end

-- Starts monitoring the specified node.
function monitornode(name)
    local s = concurrent.self()
    if not nodemonitors[s] then
        nodemonitors[s] = {}
    end
    table.insert(nodemonitors[s], name)
end

-- Stops monitoring the specified node.
function demonitornode(name)
    local s = concurrent.self()
    if not nodemonitors[s] then
        return
    end
    for k, v in pairs(nodemonitors[s]) do
        if name == v then
            table.remove(nodemonitors[s], k)
        end
    end
end

-- Notifies all the monitoring processes about the status change of a node.
function notify_all(deadnode)
    for k, v in pairs(nodemonitors) do
        for l, w in pairs(v) do
            if w == deadnode then
                notify(k, w, 'noconnection')
            end
        end
    end
end

-- Notifies a single process about the status of a node. 
function notify(dest, deadnode, reason)
    concurrent.send(dest, { signal = 'NODEDOWN', from = { dead,
        concurrent.node() }, reason = reason })
end

-- Monitoring processes should be notified when the connection with a node is
-- lost.
table.insert(concurrent._distributed._network.onfailure, notify_all)

concurrent.node = node
concurrent.nodes = nodes
concurrent.isnodealive = isnodealive
concurrent.monitornode = monitornode
concurrent.demonitornode = demonitornode
