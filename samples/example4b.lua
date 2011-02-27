require 'concurrent'

function ping(n)
    for i = 1, n do
        concurrent.send({ 'pong', 'pong@gaia' }, {
            from = { concurrent.self(), concurrent.node() },
            body = 'ping'
        })
        local msg = concurrent.receive()
        if msg.body == 'pong' then
            print('ping received pong')
        end
    end
    concurrent.send({ 'pong', 'pong@gaia' }, {
        from = { concurrent.self(), concurrent.node() },
        body = 'finished'
    })
    print('ping finished')
end

concurrent.spawn(ping, 3)

concurrent.init('ping@selene')
concurrent.loop()
concurrent.shutdown()
