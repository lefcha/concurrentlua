-- Submodule for sending messages to remote processes.
local mime = require 'mime'

local message = require 'concurrent.message'
local concurrent, network

-- The existing version of this function for message sending is renamed.
message._send = message.send

-- Sends a message to local or remote processes.  If the process is local the
-- old renamed version of this function is used, otherwise the message is send
-- through the network.  The message is serialized and the magic cookie is also
-- attached before sent.  Returns true for success and false otherwise.
function message.send(dest, mesg)
    concurrent = concurrent or require 'concurrent'
    network = network or require 'concurrent.distributed.network'
    if type(dest) ~= 'table' then
        return message._send(concurrent.whereis(dest), mesg)
    end

    local pid, node = unpack(dest)
    local socket = network.connect(node)
    if not socket then return false end

    local data
    if concurrent.getcookie() then
        data = concurrent.getcookie() .. ' ' .. tostring(pid) .. ' ' ..
               message.serialize(mesg) .. '\r\n'
    else 
        data = tostring(pid) .. ' ' .. message.serialize(mesg) .. '\r\n'
    end
    local total = #data
    repeat 
        local n, errmsg, _ = socket:send(data, total - #data + 1)
        if not n and errmsg == 'closed' then
            network.disconnect(node)
            return false
        end
        total = total - n
    until total == 0
    if concurrent.getoption('debug') then
        print('-> ' .. string.sub(data, 1, #data - 2))
    end
    return true
end

-- Serializes an object that can be any of: nil, boolean, number, string, table,
-- function.  Returns the serialized object.
function message.serialize(obj)
    local t = type(obj)
    if t == 'nil' or t == 'boolean' or t == 'number' then
        return tostring(obj)
    elseif t == 'string' then
        return string.format("%q", obj)
    elseif t == 'function' then
        return 'loadstring((mime.unb64([[' .. (mime.b64(string.dump(obj))) ..
               ']])))'
    elseif t == 'table' then
        local t = '{'
        for k, v in pairs(obj) do
            if type(k) == 'number' or type(k) == 'boolean' then
                t = t .. ' [' .. tostring(k) .. '] = ' ..
                    message.serialize(v) .. ','
            else
                t = t .. ' ["' .. tostring(k) .. '"] = ' ..
                    message.serialize(v) .. ','
            end
        end
        t =  t .. ' }'
        return t 
    else
        error('cannot serialize a ' .. t)
    end
end

return message
