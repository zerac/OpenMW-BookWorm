-- state_manager.lua
local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local state_manager = {}

-- Scans the game database for all trackable books to establish "100% completion" targets
-- This builds the reference counts for Combat, Magic, Stealth, and Lore.
function state_manager.buildMasterList(utils)
    local totals = { combat = 0, magic = 0, stealth = 0, lore = 0, totalTomes = 0, totalLetters = 0 }
    
    for _, record in ipairs(types.Book.records) do
        local id = record.id:lower()
        if utils.isTrackable(id) then
            if record.isScroll then
                totals.totalLetters = totals.totalLetters + 1
            else
                totals.totalTomes = totals.totalTomes + 1
                local _, cat = utils.getSkillInfo(id)
                if totals[cat] ~= nil then
                    totals[cat] = totals[cat] + 1
                end
            end
        end
    end
    return totals
end

function state_manager.processLoad(data)
    local state = { books = {}, notes = {} }
    if data then
        local saveMarker = data.saveTimestamp or 0
        -- Normalize existing Books
        -- MIGRATION: Convert old IDs to lowercase
        if data.booksRead then
            for id, ts in pairs(data.booksRead) do 
                local lowerId = id:lower() -- MIGRATION: Convert old IDs to lowercase
                if ts <= saveMarker then state.books[lowerId] = ts end 
            end
        end
        -- Normalize existing Notes
        -- MIGRATION: Convert old IDs to lowercase
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