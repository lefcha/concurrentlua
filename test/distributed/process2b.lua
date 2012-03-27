concurrent = require 'concurrent'

concurrent.init('caller@localhost')

pid = concurrent.spawn('remote@localhost', 'pong', 3)
concurrent.spawn('remote@localhost', 'ping', pid)

concurrent.loop()
concurrent.shutdown()
