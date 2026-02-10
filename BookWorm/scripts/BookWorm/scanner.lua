local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local async = require('openmw.async')
local self = require('openmw.self')

local scanner = {}

function scanner.findBestBook(maxDist, callback)
    local camPos = camera.getPosition()
    
    -- API verification: viewportToWorldVector is FOV and Aspect Ratio aware.
    local lookDir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    
    -- Reach: Account for camera distance so reach from character face remains constant.
    local camDist = camera.getThirdPersonDistance()
    local effectiveMax = maxDist + camDist
    local rayEnd = camPos + (lookDir * effectiveMax)

    -- FIX: We must 'ignore' the player character. 
    -- In 3rd person, the ray starts behind the player and hits their back otherwise.
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
        { ignore = self } -- CRITICAL: Ignore the player model
    )
end

return scanner