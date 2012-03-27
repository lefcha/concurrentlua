concurrent = require 'concurrent'

function hello_world(times)
    for i = 1, times do print('hello world') end
    print('done')
end

concurrent.spawn(hello_world, 3)

concurrent.loop()
