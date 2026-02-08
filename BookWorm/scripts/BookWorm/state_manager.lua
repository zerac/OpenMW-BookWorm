local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local state_manager = {}

function state_manager.processLoad(data)
    if data and data.booksRead then
        local filtered = {}
        local saveMarker = data.saveTimestamp or 0
        for id, ts in pairs(data.booksRead) do 
            if ts <= saveMarker then filtered[id] = ts end 
        end
        return filtered
    end
    return {}
end

function state_manager.exportToLog(booksRead, utils)
    local name = types.Player.record(self).name
    print(string.format("--- BOOKWORM SAVE EXPORT: %s ---", name))
    for id, ts in pairs(booksRead) do 
        local skillId, _ = utils.getSkillInfo(id)
        local label = skillId and (skillId:sub(1,1):upper() .. skillId:sub(2)) or "Lore"
        print(string.format("[%0.1f sec] [%s] %s (%s)", ts, label, utils.getBookName(id), id)) 
    end
end

return state_manager