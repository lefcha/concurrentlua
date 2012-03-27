concurrent = require 'concurrent'

function ping(pid)
    concurrent.register('ping', concurrent.self())
    concurrent.monitornode('pong@localhost')
    while true do
        concurrent.send(pid, { from = { 'ping', 'ping@localhost' },
            body = 'ping' })
        print('ping sent message to pong')
        local msg = concurrent.receive()
        if msg and msg.signal == 'NODEDOWN' then break end
        print('ping received reply from pong')
    end
    print('ping received NODEDOWN and exiting')
end

concurrent.spawn(ping, { 'pong', 'pong@localhost' })

concurrent.init('ping@localhost')
concurrent.loop()
concurrent.shutdown()
