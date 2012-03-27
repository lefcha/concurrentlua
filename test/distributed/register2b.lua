concurrent = require 'concurrent'

function internal(pid)
    concurrent.register('internal', concurrent.self())
    concurrent.monitor(pid)
    while true do
        local msg = concurrent.receive()
        if msg and msg.signal == 'DOWN' then break end
        print('internal received message from root')

        concurrent.send(pid, { from = { concurrent.self(),
            'internal@localhost' }, body = 'ping' })
        print('internal sent message to leaf')
    end
    print('internal received DOWN and exiting')
end

concurrent.spawn(internal, { 'leaf', 'leaf@localhost' })

concurrent.init('internal@localhost')
concurrent.loop()
concurrent.shutdown()
