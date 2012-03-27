-- Submodule for scheduling processes.
local time = require 'concurrent.time'
local option = require 'concurrent.option'
local concurrent, process, message

local scheduler = {}

scheduler.timeouts = {}         -- Timeouts for processes that are suspended. 
scheduler.barriers = {}         -- Barriers for blocked processes.

scheduler.stop = false          -- Flag to interrupt the scheduler.

option.options.tick = 10        -- Scheduler clock time advances.

-- Performs a step of the scheduler's operations.  Resumes processes that are no
-- longer blocked and then resumes processes that are waiting for a message and
-- one has arrived.  If all processes are dead, it instructs the scheduler loop
-- about it.
function scheduler.step(timeout)
    process = process or require 'concurrent.process'
    message = message or require 'concurrent.message'

    for k, v in pairs(scheduler.barriers) do
        if v then process.resume(process.processes[k]) end
    end

    for k, v in pairs(process.processes) do
        if #message.mailboxes[k] > 0 or
           (scheduler.timeouts[k] and time.time() - scheduler.timeouts[k] >= 0)
        then
            if scheduler.timeouts[k] then scheduler.timeouts[k] = nil end
            if type(scheduler.barriers[k]) == 'nil' then process.resume(v) end
        end
    end

    if not timeout then
        local alive = false
        for _, v in ipairs(process.processes) do
            if coroutine.status(v) ~= 'dead' then alive = true end
        end
        if not alive then return false end
    end
    
    return true
end

-- Advances the system clock by a tick.
function scheduler.tick()
    concurrent = concurrent or require 'concurrent'
    time.sleep(concurrent.getoption('tick'))
end

-- Infinite or finite loop of the scheduler. Continuesly performs a scheduler
-- step and advances the system clock by a tick. Checks for scheduler interrupts
-- or for a hint in case all processes are dead.
function scheduler.loop(timeout)
    concurrent = concurrent or require 'concurrent'
    if timeout then
        local timer = time.time() + timeout
        while concurrent.step(timeout) and not scheduler.stop and
              timer > time.time()
        do
            concurrent.tick()
        end
    else
        while concurrent.step(timeout) and not scheduler.stop do
            concurrent.tick()
        end
    end
    scheduler.stop = false
end

-- Raises the flag to cause a scheduler interrupt.
function scheduler.interrupt()
    scheduler.stop = true
end

-- Sets a barrier for the calling process.
function scheduler.wait()
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    if not scheduler.barriers[s] then
        scheduler.barriers[s] = false
        scheduler.wait_yield()
    end
    r = scheduler.barriers[s]
    scheduler.barriers[s] = nil
    return r
end

-- Actions to be performed during a wait yield.
function scheduler.wait_yield()
    scheduler.yield()
end

-- Sets a sleep timeout for the calling process.
function scheduler.sleep(timeout)
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()
    if timeout then scheduler.timeouts[s] = time.time() + timeout end
    scheduler.sleep_yield()
    if timeout then scheduler.timeouts[s] = nil end
end

-- Actions to be performed during a sleep yield.
function scheduler.sleep_yield()
    scheduler.yield()
end

-- Yields a process , but first checks if the process is exiting intentionally.
function scheduler.yield()
    if coroutine.yield() == 'EXIT' then error('EXIT', 0) end
end

return scheduler
