-- Submodule for handling all networking operations between nodes.
module('concurrent._distributed._network', package.seeall)

require 'socket'
require 'copas'
require 'mime'
require 'cltime'

nodename = nil                  -- The node's unique name.

connections = {}                -- Active connections to other nodes.

controllers = {}                -- Functions that handle incoming requests.

onfailure = {}                  -- Functions to execute on node failure.

concurrent._process.processes[-1] = -1  -- The node is a process with PID of -1.
concurrent._message.mailboxes[-1] = {}  -- The mailbox of the node.

concurrent._option.options.shortnames = false   -- Node fully qualified names.
concurrent._option.options.connectall = true    -- All nodes fully connected.
concurrent._option.options.keepalive = false    -- Keep alive the connections.
concurrent._option.options.keepalivetimeout = 60 * 1000  -- Keep alive timeout.

-- Connects to a node, by first finding out the port that the destination node
-- is listening to, then initializing the connection and sending the first
-- handshake message that contains useful information about nodes.  Returns a
-- socket to the destination node.
function connect(url)
    local node, host = string.match(url, '^(%a[%w_]*)@(.+)$')
    if not node or not host then
        return
    end

    if connections[url] then
        return connections[url]
    end
    
    local pmd = socket.connect(host, 9634)
    if not pmd then
        return
    end
    pmd:send('? ' .. url .. '\r\n')
    local port = pmd:receive()
    pmd:shutdown('both')

    if port then
        local client = socket.connect(host, tonumber(port))
        if not client then
            return
        end

        connections[url] = client

        concurrent.send({ -1, url }, { subject = 'HELLO',
            from = { node = nodename }, nodes = concurrent.nodes(),
            names = concurrent._register.names })
        
        if concurrent.getoption('keepalive') then
            concurrent._distributed._process.spawn_system(keepalive_process,
                url)
        end

        return client
    end
end

-- Continuously sends echo messages to a node and waits for echo replies.  If
-- no reply has been received the connection to that node is closed.
function keepalive_process(name)
    local timeouts = concurrent._scheduler.timeouts
    local timeout = concurrent.getoption('keepalivetimeout')

    while true do
        local timer = cltime.time() + timeout

        if not connections[name] then
            break
        end
 
        if not concurrent.send({ -1, name }, { subject = 'ECHO',
            from = { pid = concurrent.self(), node = concurrent.node() } }) then
            break
        end

        local msg = concurrent.receive(timeout)
        if not msg then
            break
        end

        local diff = timer - cltime.time()
        if diff > 0 then
            concurrent._scheduler.sleep(diff)
        end
    end
    disconnect(name)
end

-- Handles echo requests by sending back an echo reply. 
function controller_echo(msg)
    concurrent.send({ msg.from.pid, msg.from.node }, 'ECHO')
end

-- Handles handshake messages by making use of the the information the
-- connecting node sent, information like other known nodes and registered
-- process names.
function controller_hello(msg)
    connect(msg.from.node)
    if concurrent.getoption('connectall') then
        for _, v in ipairs(msg.nodes) do
            if v ~= concurrent.node() then
                connect(v)
            end
        end
        for k, v in pairs(msg.names) do
            if not concurrent.whereis(name) then
                concurrent._register.register(k, v)
            else
                concurrent._register.unregister(k)
            end
        end
    end
end

-- Disconnects from a node.
function disconnect(url)
    if not connections[url] then
        return
    end
    connections[url]:shutdown('both')
    connections[url] = nil

    for _, v in ipairs(onfailure) do
        v(url)
    end
end

-- Handles bye messages by closing the connection to the source node. 
function controller_bye(msg)
    disconnect(msg.from)
end

