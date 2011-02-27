-- Submodule for scheduling processes.
module('concurrent._scheduler', package.seeall)

require 'cltime'

timeouts = {}                   -- Timeouts for processes that are suspended. 
barriers = {}                   -- Barriers for blocked processes.

stop = false                    -- Flag to interrupt the scheduler.

concurrent._option.options.tick = 10    -- Scheduler clock time advances.

-- Performs a step of the scheduler's operations.  Resumes processes that are no
-- longer blocked and then resumes processes that are waiting for a message and
-- one has arrived.  If all processes are dead, it instructs the scheduler loop
-- about it.
function step(timeout)
    for k, v in pairs(barriers) do
        if v then
            concurrent._process.resume(concurrent._process.processes[k])
        end
    end

    for k, v in pairs(concurrent._process.processes) do
        if #concurrent._message.mailboxes[k] > 0 or (timeouts[k] and
            cltime.time() - timeouts[k] >= 0) then
            if timeouts[k] then
                timeouts[k] = nil
            end
            if type(barriers[k]) == 'nil' then
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
function tick()
    cltime.sleep(concurrent.getoption('tick'))
end

-- Infinite or finite loop of the scheduler. Continuesly performs a scheduler
-- step and advances the system clock by a tick. Checks for scheduler interrupts
-- or for a hint in case all processes are dead.
function loop(timeout)
    if timeout then
        local timer = cltime.time() + timeout
        while step(timeout) and not stop and timer > cltime.time() do
            tick()
        end
    else
        while step(timeout) and not stop do
            tick()
        end
    end
    stop = false
end

-- Raises the flag to cause a scheduler interrupt.
function interrupt()
    stop = true
end

-- Sets a barrier for the calling process.
function wait()
    local s = concurrent.self()
    if not barriers[s] then
        barriers[s] = false
        wait_yield()
    end
    r = barriers[s]
    barriers[s] = nil
    return r
end

-- Actions to be performed during a wait yield.
function wait_yield()
    yield()
end

-- Sets a sleep timeout for the calling process.
function sleep(timeout)
    local s = concurrent.self()
    if timeout then
        timeouts[s] = cltime.time() + timeout
    end
    sleep_yield()
    if timeout then
        timeouts[s] = nil
    end
end

-- Actions to be performed during a sleep yield.
function sleep_yield()
    yield()
end

-- Yields a process , but first checks if the process is exiting intentionally.
function yield()
    if coroutine.yield() == 'EXIT' then
        error('EXIT', 0)
    end
end

concurrent.step = step
concurrent.tick = tick
concurrent.loop = loop
concurrent.interrupt = interrupt
concurrent.sleep = sleep
