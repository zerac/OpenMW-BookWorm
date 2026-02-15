--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
--]]

local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')

local inventory_scanner = {}

function inventory_scanner.scan(inv, sourceLabel, booksRead, notesRead, utils, cfg)
    if not inv then return end
    for _, item in ipairs(inv:getAll(types.Book)) do
        local id = item.recordId:lower()
        if utils.isTrackable(id) and not (booksRead[id] or notesRead[id]) then
            local bookName = utils.getBookName(id)
            local skillId, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            if cfg.displayNotificationMessage then
                if isNote then
                    ui.showMessage(string.format("New letter %s: %s", sourceLabel, bookName))
                elseif skillId then
                    local labelText = "rare tome"
                    if cfg.showSkillNames then
                        local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                        labelText = skillLabel .. " tome"
                    end
                    ui.showMessage(string.format("New %s %s: %s", labelText, sourceLabel, bookName))
                else
                    ui.showMessage(string.format("New tome %s: %s", sourceLabel, bookName))
                end
            end

            -- Audio logic remains independent
            if cfg.playNotificationSounds then
                if skillId and cfg.playSkillNotificationSounds then
                    ambient.playSound("skillraise")
                else
                    ambient.playSound("Book Open")
                end
            end
            return 
        end
    end
end

return inventory_scanner