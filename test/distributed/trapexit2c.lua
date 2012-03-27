concurrent = require 'concurrent'

concurrent.setoption('trapexit', true)

function root(pid)
    local self = concurrent.self()
    concurrent.register('root', self)
    concurrent.link(pid)
    while true do
        concurrent.send(pid, { from = { self, 'root@localhost' },
            body = 'ping' })
        print('root sent message to internal')

        local msg = concurrent.receive(10)
        if msg and msg.signal == 'EXIT' then break end
    end
    print('root received EXIT and exiting')
end

concurrent.spawn(root, { 'internal', 'internal@localhost' })

concurrent.init('root@localhost')
concurrent.loop()
concurrent.shutdown()
