-- inventory_scanner.lua
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

local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core') 
local self = require('openmw.self')

local L = core.l10n('BookWorm', 'en')
local inventory_scanner = {}

function inventory_scanner.scan(inv, sourceLabel, booksRead, notesRead, utils, cfg, sessionState, player, owner)
    if not inv or not utils or not sessionState then return end
    
    local isPlayerInv = (owner == player)

    for _, item in ipairs(inv:getAll(types.Book)) do
        local id = item.recordId:lower()
        if utils.isTrackable(id) and not (booksRead[id] or notesRead[id]) then
            local bookName = utils.getBookName(id)
            -- skillLabel is now localized via utils using core.l10n('SKILLS')
            local skillLabel, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            local currentMsg = ""
            if isNote then
                -- ICU Named: New letter {source}: {name}
                currentMsg = L('InvScanner_Msg_Letter', {source = sourceLabel, name = bookName})
            elseif skillLabel then
                local labelText = L('InvScanner_Msg_RareTome') 
                if cfg.showSkillNames then
                    -- ICU Named: {skill} tome
                    -- Use localized label directly from utils
                    labelText = L('InvScanner_Msg_SkillTome', {skill = skillLabel})
                end
                -- ICU Named: New {label} {source}: {name}
                currentMsg = L('InvScanner_Msg_Discovery_Complex', {label = labelText, source = sourceLabel, name = bookName})
            else
                -- ICU Named: New tome {source}: {name}
                currentMsg = L('InvScanner_Msg_Discovery_Simple', {source = sourceLabel, name = bookName})
            end

            local shouldDisplay = true
            if isPlayerInv and cfg.throttleInventoryNotifications then
                if currentMsg == sessionState.InventoryDiscoveryMessage then
                    shouldDisplay = false
                else
                    sessionState.InventoryDiscoveryMessage = currentMsg
                end
            end

            if shouldDisplay then
                if cfg.displayNotificationMessage then
                    ui.showMessage(currentMsg)
                end

                if cfg.playNotificationSounds then
                    -- skillLabel presence indicates a skill book was found
                    if skillLabel and cfg.playSkillNotificationSounds then 
                        ambient.playSound("skillraise") 
                    else
                        ambient.playSound("Book Open")
                    end
                end
            end
            return 
        end
    end
end

return inventory_scanner