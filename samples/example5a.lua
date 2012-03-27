concurrent = require 'concurrent'

function ping(n, pid)
    concurrent.link(pid)
    for i = 1, n do
        concurrent.send(pid, { from = concurrent.self(), body = 'ping' })
        local msg = concurrent.receive()
        if msg.body == 'pong' then print('ping received pong') end
    end
    print('ping finished')
    concurrent.exit('finished')
end

function pong()
    while true do
        local msg = concurrent.receive()
        if msg.body == 'ping' then
            print('pong received ping')
            concurrent.send(msg.from, { body = 'pong' })
        end
    end
    print('pong finished')
end

pid = concurrent.spawn(pong)
concurrent.spawn(ping, 3, pid)

concurrent.loop()
