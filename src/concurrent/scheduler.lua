-- Submodule for scheduling processes.
time = require 'concurrent.time'

local _scheduler = {}

_scheduler.timeouts = {}        -- Timeouts for processes that are suspended. 
_scheduler.barriers = {}        -- Barriers for blocked processes.

_scheduler.stop = false         -- Flag to interrupt the scheduler.

concurrent._option.options.tick = 10    -- Scheduler clock time advances.

-- Performs a step of the scheduler's operations.  Resumes processes that are no
-- longer blocked and then resumes processes that are waiting for a message and
-- one has arrived.  If all processes are dead, it instructs the scheduler loop
-- about it.
function _scheduler.step(timeout)
    for k, v in pairs(_scheduler.barriers) do
        if v then
            concurrent._process.resume(concurrent._process.processes[k])
        end
    end

    for k, v in pairs(concurrent._process.processes) do
        if #concurrent._message.mailboxes[k] > 0 or (_scheduler.timeouts[k] and
            time.time() - _scheduler.timeouts[k] >= 0) then
            if _scheduler.timeouts[k] then
                _scheduler.timeouts[k] = nil
            end
            if type(_scheduler.barriers[k]) == 'nil' then
                concurrent._process.resume(v)
            end
        end
    end

    if not timeout then
        local alive = false
        for _, v in ipairs(concurrent._process.processes) do
            if coroutine.status(v) ~= 'dead' then
                alive = true
            end
        end
        if not alive then
            return false
        end
    end
    
    return true
end

-- Advances the system clock by a tick.
function _scheduler.tick()
    time.sleep(concurrent.getoption('tick'))
end

-- Infinite or finite loop of the scheduler. Continuesly performs a scheduler
-- step and advances the system clock by a tick. Checks for scheduler interrupts
-- or for a hint in case all processes are dead.
function _scheduler.loop(timeout)
    if timeout then
        local timer = time.time() + timeout
        while _scheduler.step(timeout) and not _scheduler.stop and
            timer > time.time() do
            _scheduler.tick()
        end
    else
        while _scheduler.step(timeout) and not _scheduler.stop do
            _scheduler.tick()
        end
    end
    _scheduler.stop = false
end

-- Raises the flag to cause a scheduler interrupt.
function _scheduler.interrupt()
    _scheduler.stop = true
end

-- Sets a barrier for the calling process.
function _scheduler.wait()
    local s = concurrent.self()
    if not _scheduler.barriers[s] then
        _scheduler.barriers[s] = false
        _scheduler.wait_yield()
    end
    r = _scheduler.barriers[s]
    _scheduler.barriers[s] = nil
    return r
end

-- Actions to be performed during a wait yield.
function _scheduler.wait_yield()
    _scheduler.yield()
end

-- Sets a sleep timeout for the calling process.
function _scheduler.sleep(timeout)
    local s = concurrent.self()
    if timeout then
        _scheduler.timeouts[s] = time.time() + timeout
    end
    _scheduler.sleep_yield()
    if timeout then
        _scheduler.timeouts[s] = nil
    end
end

-- Actions to be performed during a sleep yield.
function _scheduler.sleep_yield()
    _scheduler.yield()
end

-- Yields a process , but first checks if the process is exiting intentionally.
function _scheduler.yield()
    if coroutine.yield() == 'EXIT' then
        error('EXIT', 0)
    end
end

concurrent.step = _scheduler.step
concurrent.tick = _scheduler.tick
concurrent.loop = _scheduler.loop
concurrent.interrupt = _scheduler.interrupt
concurrent.sleep = _scheduler.sleep

return _scheduler
