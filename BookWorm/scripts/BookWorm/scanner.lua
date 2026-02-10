local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local async = require('openmw.async')

local scanner = {}

function scanner.findBestBook(maxDist, callback)
    local camPos = camera.getPosition()
    local lookDir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    local camDist = camera.getThirdPersonDistance()
    local effectiveMax = maxDist + camDist
    local rayEnd = camPos + (lookDir * effectiveMax)

    -- Use the Async version to avoid the "input events only" error
    nearby.asyncCastRenderingRay(
        async:callback(function(result)
            if result.hit and result.hitObject and result.hitObject.type == types.Book then
                callback(result.hitObject)
            else
                callback(nil)
            end
        end),
        camPos,
        rayEnd
    )
end

return scanner