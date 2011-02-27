-- Submodule for passing messages.
module('concurrent._message', package.seeall)

require 'cltime'

mailboxes = {}                  -- Mailboxes associated with processes.

-- Sends a messages to a process, actually, inserts it to the destination
-- mailbox.  Returns true if successful and false otherwise.
function send(dest, mesg)
    local pid = concurrent.whereis(dest)
    if not pid then
        return false
    end
    table.insert(mailboxes[pid], mesg)
    return true
end

-- Receives the oldest unread message.  If the mailbox is empty, it waits until
-- the specified timeout has expired.
function receive(timeout)
    local timeouts = concurrent._scheduler.timeouts
    local s = concurrent.self()
    if type(timeout) == 'number' then
        timeouts[s] = cltime.time() + timeout
    end
    if #mailboxes[s] == 0 then
        concurrent._scheduler.sleep(timeout)
    end
    if #mailboxes[s] > 0 then
        return table.remove(mailboxes[s], 1)
    end
end

concurrent.send = send
concurrent.receive = receive
