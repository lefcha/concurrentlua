-- Submodule for the scheduling of processes in a distributed node. 
module('concurrent._distributed._scheduler', package.seeall)

require 'socket'
require 'copas'
require 'cltime'

-- The existing versions of these functions for then schedulers operation are
-- renamed.
_step = concurrent.step
_tick = concurrent.tick
_loop = concurrent.loop

-- In addition to the operations performed for local processes, the mailbox of
-- the node itself is checked and any handlers are called to take care of the
-- messages.
function step(timeout)
    if #concurrent._message.mailboxes[-1] > 0 then
        concurrent._distributed._network.controller()
    end

    return _step(timeout)
end

-- Instead of calling the system's old tick function, one that also considers
-- networking is called.
function tick()
    copas.step(concurrent.getoption('tick') / 1000)
end

-- Infinite or finite loop for the scheduler of a node in distributed mode.
function loop(timeout)
    if not concurrent.node() then
        return _loop(timeout)
    end
    if timeout then
        local timer = cltime.time() + timeout
        while step(timeout) and concurrent.node() and
            not concurrent._scheduler.stop and timer > cltime.time() do
            tick()
        end
    else
        while step(timeout) and concurrent.node() and
            not concurrent._scheduler.stop do
            tick()
        end
    end
    concurrent._scheduler.stop = false
end

concurrent.step = step
concurrent.tick = tick
concurrent.loop = loop
