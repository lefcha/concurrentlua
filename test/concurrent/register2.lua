concurrent = require 'concurrent'

function leaf(n)
    for i = 1, n do
        local msg  = concurrent.receive()
        print('leaf received message from internal')
    end
    print('leaf exiting')
end

function internal(name)
    while true do
        if not concurrent.isalive(concurrent.whereis(name)) then break end

        local msg = concurrent.receive(1000)
        print('internal received message from root')

        concurrent.send(name, { from = concurrent.self(), body = 'ping' })
        print('internal sent message to leaf')
    end
    print('internal exiting')
end

function root(name)
    while true do
        if not concurrent.isalive(concurrent.whereis(name)) then break end

        concurrent.send(name, { from = concurrent.self(), body = 'ping' })
        print('root sent message to internal')

        local msg = concurrent.receive(10)
    end
    print('root exiting')
end

print('registered: ', unpack(concurrent.registered()))

pid = concurrent.spawn(leaf, 2)
concurrent.register('leaf', pid)

print('registered: ', unpack(concurrent.registered()))
concurrent.unregister('leaf')
print('registered: ', unpack(concurrent.registered()))
concurrent.register('leaf', pid)
print('registered: ', unpack(concurrent.registered()))

pid = concurrent.spawn(internal, 'leaf')
concurrent.register('internal', pid)

pid = concurrent.spawn(root, 'internal')
concurrent.register('root', pid)

print('registered: ', unpack(concurrent.registered()))

concurrent.loop()

print('registered: ', unpack(concurrent.registered()))
