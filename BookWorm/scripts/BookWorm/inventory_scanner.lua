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

function inventory_scanner.scan(inv, sourceLabel, playSkillSound, booksRead, notesRead, utils)
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
            elseif skillId then
                -- DYNAMIC SKILL NOTIFICATION
                local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                ui.showMessage(string.format("New %s tome %s: %s", skillLabel, sourceLabel, bookName))
                if playSkillSound then ambient.playSound("skillraise") end
            else
                ui.showMessage(string.format("New tome %s: %s", sourceLabel, bookName))
            end
            return 
        end
    end
end

return inventory_scanner