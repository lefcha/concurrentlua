-- Submodule for process name registering.
module('concurrent._register', package.seeall)

names = {}                      -- Process names and PIDs associative table.

-- Registers a PID with the specified name.  Returns true if successful or false
-- otherwise.
function register(name, pid)
    if whereis(name) then
        return false
    end
    if not pid then
        pid = concurrent.self()
    end
    names[name] = pid
    return true
end

-- Unregisters the specified process name.  Returns true if successful or
-- false otherwise.
function unregister(name)
    if not name then
        name = concurrent.self()
    end
    for k, v in pairs(names) do
        if name == k or name == v then
            names[k] = nil
            return true
        end
    end
    return false
end

-- Returns a table with the names of all the registered processes.
function registered()
    local n = {}
    for k, _ in pairs(names) do
        table.insert(n, k)
    end
    return n
end

-- Returns the PID of the process specified by its registered name.
function whereis(name)
    if type(name) == 'number' then
        return name
    end
    if not names[name] then
        return
    end
    return names[name]
end

-- Terminated or aborted processes should not be registered anymore.
table.insert(concurrent._process.ondeath, unregister)
table.insert(concurrent._process.ondestruction, unregister)

concurrent.register = register
concurrent.unregister = unregister
concurrent.registered = registered
concurrent.whereis = whereis
