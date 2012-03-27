concurrent = require 'concurrent'

function receiver()
    concurrent.register('receiver', concurrent.self())
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

concurrent.spawn(receiver)

concurrent.init('receiver@localhost')
concurrent.loop()
concurrent.shutdown()
