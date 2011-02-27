-- Submodule for the setting the system's options.
module('concurrent._option', package.seeall)

options = {}                    -- System options.

options.debug = false           -- Sets printing of debugging messages.

-- Returns the value of the option.
function getoption(option)
    return options[option]
end

-- Sets the value of the option.
function setoption(option, value)
    options[option] = value
end

concurrent.setoption = setoption
concurrent.getoption = getoption
