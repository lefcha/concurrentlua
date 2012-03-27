-- Submodule for setting the magic cookie.
local concurrent

local cookie = {}

cookie.cookie = nil             -- The magic cookie used for authentication.

-- Sets the magic cookie.
function cookie.setcookie(c)
    concurrent = concurrent or require 'concurrent'
    if concurrent.node() then cookie.cookie = c end
end

-- Returns the set magic cookie.
function cookie.getcookie()
    return cookie.cookie
end

return cookie
