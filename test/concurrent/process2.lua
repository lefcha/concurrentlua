concurrent = require 'concurrent'

function leaf(n)
    for i = 1, n do
        local msg  = concurrent.receive()
        print('leaf received message from internal')
    end
    print('leaf exiting')
end

function internal(pid)
    while concurrent.isalive(pid) do
        local msg = concurrent.receive(1000)
        print('internal received message from root')

        concurrent.send(pid, 'hey')
        print('internal sent message to leaf')
    end
    print('internal exiting')
end

function root(pid)
    while concurrent.isalive(pid) do
        concurrent.send(pid, 'hey')
        print('root sent message to internal')

        local msg = concurrent.receive(10)
    end
    print('root exiting')
end

pid = concurrent.spawn(leaf, 2)
pid = concurrent.spawn(internal, pid)
concurrent.spawn(root, pid)

concurrent.loop()
