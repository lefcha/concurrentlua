-- Submodule for emulating the control of a script as a process.
module('concurrent._root', package.seeall)

concurrent._process.processes[0] = 0    -- Root process has PID of 0. 
concurrent._message.mailboxes[0] = {}   -- Root process mailbox.

-- The existing versions of these functions are renamed before replacing them.
_self = concurrent.self
_isalive = concurrent.isalive
_wait_yield = concurrent._scheduler.wait_yield
_sleep_yield = concurrent._scheduler.sleep_yield

-- Returns 0 if the process is not a coroutine.
function self()
    return _self() or 0
end

-- The root process is always alive.
function isalive(pid)
    if pid ~= 0 then
        return _isalive(pid)
    end
    return true
end

-- Special care must be taken if the root process is blocked.
function wait_yield()
    local s = self()

    if s ~= 0 then
        return _wait_yield()
    end

    while true do
        if concurrent._scheduler.barriers[s] then
            break
        end
        concurrent.step()
        concurrent.tick()
    end
end

-- Special care must be taken if the root process is sleeping.
function sleep_yield()
    local timeouts = concurrent._scheduler.timeouts
    local mailboxes = concurrent._message.mailboxes
    local s = self()

    if s ~= 0 then
        return _sleep_yield()
    end

    while true do
        if #mailboxes[s] > 0 then
            break
        end
        if timeouts[s] and cltime.time() - timeouts[s] >= 0 then
            timeouts[s] = nil
            return
        end
        concurrent.step()
        concurrent.tick()
    end
end

concurrent.self = self
concurrent.isalive = isalive
concurrent._scheduler.wait_yield = wait_yield
concurrent._scheduler.sleep_yield = sleep_yield
