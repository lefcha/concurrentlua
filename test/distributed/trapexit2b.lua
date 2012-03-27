concurrent = require 'concurrent'

concurrent.setoption('trapexit', true)

function internal(pid)
    concurrent.register('internal', concurrent.self())
    concurrent.link(pid)
    while true do
        local msg = concurrent.receive()
        if msg and msg.signal == 'EXIT' then break end
        print('internal received message from root')

        concurrent.send(pid, { from = { concurrent.self(),
            'internal@localhost' }, body = 'ping' })
        print('internal sent message to leaf')
    end
    print('internal received EXIT and exiting')
    concurrent.exit('test')
end

concurrent.spawn(internal, { 'leaf', 'leaf@localhost' })

concurrent.init('internal@localhost')
concurrent.loop()
concurrent.shutdown()
