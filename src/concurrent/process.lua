-- Submodule for creating and destroying processes.
local _process = {}

_process.processes = {}         -- All the processes in the system.

_process.ondeath = {}           -- Functions to execute on abnormal exit.
_process.ondestruction = {}     -- Functions to execute on termination.

-- Creates a process and its mailbox, and initializes its sleep timeout to be
-- used by the scheduler.  Returns a PID or in case of error nil and an
-- error message.
function _process.spawn(func, ...)
    local co = coroutine.create(
        function (...)
            coroutine.yield()
            func(...)
            _process.destroy()
        end)
    table.insert(_process.processes, co)
    local pid = #_process.processes
    concurrent._message.mailboxes[pid] = {}
    concurrent._scheduler.timeouts[pid] = 0
    local status, errmsg = _process.resume(co, ...)
    if not status then
        return nil, errmsg
    end
    return pid
end

-- Resumes a suspended process.  Returns its status and any coroutine related
-- error messages.
function _process.resume(co, ...)
    if type(co) ~= 'thread' or coroutine.status(co) ~= 'suspended' then
        return
    end
    local status, errmsg = coroutine.resume(co, ...)
    if not status then
        local pid = _process.whois(co)
        _process.die(pid, errmsg)
    end
    return status, errmsg
end

-- Returns the PID of the calling process.
function _process.self()
    local co = coroutine.running()
    if co then
        return _process.whois(co)
    end
end

-- Returns the PID of the specified coroutine.
function _process.whois(co)
    for k, v in pairs(_process.processes) do
        if v == co then
            return k
        end
    end
end

-- Returns the status of a specific process, that can be either alive or dead.
function _process.isalive(pid)
    local co = _process.processes[pid]
    if co and type(co) == 'thread' and coroutine.status(co) ~= 'dead' then
        return true
    else
        return false
    end
end

-- Causes abnormal exit of the calling process.
function _process.exit(reason)
    error(reason, 0)
end

-- Terminates the specified process.
function _process.kill(pid, reason)
    if type(_process.processes[pid]) == 'thread' and
        coroutine.status(_process.processes[pid]) == 'suspended' then
        local status, errmsg = coroutine.resume(_process.processes[pid], 'EXIT')
        _process.die(pid, errmsg)
    end
end

-- Executes the functions registered to be run upon process termination.
function _process.destroy()
    for _, v in ipairs(_process.ondestruction) do
        v(concurrent.self(), 'normal')
    end
end

-- Executes the functions registered to be run upon process abnormal exit.
function _process.die(pid, reason)
    for _, v in ipairs(_process.ondeath) do
        v(pid, reason)
    end
end 

-- Returns the PID of a process.
function _process.whereis(pid)
    return pid
end

concurrent.spawn = _process.spawn
concurrent.self = _process.self
concurrent.isalive = _process.isalive
concurrent.exit = _process.exit
concurrent.whereis = _process.whereis

return _process
