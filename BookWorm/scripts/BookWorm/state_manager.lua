local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local state_manager = {}

function state_manager.processLoad(data)
    local state = { books = {}, notes = {} }
    if data then
        local saveMarker = data.saveTimestamp or 0
        -- Normalize existing Books
        if data.booksRead then
            for id, ts in pairs(data.booksRead) do 
                local lowerId = id:lower() -- MIGRATION: Convert old IDs to lowercase
                if ts <= saveMarker then state.books[lowerId] = ts end 
            end
        end
        -- Normalize existing Notes
        if data.notesRead then
            for id, ts in pairs(data.notesRead) do 
                local lowerId = id:lower() -- MIGRATION: Convert old IDs to lowercase
                if ts <= saveMarker then state.notes[lowerId] = ts end 
            end
        end
    end
    return state
end

-- Export only Books
function state_manager.exportBooks(books, utils)
    print(string.format("--- BOOKWORM: BOOK EXPORT [%s] ---", types.Player.record(self).name))
    for id, ts in pairs(books) do 
        local skillId, _ = utils.getSkillInfo(id)
        local label = skillId and (skillId:sub(1,1):upper() .. skillId:sub(2)) or "Lore"
        print(string.format("[%0.1f] [%s] %s (%s)", ts, label, utils.getBookName(id), id)) 
    end
end

-- Export only Letters
function state_manager.exportLetters(notes, utils)
    print(string.format("--- BOOKWORM: LETTER EXPORT [%s] ---", types.Player.record(self).name))
    for id, ts in pairs(notes) do 
        print(string.format("[%0.1f] [Note] %s (%s)", ts, utils.getBookName(id), id)) 
    end
end

return state_manager