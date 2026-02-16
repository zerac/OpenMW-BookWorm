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
local aux_ui = require('openmw_aux.ui') 

local L = core.l10n('BookWorm', 'en')
local ui_handler = {}

function ui_handler.handleModeChange(data, state)
    local p = state
    
    if p.activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then
        aux_ui.deepDestroy(p.activeWindow)
        return "CLOSE_LIBRARY" 
    end

    if data.newMode == "Book" or data.newMode == "Scroll" then 
        types.Actor.activeEffects(p.self):remove('invisibility')
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
        if types.Lockable.objectIsInstance(obj) and types.Lockable.isLocked(obj) then
            return
        end

        local record = obj.type.record(obj)
        local name = record and record.name or L('UiHandler_Label_Container_Fallback')
        local isCorpse = (obj.type == types.NPC or obj.type == types.Creature)
        
        local sourceLabel = ""
        if data.newMode == "Barter" then 
            sourceLabel = L('UiHandler_Label_Barter') 
        elseif isCorpse then
            sourceLabel = L('UiHandler_Label_Loot')
        else
            -- ICU Named: in the {name}
            sourceLabel = L('UiHandler_Label_Container_Format', {name = name:lower()})
        end
        
        local inv = types.Actor.objectIsInstance(obj) and types.Actor.inventory(obj) or types.Container.inventory(obj)
        p.invScanner.scan(inv, sourceLabel, p.booksRead, p.notesRead, p.utils, p.cfg, p.sessionState, p.self, obj)

    elseif data.newMode == "Interface" and p.activeWindow == nil then
        p.invScanner.scan(types.Actor.inventory(p.self), L('UiHandler_Label_Inventory'), p.booksRead, p.notesRead, p.utils, p.cfg, p.sessionState, p.self, p.self)
    end
end

return ui_handler