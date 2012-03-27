concurrent = require 'concurrent'

function internal(pid)
    concurrent.register('internal', concurrent.self())
    concurrent.link(pid)
    while true do
        local msg = concurrent.receive()
        print('internal received message from root')

        concurrent.send(pid, { from = { concurrent.self(),
                                        'internal@localhost' },
                               body = 'ping' })
        print('internal sent message to leaf')
    end
end

concurrent.spawn(internal, { 'leaf', 'leaf@localhost' })

concurrent.init('internal@localhost')
concurrent.loop()
concurrent.shutdown()
