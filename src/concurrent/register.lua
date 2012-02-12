-- Submodule for process name registering.
local _register = {}

_register.names = {}            -- Process names and PIDs associative table.

-- Registers a PID with the specified name.  Returns true if successful or false
-- otherwise.
function _register.register(name, pid)
    if _register.whereis(name) then
        return false
    end
    if not pid then
        pid = concurrent.self()
    end
    _register.names[name] = pid
    return true
end

-- Unregisters the specified process name.  Returns true if successful or
-- false otherwise.
function _register.unregister(name)
    if not name then
        name = concurrent.self()
    end
    for k, v in pairs(_register.names) do
        if name == k or name == v then
            _register.names[k] = nil
            return true
        end
    end
    return false
end

-- Returns a table with the names of all the registered processes.
function _register.registered()
    local n = {}
    for k, _ in pairs(_register.names) do
        table.insert(n, k)
    end
    return n
end

-- Returns the PID of the process specified by its registered name.
function _register.whereis(name)
    if type(name) == 'number' then
        return name
    end
    if not _register.names[name] then
        return
    end
    return _register.names[name]
end

-- Terminated or aborted processes should not be registered anymore.
table.insert(concurrent._process.ondeath, _register.unregister)
table.insert(concurrent._process.ondestruction, _register.unregister)

concurrent.register = _register.register
concurrent.unregister = _register.unregister
concurrent.registered = _register.registered
concurrent.whereis = _register.whereis

return _register
