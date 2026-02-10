local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local async = require('openmw.async')
local self = require('openmw.self')
local input = require('openmw.input') -- Added for Idle check

local scanner = {}

function scanner.findBestBook(maxDist, callback)
    -- OPTIMIZATION: If the player is tabbed out or completely idle, skip the raycast
    if input.isIdle() and camera.getMode() ~= camera.MODE.Preview then 
        return 
    end

    local camPos = camera.getPosition()
    local lookDir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    
    -- Reach Adaptation
    local camDist = camera.getThirdPersonDistance()
    local effectiveMax = maxDist + camDist
    local rayEnd = camPos + (lookDir * effectiveMax)

    nearby.asyncCastRenderingRay(
        async:callback(function(result)
            if result.hit and result.hitObject and result.hitObject.type == types.Book then
                callback(result.hitObject)
            else
                callback(nil)
            end
        end),
        camPos,
        rayEnd,
        { ignore = self }
    )
end

return scanner