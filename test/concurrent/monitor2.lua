concurrent = require 'concurrent'

function leaf(n)
    for i = 1, n do
        local msg  = concurrent.receive()
        print('leaf received message from internal')
    end
    print('leaf exiting')
end

function internal(pid)
    concurrent.monitor(pid)
    while true do
        local msg = concurrent.receive(1000)
        if msg and msg.signal == 'DOWN' then break end
        print('internal received message from root')

        concurrent.send(pid, { from = concurrent.self(), body = 'ping' })
        print('internal sent message to leaf')
    end
    print('internal received DOWN and exiting')
end

function root(pid)
    concurrent.monitor(pid)
    local self = concurrent.self()
    while true do
        concurrent.send(pid, { from = self, body = 'ping' })
        print('root sent message to internal')

        local msg = concurrent.receive(10)
        if msg and msg.signal == 'DOWN' then break end
    end
    print('root received DOWN and exiting')
end

pid = concurrent.spawn(leaf, 2)
pid = concurrent.spawn(internal, pid)
concurrent.spawn(root, pid)

concurrent.loop()
