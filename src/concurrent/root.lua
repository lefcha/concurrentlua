-- Submodule for emulating the control of a script as a process.
time = require 'concurrent.time'

_root = {}

concurrent._process.processes[0] = 0    -- Root process has PID of 0. 
concurrent._message.mailboxes[0] = {}   -- Root process mailbox.

-- The existing versions of these functions are renamed before replacing them.
_root._self = concurrent.self
_root._isalive = concurrent.isalive
_root._wait_yield = concurrent._scheduler.wait_yield
_root._sleep_yield = concurrent._scheduler.sleep_yield

-- Returns 0 if the process is not a coroutine.
function _root.self()
    return _root._self() or 0
end

-- The root process is always alive.
function _root.isalive(pid)
    if pid ~= 0 then
        return _root._isalive(pid)
    end
    return true
end

-- Special care must be taken if the root process is blocked.
function _root.wait_yield()
    local s = _root.self()

    if s ~= 0 then
        return _root._wait_yield()
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
function _root.sleep_yield()
    local timeouts = concurrent._scheduler.timeouts
    local mailboxes = concurrent._message.mailboxes
    local s = _root.self()

    if s ~= 0 then
        return _root._sleep_yield()
    end

    while true do
        if #mailboxes[s] > 0 then
            break
        end
        if timeouts[s] and time.time() - timeouts[s] >= 0 then
            timeouts[s] = nil
            return
        end
        concurrent.step()
        concurrent.tick()
    end
end

concurrent.self = _root.self
concurrent.isalive = _root.isalive
concurrent._scheduler.wait_yield = _root.wait_yield
concurrent._scheduler.sleep_yield = _root.sleep_yield

return _root
