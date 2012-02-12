-- Submodule for setting the magic cookie.
local _cookie = {}

_cookie.cookie = nil            -- The magic cookie used for authentication.

-- Sets the magic cookie.
function _cookie.setcookie(c)
    if concurrent.node() then
        _cookie.cookie = c
    end
end

-- Returns the set magic cookie.
function _cookie.getcookie()
    return _cookie.cookie
end

concurrent.setcookie = _cookie.setcookie
concurrent.getcookie = _cookie.getcookie

return _cookie
