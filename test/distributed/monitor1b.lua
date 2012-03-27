concurrent = require 'concurrent'

function ping(pid)
    concurrent.register('ping', concurrent.self())
    concurrent.monitor(pid)
    while true do
        concurrent.send(pid, { from = { 'ping', 'ping@localhost' },
                               body = 'ping' })
        print('ping sent message to pong')
        local msg = concurrent.receive(1000)
        if msg and msg.signal == 'DOWN' then break end
        print('ping received reply from pong')
    end
    print('ping received DOWN and exiting')
end

concurrent.spawn(ping, { 'pong', 'pong@localhost' })

concurrent.init('ping@localhost')
concurrent.loop()
concurrent.shutdown()
