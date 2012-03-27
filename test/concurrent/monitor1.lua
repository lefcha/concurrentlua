concurrent = require 'concurrent'

function pong(n)
    for i = 1, n do
        local msg  = concurrent.receive()
        print('pong received message from ping')
        concurrent.send(msg.from, { from = concurrent.self(), body = 'pong' })
        print('pong sent reply to ping')
    end
end

function ping(pid)
    concurrent.monitor(pid)
    while true do
        concurrent.send(pid, { from = concurrent.self(), body = 'ping' })
        print('ping sent message to pong')
        local msg = concurrent.receive(1000)
        if msg and msg.signal == 'DOWN' then break end
        print('ping received reply from pong')
    end
    print('ping received DOWN and exiting')
end

pid = concurrent.spawn(pong, 3)
concurrent.spawn(ping, pid)

concurrent.loop()
