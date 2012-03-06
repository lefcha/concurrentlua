-- Submodule for passing messages.
time = require 'concurrent.time'

local _message = {}

_message.mailboxes = {}         -- Mailboxes associated with processes.

-- Sends a messages to a process, actually, inserts it to the destination
-- mailbox.  Returns true if successful and false otherwise.
function _message.send(dest, mesg)
    local pid = concurrent.whereis(dest)
    if not pid then
        return false
    end
    table.insert(_message.mailboxes[pid], mesg)
    return true
end

-- Receives the oldest unread message.  If the mailbox is empty, it waits until
-- the specified timeout has expired.
function _message.receive(timeout)
    local timeouts = concurrent._scheduler.timeouts
    local s = concurrent.self()
    if type(timeout) == 'number' then
        timeouts[s] = time.time() + timeout
    end
    if #_message.mailboxes[s] == 0 then
        concurrent._scheduler.sleep(timeout)
    end
    if #_message.mailboxes[s] > 0 then
        return table.remove(_message.mailboxes[s], 1)
    end
end

concurrent.send = _message.send
concurrent.receive = _message.receive

return _message
