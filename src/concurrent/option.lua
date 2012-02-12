-- Submodule for the setting the system's options.
local _option = {}

_option.options = {}            -- System options.

_option.options.debug = false   -- Sets printing of debugging messages.

-- Returns the value of the option.
function _option.getoption(option)
    return _option.options[option]
end

-- Sets the value of the option.
function _option.setoption(option, value)
    _option.options[option] = value
end

concurrent.setoption = _option.setoption
concurrent.getoption = _option.getoption

return _option
