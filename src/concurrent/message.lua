-- Submodule for passing messages.
local time = require 'concurrent.time'
local concurrent, scheduler

local message = {}

message.mailboxes = {}          -- Mailboxes associated with processes.

-- Sends a messages to a process, actually, inserts it to the destination
-- mailbox.  Returns true if successful and false otherwise.
function message.send(dest, mesg)
    concurrent = concurrent or require 'concurrent'
    local pid = concurrent.whereis(dest)
    if not pid then return false end
    table.insert(message.mailboxes[pid], mesg)
    return true
end

-- Receives the oldest unread message.  If the mailbox is empty, it waits until
-- the specified timeout has expired.
function message.receive(timeout)
    concurrent = concurrent or require 'concurrent'
    scheduler = scheduler or require 'concurrent.scheduler'
    local timeouts = scheduler.timeouts
    local s = concurrent.self()
    if type(timeout) == 'number' then timeouts[s] = time.time() + timeout end
    if #message.mailboxes[s] == 0 then scheduler.sleep(timeout) end
    if #message.mailboxes[s] > 0 then
        return table.remove(message.mailboxes[s], 1)
    end
end

return message
