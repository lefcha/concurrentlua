-- Submodule for creating and destroying processes.
local concurrent, message, scheduler

local process = {}

process.processes = {}          -- All the processes in the system.

process.ondeath = {}            -- Functions to execute on abnormal exit.
process.ondestruction = {}      -- Functions to execute on termination.

-- Creates a process and its mailbox, and initializes its sleep timeout to be
-- used by the scheduler.  Returns a PID or in case of error nil and an
-- error message.
function process.spawn(func, ...)
    message = message or require 'concurrent.message'
    scheduler = scheduler or require 'concurrent.scheduler'
    local co = coroutine.create(
        function (...)
            coroutine.yield()
            func(...)
            process.destroy()
        end)
    table.insert(process.processes, co)
    local pid = #process.processes
    message.mailboxes[pid] = {}
    scheduler.timeouts[pid] = 0
    local status, errmsg = process.resume(co, ...)
    if not status then return nil, errmsg end
    return pid
end

-- Resumes a suspended process.  Returns its status and any coroutine related
-- error messages.
function process.resume(co, ...)
    if type(co) ~= 'thread' or coroutine.status(co) ~= 'suspended' then
        return
    end
    local status, errmsg = coroutine.resume(co, ...)
    if not status then
        local pid = process.whois(co)
        process.die(pid, errmsg)
    end
    return status, errmsg
end

-- Returns the PID of the calling process.
function process.self()
    local co = coroutine.running()
    if co then return process.whois(co) end
end

-- Returns the PID of the specified coroutine.
function process.whois(co)
    for k, v in pairs(process.processes) do
        if v == co then return k end
    end
end

-- Returns the status of a specific process, that can be either alive or dead.
function process.isalive(pid)
    local co = process.processes[pid]
    if co and type(co) == 'thread' and coroutine.status(co) ~= 'dead' then
        return true
    else
        return false
    end
end

-- Causes abnormal exit of the calling process.
function process.exit(reason)
    error(reason, 0)
end

-- Terminates the specified process.
function process.kill(pid, reason)
    if type(process.processes[pid]) == 'thread' and
       coroutine.status(process.processes[pid]) == 'suspended'
    then
        local status, errmsg = coroutine.resume(process.processes[pid], 'EXIT')
        process.die(pid, errmsg)
    end
end

-- Executes the functions registered to be run upon process termination.
function process.destroy()
    concurrent = concurrent or require 'concurrent'
    for _, v in ipairs(process.ondestruction) do
        v(concurrent.self(), 'normal')
    end
end

-- Executes the functions registered to be run upon process abnormal exit.
function process.die(pid, reason)
    for _, v in ipairs(process.ondeath) do v(pid, reason) end
end 

-- Returns the PID of a process.
function process.whereis(pid)
    return pid
end

return process
