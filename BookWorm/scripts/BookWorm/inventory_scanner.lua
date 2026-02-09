local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')

local inventory_scanner = {}

function inventory_scanner.scan(inv, sourceLabel, playSkillSound, booksRead, notesRead, utils)
    if not inv then return end
    for _, item in ipairs(inv:getAll(types.Book)) do
        local id = item.recordId:lower()
        if not (booksRead[id] or notesRead[id] or utils.blacklist[id]) then
            local bookName = utils.getBookName(id)
            local skill, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            -- FIX: Removed "in" from the string format to support "for sale" and "to loot"
            if isNote then
                ui.showMessage(string.format("New letter %s: %s", sourceLabel, bookName))
            elseif skill then
                ui.showMessage(string.format("New rare tome %s: %s", sourceLabel, bookName))
                if playSkillSound then ambient.playSound("skillraise") end
            else
                ui.showMessage(string.format("New tome %s: %s", sourceLabel, bookName))
            end
            return 
        end
    end
end

return inventory_scanner