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

local inventory_scanner = {}

function inventory_scanner.scan(inv, sourceLabel, booksRead, notesRead, utils, cfg)
    if not inv then return end
    for _, item in ipairs(inv:getAll(types.Book)) do
        local id = item.recordId:lower()
        -- Trackable Guard: Prevents enchanted scrolls from appearing in container notifications
        if utils.isTrackable(id) and not (booksRead[id] or notesRead[id]) then
            local bookName = utils.getBookName(id)
            local skillId, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            if isNote then
                ui.showMessage(string.format("New letter %s: %s", sourceLabel, bookName))
                if cfg.playNotificationSounds then ambient.playSound("Book Open") end
            elseif skillId then
                -- DYNAMIC SKILL NOTIFICATION
                local labelText = "rare tome"
                if cfg.showSkillNames then
                    local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                    labelText = skillLabel .. " tome"
                end
                ui.showMessage(string.format("New %s %s: %s", labelText, sourceLabel, bookName))
                
                -- Play skill sound if both master sounds and skill sounds are on
                if cfg.playNotificationSounds and cfg.playSkillNotificationSounds then 
                    ambient.playSound("skillraise") 
                elseif cfg.playNotificationSounds then
                    ambient.playSound("Book Open")
                end
            else
                ui.showMessage(string.format("New tome %s: %s", sourceLabel, bookName))
                if cfg.playNotificationSounds then ambient.playSound("Book Open") end
            end
            return 
        end
    end
end

return inventory_scanner