concurrent = require 'concurrent'

function pong()
    while true do
        local msg = concurrent.receive()
        if msg.body == 'finished' then
            break
        elseif msg.body == 'ping' then
            print('pong received ping')
            concurrent.send(msg.from, { body = 'pong' })
        end
    end
    print('pong finished')
end

function ping(n)
    for i = 1, n do
        concurrent.send('pong', { from = concurrent.self(), body = 'ping' })
        local msg = concurrent.receive()
        if msg.body == 'pong' then print('ping received pong') end
    end
    concurrent.send('pong', { from = concurrent.self(), body = 'finished' })
    print('ping finished')
end

pid = concurrent.spawn(pong)
concurrent.register('pong', pid)
concurrent.spawn(ping, 3)

concurrent.loop()
