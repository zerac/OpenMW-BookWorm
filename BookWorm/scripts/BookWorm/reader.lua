-- reader.lua
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
local storage = require('openmw.storage')

local reader = {}

-- SETTINGS ACCESS
local notifSettings = storage.playerSection("Settings_BookWorm_Notif")

function reader.mark(obj, booksRead, notesRead, utils)
    -- Enforce Trackable Guard: Stops enchanted scrolls from being marked or messaging
    if not obj or obj.type ~= types.Book or not utils.isTrackable(obj.recordId) then return end
    
    local id = obj.recordId:lower()
    local isNote = utils.isLoreNote(id)
    local targetTable = isNote and notesRead or booksRead
    
    local bookName = utils.getBookName(id)
    local recognizeSkills = notifSettings:get("recognizeSkillBooks")
    local showNames = notifSettings:get("showSkillNames")
    
    -- FIXED: The 'on reading' setting now strictly dictates visibility for this function
    local canShow = notifSettings:get("displayNotificationMessageOnReading")

    if targetTable[id] then 
        if canShow then
            ui.showMessage("(Already read) " .. bookName)
        end
    else
        targetTable[id] = core.getSimulationTime()
        
        if canShow then
            local skillId, _ = utils.getSkillInfo(id)
            if skillId and recognizeSkills then
                local labelText = "rare tome"
                if showNames then
                    local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                    labelText = skillLabel .. " tome"
                end
                ui.showMessage(string.format("Marked as read: %s (%s)", bookName, labelText))
            else
                ui.showMessage("Marked as read: " .. bookName)
            end
        end
    end
end

return reader