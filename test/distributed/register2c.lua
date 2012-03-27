concurrent = require 'concurrent'

function root(pid)
    local self = concurrent.self()
    concurrent.register('root', self)
    concurrent.monitor(pid)
    while true do
        concurrent.send(pid, { from = { self, 'root@localhost' },
            body = 'ping' })
        print('root sent message to internal')

        local msg = concurrent.receive(10)
        if msg and msg.signal == 'DOWN' then break end
    end
    print('root received DOWN and exiting')
end

concurrent.spawn(root, { 'internal', 'internal@localhost' })

concurrent.init('root@localhost')
concurrent.loop()
concurrent.shutdown()
