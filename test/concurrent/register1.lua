concurrent = require 'concurrent'

function pong(self, n)
    for i = 1, n do
        local msg  = concurrent.receive()
        print('pong received message from ping')
        concurrent.send(msg.from, { from = self, body = 'pong' })
        print('pong sent reply to ping')
    end
end

function ping(self, name)
    while true do
        concurrent.send(name, { from = self, body = 'ping' })
        print('ping sent message to pong')
        local msg = concurrent.receive(1000)
        if not msg and not concurrent.isalive(name) then
            print('ping exiting because pong is not alive anymore')
            concurrent.exit()
        end
        print('ping received reply from pong')
    end
end

print('registered: ', unpack(concurrent.registered()))

pid = concurrent.spawn(pong, 'pong', 3)
concurrent.register('pong', pid)

print('registered: ', unpack(concurrent.registered()))
concurrent.unregister('pong')
print('registered: ', unpack(concurrent.registered()))
concurrent.register('pong', pid)
print('registered: ', unpack(concurrent.registered()))

pid = concurrent.spawn(ping, 'ping', 'pong')
concurrent.register('ping', pid)

print('registered: ', unpack(concurrent.registered()))

concurrent.loop()

print('registered: ', unpack(concurrent.registered()))
