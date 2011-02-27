-- Submodule for setting the magic cookie.
module('concurrent._distributed._cookie', package.seeall)

cookie = nil                    -- The magic cookie used for authentication.

-- Sets the magic cookie.
function setcookie(c)
    if concurrent.node() then
        cookie = c
    end
end

-- Returns the set magic cookie.
function getcookie()
    return cookie
end

concurrent.setcookie = setcookie
concurrent.getcookie = getcookie
