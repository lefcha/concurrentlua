concurrent = require 'concurrent'

function leaf(n)
    concurrent.register('leaf', concurrent.self())
    for i = 1, n do
        local msg  = concurrent.receive()
        print('leaf received message from internal')
    end
    print('leaf exiting')
end

concurrent.spawn(leaf, 2)

concurrent.init('leaf@localhost')
concurrent.loop()
concurrent.shutdown()
