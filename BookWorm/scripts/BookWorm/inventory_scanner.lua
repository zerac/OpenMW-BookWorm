local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')

local inventory_scanner = {}

function inventory_scanner.scan(inv, sourceLabel, playSkillSound, booksRead, notesRead, utils)
    if not inv then return end
    for _, item in ipairs(inv:getAll(types.Book)) do
        local id = item.recordId
        if not (booksRead[id] or notesRead[id] or utils.blacklist[id:lower()]) then
            local bookName = utils.getBookName(id)
            local skill, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            if isNote then
                ui.showMessage(string.format("New letter in %s: %s", sourceLabel, bookName))
            elseif skill then
                ui.showMessage(string.format("New rare tome in %s: %s", sourceLabel, bookName))
                if playSkillSound then ambient.playSound("skillraise") end
            else
                ui.showMessage(string.format("New tome in %s: %s", sourceLabel, bookName))
            end
            return -- Found one; stop
        end
    end
end

return inventory_scanner