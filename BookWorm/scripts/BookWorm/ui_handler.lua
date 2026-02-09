local types = require('openmw.types')
local core = require('openmw.core')

local ui_handler = {}

function ui_handler.handleModeChange(data, state)
    local p = state -- Reference to player script state/variables
    
    -- 1. LIBRARY UI CLEANUP
    if p.activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then
        p.activeWindow:destroy()
        return "CLOSE_LIBRARY" 
    end

    -- 2. BOOK MARKING
    if data.newMode == "Book" or data.newMode == "Scroll" then 
        p.reader.mark(data.arg or p.lastLookedAtObj, p.booksRead, p.notesRead, p.utils) 
    
    -- 3. GHOST CLEANUP
    elseif p.currentRemoteRecordId and data.newMode ~= "Book" and data.newMode ~= "Scroll" then
        core.sendGlobalEvent('BookWorm_CleanupRemote', { 
            recordId = p.currentRemoteRecordId, 
            player = p.self, 
            target = p.currentRemoteTarget 
        })
        return "CLEANUP_GHOST"
    end

    -- 4. LOOT & INVENTORY SCANNING
    if (data.newMode == "Container" or data.newMode == "Barter") and data.arg then
        local obj = data.arg
        local isLocked = false
        if obj.type == types.Container then
            isLocked = types.Lockable.isLocked(obj)
        end

        if not isLocked then
            -- RESTORED: Get actual record name (e.g., "Chest", "Barrel")
            local record = obj.type.record(obj)
            local name = record and record.name or "container"
            
            local isCorpse = (obj.type == types.NPC or obj.type == types.Creature)
            local sourceLabel = isCorpse and "the corpse" or ("the " .. name:lower())
            
            if data.newMode == "Barter" then sourceLabel = "the merchant" end
            
            p.invScanner.scan(types.Actor.inventory(obj), sourceLabel, true, p.booksRead, p.notesRead, p.utils)
        end
    elseif data.newMode == "Interface" and p.activeWindow == nil then
        p.invScanner.scan(types.Actor.inventory(p.self), "inventory", false, p.booksRead, p.notesRead, p.utils)
    end
end

return ui_handler