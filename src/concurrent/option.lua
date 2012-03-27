-- Submodule for the setting the system's options.
local option = {}

option.options = {}             -- System options.

option.options.debug = false    -- Sets printing of debugging messages.

-- Returns the value of the option.
function option.getoption(key)
    return option.options[key]
end

-- Sets the value of the option.
function option.setoption(key, value)
    option.options[key] = value
end

return option
