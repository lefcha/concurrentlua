concurrent = require 'concurrent'

function ping(pid)
    concurrent.register('ping', concurrent.self())
    concurrent.link(pid)
    while true do
        concurrent.send(pid, { from = { 'ping', 'ping@localhost' },
                               body = 'ping' })
        print('ping sent message to pong')
        local msg = concurrent.receive(1000)
        print('ping received reply from pong')
    end
    print('ping exiting')
end

concurrent.spawn(ping, { 'pong', 'pong@localhost' })

concurrent.init('ping@localhost')
concurrent.loop()
concurrent.shutdown()
