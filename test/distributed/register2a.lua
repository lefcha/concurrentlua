concurrent = require 'concurrent'

function leaf(n)
    print('registered: ', unpack(concurrent.registered()))
    concurrent.register('leaf', concurrent.self())
    print('registered: ', unpack(concurrent.registered()))
    for i = 1, n do
        local msg  = concurrent.receive()
        print('leaf received message from internal')
    end
    print('registered: ', unpack(concurrent.registered()))
    concurrent.unregister('leaf')
    print('registered: ', unpack(concurrent.registered()))
    concurrent.register('leaf', concurrent.self())
    print('registered: ', unpack(concurrent.registered()))
    print('leaf exiting')
end

concurrent.spawn(leaf, 2)

concurrent.init('leaf@localhost')
concurrent.loop()
concurrent.shutdown()