-- Main socket handler for any incoming data, that waits for any data, checks
-- if the they are prefixed with the correct magic cookie and then deserializes
-- the message and forwards it to its recipient.
function handler(socket)
    local s = copas.wrap(socket)
    while true do
        local data = s:receive()
        if not data then
            break
        end

        if concurrent.getoption('debug') then
            print('<- ' .. data)
        end

        local recipient, message
        if concurrent.getcookie() then
            recipient, message = string.match(data, '^' ..
                concurrent.getcookie() .. ' ([%w%-_]+) (.+)$')
        else 
            recipient, message = string.match(data, '^([%w%-_]+) (.+)$')
        end
        if recipient and message then
            if type(tonumber(recipient)) == 'number' then
                recipient = tonumber(recipient)
            end
            local func = loadstring('return ' .. message)
            if func then
                if pcall(func) then
                    concurrent.send(recipient, func())
                end
            end
        end
    end
end

-- Checks for and handles messages sent to the node itself based on any
-- controllers that have been defined.
function controller()
    while #concurrent._message.mailboxes[-1] > 0 do
        local msg = table.remove(concurrent._message.mailboxes[-1], 1)
        if controllers[msg.subject] then
            controllers[msg.subject](msg)
        end
    end
end

-- Returns the fully qualified domain name of the calling node.
function getfqdn()
    local hostname = socket.dns.gethostname()
    local _, resolver = socket.dns.toip(hostname)
    local fqdn
    for _, v in pairs(resolver.ip) do
        fqdn, _ = socket.dns.tohostname(v)
        if string.find(fqdn, '%w+%.%w+') then
            break
        end
    end
    return fqdn 
end

-- Returns the short name of the calling node.
function gethost()
     return socket.dns.gethostname()
end

-- Returns the node's name along with the fully qualified domain name.
function hostname(node)
    return dispatcher(node .. '@' .. getfqdn())
end

-- Returns the node's name along with the short name.
function shortname(node)
    return dispatcher(node .. '@' .. gethost())
end

-- Initializes a node.
function init(node)
    if string.find(node, '@') then
        return dispatcher(node)
    else
        if concurrent.getoption('shortnames') then
            return shortname(node)
        else
            return hostname(node)
        end
    end
end

-- The dispatcher takes care of the main operations to initialize the
-- networking part of the node initialization.  Creates a port to listen to for
-- data, and registers this port to the local port mapper daemon, sets the
-- node's name, converts registered names to distributed form and adds a
-- handler for any incoming data.  Returns true if successful or false
-- otherwise.
function dispatcher(name)
    local node, host = string.match(name, '^(%a[%w_]*)@(.+)$')

    local server = socket.bind('*', 0)
    local _, port = server:getsockname()

    local client = socket.connect('127.0.0.1', 9634)
    if not client then
        return false
    end
    local answer
    client:send('+ ' .. name .. ' ' .. port .. '\r\n')
    client:send('? ' .. name .. '\r\n')
    answer = client:receive()
    if answer ~= tostring(port) then
        client:send('= ' .. name .. ' ' .. port .. '\r\n')
        client:send('? ' .. name .. '\r\n')
        answer = client:receive()
        if answer ~= tostring(port) then
            return false
        end
    end
    client:shutdown('both')

    nodename = name

    for n, p in pairs(concurrent._register.names) do
        if type(p) == 'number' then
            concurrent._register.names[n] = { p, nodename }
        end
    end

    copas.addserver(server, handler)

    return true
end

-- Shuts down a node by unregistering the node's listening port from the port
-- mapper daemon, by closing all of its active connections to other nodes, and
-- converting the registered names to local form.
function shutdown()
    if not concurrent.node() then
        return true
    end

    local client = socket.connect('127.0.0.1', 9634)
    if not client then
        return false
    end
    client:send('- ' .. concurrent.node() .. '\r\n')
    client:shutdown('both')

    for k, _ in pairs(connections) do
        concurrent.send({ -1, k }, { subject = 'BYE',
            from = concurrent.node() })
        disconnect(k)
    end

    for n, pid in pairs(concurrent._register.names) do
        if type(pid) == 'table' then
            p, _ = unpack(pid)
            concurrent._register.names[n] = p
        end
    end

    nodename = nil

    return true
end

-- Controllers to handle messages between the nodes. 
controllers['HELLO'] = controller_hello
controllers['ECHO'] = controller_echo
controllers['BYE'] = controller_bye

concurrent.init = init
concurrent.shutdown = shutdown
