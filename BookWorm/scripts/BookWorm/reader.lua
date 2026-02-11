-- reader.lua
local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core')

local reader = {}

function reader.mark(obj, booksRead, notesRead, utils)
    -- Enforce Trackable Guard: Stops enchanted scrolls from being marked or messaging
    if not obj or obj.type ~= types.Book or not utils.isTrackable(obj.recordId) then return end
    
    local id = obj.recordId:lower()
    local isNote = utils.isLoreNote(id)
    local targetTable = isNote and notesRead or booksRead
    
    if targetTable[id] then 
        ui.showMessage("(Already read) " .. utils.getBookName(id))
        -- Sound is intentionally omitted here to prevent double-audio with engine 
        -- and redundant noise on re-reads.
    else
        targetTable[id] = core.getSimulationTime()
        ui.showMessage("Marked as read: " .. utils.getBookName(id))
        
        -- Sound is omitted here. 
        -- If it is a skill book, the Engine (playerskillhandlers.lua) plays 'skillraise'.
        -- If it is a lore book, the Engine plays the standard page-turn sound.
    end
end

return reader