local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local state_manager = {}

function state_manager.processLoad(data)
    local state = { books = {}, notes = {} }
    if data then
        local saveMarker = data.saveTimestamp or 0
        if data.booksRead then
            for id, ts in pairs(data.booksRead) do if ts <= saveMarker then state.books[id] = ts end end
        end
        if data.notesRead then
            for id, ts in pairs(data.notesRead) do if ts <= saveMarker then state.notes[id] = ts end end
        end
    end
    return state
end

function state_manager.exportToLog(books, notes, utils)
    print(string.format("--- BOOKWORM EXPORT: %s ---", types.Player.record(self).name))
    print(">> BOOKS:")
    for id, _ in pairs(books) do print("- " .. utils.getBookName(id)) end
    print(">> LETTERS & NOTES:")
    for id, _ in pairs(notes) do print("- " .. utils.getBookName(id)) end
end

return state_manager