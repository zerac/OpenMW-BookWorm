local world = require('openmw.world')
local types = require('openmw.types')

-- Snapshot storage: [player.id] = { [recordId] = originalCount }
local playerSnapshots = {}

return {
    eventHandlers = {
        onObjectUse = function(data)
            if data.object.type == types.Book then
                data.actor:sendEvent('BookWorm_ManualMark', data.object)
            end
        end,
        
        BookWorm_RequestRemoteObject = function(data)
            local player = data.player
            local inv = types.Actor.inventory(player)
            
            -- 1. Take Snapshot of current inventory count
            local currentCount = inv:countOf(data.recordId)
            
            if not playerSnapshots[player.id] then playerSnapshots[player.id] = {} end
            playerSnapshots[player.id][data.recordId] = currentCount
            
            -- 2. Create the Ghost purely for UI display
            local tempObj = world.createObject(data.recordId)
            
            player:sendEvent('BookWorm_OpenRemoteUI', { 
                target = tempObj, 
                mode = data.mode,
                recordId = data.recordId
            })
        end,
        
        BookWorm_CleanupRemote = function(data)
            local player = data.player
            local recordId = data.recordId
            local snapshotCount = playerSnapshots[player.id] and playerSnapshots[player.id][recordId]
            
            if snapshotCount ~= nil then
                local inv = types.Actor.inventory(player)
                local currentCount = inv:countOf(recordId)
                
                -- THE INVENTORY FIX:
                -- If count increased (Player clicked 'Take' in UI)
                if currentCount > snapshotCount then
                    -- Get all books to find the actual real items, not the ghost
                    local books = inv:getAll(types.Book)
                    for _, item in ipairs(books) do
                        -- Logic: ID matches, it's NOT the ghost, and it actually has items to remove
                        if item.recordId == recordId and item ~= data.target and item.count > 0 then
                            item:remove(1)
                            break 
                        end
                    end
                end
                
                -- THE MEMORY FIX:
                -- Destroy the ghost object passed back from player.lua
                if data.target and data.target:isValid() then
                    data.target:remove()
                end
                
                playerSnapshots[player.id][recordId] = nil
            end
        end
    }
}