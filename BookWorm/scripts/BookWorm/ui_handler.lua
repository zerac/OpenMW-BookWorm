local types = require('openmw.types')
local core = require('openmw.core')
local aux_ui = require('openmw_aux.ui') -- Added for deepDestroy

local ui_handler = {}

function ui_handler.handleModeChange(data, state)
    local p = state
    
    -- 1. Close Library UI if engine switches to a non-interface mode
    if p.activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then
        aux_ui.deepDestroy(p.activeWindow) -- Refactored
        return "CLOSE_LIBRARY" 
    end

    -- 2. Reading Logic: Direct or via Remote UI
    if data.newMode == "Book" or data.newMode == "Scroll" then 
        types.Actor.activeEffects(p.self):remove('invisibility')
        p.reader.mark(data.arg or p.lastLookedAtObj, p.booksRead, p.notesRead, p.utils) 
    
    -- 3. Ghost Object Cleanup
    elseif p.currentRemoteRecordId and data.newMode ~= "Book" and data.newMode ~= "Scroll" then
        core.sendGlobalEvent('BookWorm_CleanupRemote', { 
            recordId = p.currentRemoteRecordId, 
            player = p.self, 
            target = p.currentRemoteTarget 
        })
        return "CLEANUP_GHOST"
    end

    -- 4. Container & Barter Scanning
    if (data.newMode == "Container" or data.newMode == "Barter") and data.arg then
        local obj = data.arg
        if types.Lockable.objectIsInstance(obj) and types.Lockable.isLocked(obj) then
            return
        end

        local record = obj.type.record(obj)
        local name = record and record.name or "container"
        local isCorpse = (obj.type == types.NPC or obj.type == types.Creature)
        
        local sourceLabel = ""
        if data.newMode == "Barter" then 
            sourceLabel = "for sale" 
        elseif isCorpse then
            sourceLabel = "to loot"
        else
            sourceLabel = "in the " .. name:lower()
        end
        
        local inv = types.Actor.objectIsInstance(obj) and types.Actor.inventory(obj) or types.Container.inventory(obj)
        p.invScanner.scan(inv, sourceLabel, true, p.booksRead, p.notesRead, p.utils)

    elseif data.newMode == "Interface" and p.activeWindow == nil then
        p.invScanner.scan(types.Actor.inventory(p.self), "in inventory", false, p.booksRead, p.notesRead, p.utils)
    end
end

return ui_handler