-- ui_handler.lua
--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org>.
--]]
 
local types = require('openmw.types')
local core = require('openmw.core')
local aux_ui = require('openmw_aux.ui') -- Added for deepDestroy

local ui_handler = {}

function ui_handler.handleModeChange(data, state)
    local p = state
    
    -- 1. Close Library UI if engine switches to a non-interface mode
    -- This happens when player hits Esc or opens the Game Menu.
    if p.activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then
        aux_ui.deepDestroy(p.activeWindow) -- Refactored
        return "CLOSE_LIBRARY" 
    end

    -- 2. Reading Logic: Direct or via Remote UI
    -- Engine (omw/ui.lua) automatically plays 'book open' here.
    if data.newMode == "Book" or data.newMode == "Scroll" then 
        types.Actor.activeEffects(p.self):remove('invisibility')
        p.reader.mark(data.arg or p.lastLookedAtObj, p.booksRead, p.notesRead, p.utils) 
    
    -- 3. Ghost Object Cleanup
    -- Engine (omw/ui.lua) automatically plays 'book close' when mode leaves Book/Scroll.
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