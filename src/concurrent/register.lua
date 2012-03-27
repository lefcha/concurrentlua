-- Submodule for process name registering.
local process = require 'concurrent.process'
local concurrent

local register = {}

register.names = {}             -- Process names and PIDs associative table.

-- Registers a PID with the specified name.  Returns true if successful or false
-- otherwise.
function register.register(name, pid)
    concurrent = concurrent or require 'concurrent'
    if concurrent.whereis(name) then return false end
    if not pid then pid = concurrent.self() end
    register.names[name] = pid
    return true
end

-- Unregisters the specified process name.  Returns true if successful or
-- false otherwise.
function register.unregister(name)
    concurrent = concurrent or require 'concurrent'
    if not name then name = concurrent.self() end
    for k, v in pairs(register.names) do
        if name == k or name == v then
            register.names[k] = nil
            return true
        end
    end
    return false
end

-- Returns a table with the names of all the registered processes.
function register.registered()
    local n = {}
    for k, _ in pairs(register.names) do table.insert(n, k) end
    return n
end

-- Returns the PID of the process specified by its registered name.
function register.whereis(name)
    if type(name) == 'number' then return name end
    if not register.names[name] then return end
    return register.names[name]
end

-- Terminated or aborted processes should not be registered anymore.
table.insert(process.ondeath, register.unregister)
table.insert(process.ondestruction, register.unregister)

return register
