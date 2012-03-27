concurrent = require 'concurrent'

function pong(n)
    concurrent.register('pong', concurrent.self())
    for i = 1, n do
        local msg  = concurrent.receive()
        print('pong received message from ping')
        concurrent.send(msg.from, { from = { 'pong', 'pong@localhost' },
                                    body = 'pong' })
        print('pong sent reply to ping')
    end
    print('pong exiting')
end

concurrent.spawn(pong, 3)

concurrent.init('pong@localhost')
concurrent.loop()
concurrent.shutdown()
