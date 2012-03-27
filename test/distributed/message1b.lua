concurrent = require 'concurrent'

function sender(pid)
    concurrent.register('sender', concurrent.self())
    concurrent.send(pid, { from = concurrent.self(),
                           integer = 9634,
                           float = 96.34,
                           string = 'hello world',
                           table = { 'hello, world', hello = 'world' },
                           callme = function () return 'hello world!' end })
end

concurrent.spawn(sender, { 'receiver', 'receiver@localhost' })

concurrent.init('sender@localhost')
concurrent.loop()
concurrent.shutdown()
