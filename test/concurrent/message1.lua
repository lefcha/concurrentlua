concurrent = require 'concurrent'

function receiver()
    local msg  = concurrent.receive()
    print('this is an integer: ' .. msg.integer)
    print('this is a float: ' .. msg.float)
    print('this is a string: ' .. msg.string)
    print('this is a ' .. tostring(msg.table))
    print('  table[1] = ' .. msg.table[1])
    print("  table['hello'] = " .. msg.table['hello'])
    print('this is a ' .. tostring(msg.callme))
    print('  function() = ' .. msg.callme())
end

function sender(pid)
    concurrent.send(pid, { from = concurrent.self(),
                           integer = 9634,
                           float = 96.34,
                           string = 'hello world',
                           table = { 'hello, world', hello = 'world' },
                           callme = function () return 'hello world!' end })
end

pid = concurrent.spawn(receiver)
concurrent.spawn(sender, pid)

concurrent.loop()
