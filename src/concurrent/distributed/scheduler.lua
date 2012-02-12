-- Submodule for the scheduling of processes in a distributed node. 
require 'socket'
require 'copas'
require 'cltime'

local _scheduler = {}

-- The existing versions of these functions for then schedulers operation are
-- renamed.
_scheduler._step = concurrent.step
_scheduler._tick = concurrent.tick
_scheduler._loop = concurrent.loop

-- In addition to the operations performed for local processes, the mailbox of
-- the node itself is checked and any handlers are called to take care of the
-- messages.
function _scheduler.step(timeout)
    if #concurrent._message.mailboxes[-1] > 0 then
        concurrent._distributed._network.controller()
    end

    return _scheduler._step(timeout)
end

-- Instead of calling the system's old tick function, one that also considers
-- networking is called.
function _scheduler.tick()
    copas.step(concurrent.getoption('tick') / 1000)
end

-- Infinite or finite loop for the scheduler of a node in distributed mode.
function _scheduler.loop(timeout)
    if not concurrent.node() then
        return _scheduler._loop(timeout)
    end
    if timeout then
        local timer = cltime.time() + timeout
        while _scheduler.step(timeout) and concurrent.node() and
            not concurrent._scheduler.stop and timer > cltime.time() do
            _scheduler.tick()
        end
    else
        while _scheduler.step(timeout) and concurrent.node() and
            not concurrent._scheduler.stop do
            _scheduler.tick()
        end
    end
    concurrent._scheduler.stop = false
end

concurrent.step = _scheduler.step
concurrent.tick = _scheduler.tick
concurrent.loop = _scheduler.loop

return _scheduler
