-- Submodule for node related operations.
local network = require 'concurrent.distributed.network'
local concurrent

local node = {}

node.nodemonitors = {}          -- Nodes monitoring the node.

-- Returns the node's name.
function node.node()
    return network.nodename
end

-- Returns a table with the names of the nodes that the node is connected to.
function node.nodes()
    local t = {}
    for k, _ in pairs(network.connections) do table.insert(t, k) end
    return t
end

-- Returns a true if the node has been initialized or false otherwise.
function node.isnodealive()
    concurrent = concurrent or require 'concurrent'
    return concurrent.node() ~= nil
end

-- Starts monitoring the specified node.
function node.monitornode(name)
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    if not node.nodemonitors[s] then node.nodemonitors[s] = {} end
    table.insert(node.nodemonitors[s], name)
end

-- Stops monitoring the specified node.
function node.demonitornode(name)
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    if not node.nodemonitors[s] then return end
    for k, v in pairs(node.nodemonitors[s]) do
        if name == v then table.remove(node.nodemonitors[s], k) end
    end
end

-- Notifies all the monitoring processes about the status change of a node.
function node.notify_all(deadnode)
    for k, v in pairs(node.nodemonitors) do
        for l, w in pairs(v) do
            if w == deadnode then node.notify(k, w, 'noconnection') end
        end
    end
end

-- Notifies a single process about the status of a node. 
function node.notify(dest, deadnode, reason)
    concurrent = concurrent or require 'concurrent'
    concurrent.send(dest, { signal = 'NODEDOWN',
                            from = { dead, concurrent.node() },
                            reason = reason })
end

-- Monitoring processes should be notified when the connection with a node is
-- lost.
table.insert(network.onfailure, node.notify_all)

return node
