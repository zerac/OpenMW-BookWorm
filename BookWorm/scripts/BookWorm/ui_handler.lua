local types = require('openmw.types')
local core = require('openmw.core')

local ui_handler = {}

function ui_handler.handleModeChange(data, state)
    local p = state
    
    if p.activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then
        p.activeWindow:destroy()
        return "CLOSE_LIBRARY" 
    end

    if data.newMode == "Book" or data.newMode == "Scroll" then 
        p.reader.mark(data.arg or p.lastLookedAtObj, p.booksRead, p.notesRead, p.utils) 
    
    elseif p.currentRemoteRecordId and data.newMode ~= "Book" and data.newMode ~= "Scroll" then
        core.sendGlobalEvent('BookWorm_CleanupRemote', { 
            recordId = p.currentRemoteRecordId, 
            player = p.self, 
            target = p.currentRemoteTarget 
        })
        return "CLEANUP_GHOST"
    end

    if (data.newMode == "Container" or data.newMode == "Barter") and data.arg then
        local obj = data.arg
        local isLocked = false
        if obj.type == types.Container then
            isLocked = types.Lockable.isLocked(obj)
        end

        if not isLocked then
            local record = obj.type.record(obj)
            local name = record and record.name or "container"
            local isCorpse = (obj.type == types.NPC or obj.type == types.Creature)
            
            -- PREPOSITION FIX: Labels now contain their own logic
            local sourceLabel = ""
            if data.newMode == "Barter" then 
                sourceLabel = "for sale" 
            elseif isCorpse then
                sourceLabel = "to loot"
            else
                sourceLabel = "in the " .. name:lower()
            end
            
            p.invScanner.scan(types.Actor.inventory(obj), sourceLabel, true, p.booksRead, p.notesRead, p.utils)
        end
    elseif data.newMode == "Interface" and p.activeWindow == nil then
        -- INVENTORY FIX: Add "in" back specifically for the player's bags
        p.invScanner.scan(types.Actor.inventory(p.self), "in inventory", false, p.booksRead, p.notesRead, p.utils)
    end
end

return ui_handler