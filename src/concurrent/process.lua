-- Submodule for creating and destroying processes.
module('concurrent._process', package.seeall)

processes = {}                  -- All the processes in the system.

ondeath = {}                    -- Functions to execute on abnormal exit.
ondestruction = {}              -- Functions to execute on termination.

-- Creates a process and its mailbox, and initializes its sleep timeout to be
-- used by the scheduler.  Returns a PID or in case of error nil and an
-- error message.
function spawn(func, ...)
    local co = coroutine.create(
        function (...)
            coroutine.yield()
            func(...)
            destroy()
        end)
    table.insert(processes, co)
    local pid = #processes
    concurrent._message.mailboxes[pid] = {}
    concurrent._scheduler.timeouts[pid] = 0
    local status, errmsg = resume(co, ...)
    if not status then
        return nil, errmsg
    end
    return pid
end

-- Resumes a suspended process.  Returns its status and any coroutine related
-- error messages.
function resume(co, ...)
    if type(co) ~= 'thread' or coroutine.status(co) ~= 'suspended' then
        return
    end
    local status, errmsg = coroutine.resume(co, ...)
    if not status then
        local pid = whois(co)
        die(pid, errmsg)
    end
    return status, errmsg
end

-- Returns the PID of the calling process.
function self()
    local co = coroutine.running()
    if co then
        return whois(co)
    end
end

-- Returns the PID of the specified coroutine.
function whois(co)
    for k, v in pairs(processes) do
        if v == co then
            return k
        end
    end
end

-- Returns the status of a specific process, that can be either alive or dead.
function isalive(pid)
    local co = processes[pid]
    if co and type(co) == 'thread' and coroutine.status(co) ~= 'dead' then
        return true
    else
        return false
    end
end

-- Causes abnormal exit of the calling process.
function exit(reason)
    error(reason, 0)
end

-- Terminates the specified process.
function kill(pid, reason)
    if type(processes[pid]) == 'thread' and
        coroutine.status(processes[pid]) == 'suspended' then
        local status, errmsg = coroutine.resume(processes[pid], 'EXIT')
        die(pid, errmsg)
    end
end

-- Executes the functions registered to be run upon process termination.
function destroy()
    for _, v in ipairs(ondestruction) do
        v(concurrent.self(), 'normal')
    end
end

-- Executes the functions registered to be run upon process abnormal exit.
function die(pid, reason)
    for _, v in ipairs(ondeath) do
        v(pid, reason)
    end
end 

-- Returns the PID of a process.
function whereis(pid)
    return pid
end

concurrent.spawn = spawn
concurrent.spawnmonitor = spawnmonitor
concurrent.self = self
concurrent.isalive = isalive
concurrent.exit = exit
concurrent.whereis = whereis
