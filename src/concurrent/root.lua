-- Submodule for emulating the control of a script as a process.
local time = require 'concurrent.time'
local process = require 'concurrent.process'
local message = require 'concurrent.message'
local scheduler = require 'concurrent.scheduler'
local concurrent

process.processes[0] = 0        -- Root process has PID of 0. 
message.mailboxes[0] = {}       -- Root process mailbox.

-- The existing versions of these functions are renamed before replacing them.
process._self = process.self
process._isalive = process.isalive
scheduler._wait_yield = scheduler.wait_yield
scheduler._sleep_yield = scheduler.sleep_yield

-- Returns 0 if the process is not a coroutine.
function process.self()
    return process._self() or 0
end

-- The root process is always alive.
function process.isalive(pid)
    if pid ~= 0 then return process._isalive(pid) end
    return true
end

-- Special care must be taken if the root process is blocked.
function scheduler.wait_yield()
    concurrent = concurrent or require 'concurrent'
    local s = concurrent.self()

    if s ~= 0 then return scheduler._wait_yield() end

    while true do
        if scheduler.barriers[s] then break end
        concurrent.step()
        concurrent.tick()
    end
end

-- Special care must be taken if the root process is sleeping.
function scheduler.sleep_yield()
    concurrent = concurrent or require 'concurrent'
    local timeouts = scheduler.timeouts
    local mailboxes = message.mailboxes
    local s = concurrent.self()

    if s ~= 0 then return scheduler._sleep_yield() end

    while true do
        if #mailboxes[s] > 0 then break end
        if timeouts[s] and time.time() - timeouts[s] >= 0 then
            timeouts[s] = nil
            return
        end
        concurrent.step()
        concurrent.tick()
    end
end

return process
