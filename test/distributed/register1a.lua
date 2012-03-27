concurrent = require 'concurrent'

function pong(n)
    print('registered: ', unpack(concurrent.registered()))
    concurrent.register('pong', concurrent.self())
    print('registered: ', unpack(concurrent.registered()))
    for i = 1, n do
        local msg  = concurrent.receive()
        print('pong received message from ping')
        concurrent.send(msg.from, { from = { 'pong', 'pong@localhost' },
            body = 'pong' })
        print('pong sent reply to ping')
    end
    print('registered: ', unpack(concurrent.registered()))
    concurrent.unregister('pong')
    print('registered: ', unpack(concurrent.registered()))
    concurrent.register('pong', concurrent.self())
    print('registered: ', unpack(concurrent.registered()))
    print('pong exiting')
end

pid = concurrent.spawn(pong, 3)

concurrent.init('pong@localhost')
concurrent.loop()
concurrent.shutdown()
