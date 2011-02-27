require 'concurrent'

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
        
concurrent.init('pong@gaia')
    
pid = concurrent.spawn(pong)

concurrent.register('pong', pid)
concurrent.loop()
concurrent.shutdown()
