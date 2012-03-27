-- Submodule for the scheduling of processes in a distributed node. 
local socket = require 'socket'
local copas = require 'copas'

local time = require 'concurrent.time'
local scheduler = require 'concurrent.scheduler'
local concurrent, message, network

-- The existing versions of these functions for then schedulers operation are
-- renamed.
scheduler._step = scheduler.step
scheduler._tick = scheduler.tick
scheduler._loop = scheduler.loop

-- In addition to the operations performed for local processes, the mailbox of
-- the node itself is checked and any handlers are called to take care of the
-- messages.
function scheduler.step(timeout)
    message = message or require 'concurrent.message'
    network = network or require 'concurrent.distributed.network'
    if #message.mailboxes[-1] > 0 then network.controller() end
    return scheduler._step(timeout)
end

-- Instead of calling the system's old tick function, one that also considers
-- networking is called.
function scheduler.tick()
    concurrent = concurrent or require 'concurrent'
    copas.step(concurrent.getoption('tick') / 1000)
end

-- Infinite or finite loop for the scheduler of a node in distributed mode.
function scheduler.loop(timeout)
    concurrent = concurrent or require 'concurrent'
    if not concurrent.node() then return scheduler._loop(timeout) end
    if timeout then
        local timer = time.time() + timeout
        while concurrent.step(timeout) and concurrent.node() and
              not scheduler.stop and timer > time.time()
        do
            concurrent.tick()
        end
    else
        while concurrent.step(timeout) and concurrent.node() and
              not scheduler.stop
        do
            concurrent.tick()
        end
    end
    scheduler.stop = false
end

return scheduler
