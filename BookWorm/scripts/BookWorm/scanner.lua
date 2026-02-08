local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local types = require('openmw.types')

local scanner = {}

function scanner.getLookVector()
    local p = camera.getPitch()
    local y = camera.getYaw()
    local cosP = math.cos(p)
    return util.vector3(math.sin(y) * cosP, math.cos(y) * cosP, math.sin(-p))
end

function scanner.findBestBook(maxDist, dotThreshold)
    local camPos = camera.getPosition()
    local lookDir = scanner.getLookVector()
    local bestObj = nil
    local maxDot = -1

    for _, obj in ipairs(nearby.items) do
        if obj.type == types.Book then
            -- The scanner now sees all Book types.
            -- Filtering logic is handled by the player/utils script.
            local objDir = (obj.position - camPos):normalize()
            local dot = objDir:dot(lookDir)
            local dist = (obj.position - camPos):length()
            
            if dot > dotThreshold and dist < maxDist and dot > maxDot then
                bestObj = obj; maxDot = dot
            end
        end
    end
    return bestObj
end

return scanner