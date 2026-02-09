local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core')

local reader = {}

function reader.mark(obj, booksRead, notesRead, utils)
    if not obj or obj.type ~= types.Book or utils.blacklist[obj.recordId:lower()] then return end
    
    local id = obj.recordId
    local isNote = utils.isLoreNote(id)
    local targetTable = isNote and notesRead or booksRead
    
    -- NEW/RESTORED: Show message if already read, otherwise mark it
    if targetTable[id] then 
        ui.showMessage("(Already read) " .. utils.getBookName(id))
    else
        targetTable[id] = core.getSimulationTime()
        ui.showMessage("Marked as read: " .. utils.getBookName(id))
        
        -- Audio feedback only for the first time reading
        if isNote then 
            ambient.playSound("Book Open") 
        else
            local skill, _ = utils.getSkillInfo(id)
            if skill then 
                ambient.playSound("skillraise") 
            else 
                ambient.playSound("Book Open") 
            end
        end
    end
end

return reader