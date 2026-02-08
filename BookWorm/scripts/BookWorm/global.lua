local world = require('openmw.world')
local types = require('openmw.types')

-- Snapshot storage: [player.id] = { [recordId] = { count = X, ghost = obj } }
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
            local currentCount = inv:countOf(data.recordId)
            
            -- Create the temporary 'Ghost' just to open the UI
            local tempObj = world.createObject(data.recordId)
            
            if not playerSnapshots[player.id] then playerSnapshots[player.id] = {} end
            
            -- Store snapshot and the ghost reference
            playerSnapshots[player.id][data.recordId] = {
                count = currentCount,
                ghost = tempObj
            }

            player:sendEvent('BookWorm_OpenRemoteUI', { 
                target = tempObj, 
                mode = data.mode,
                recordId = data.recordId
            })
        end,
        
        BookWorm_CleanupRemote = function(data)
            local player = data.player
            local recordId = data.recordId
            local snapshot = playerSnapshots[player.id] and playerSnapshots[player.id][recordId]
            
            if snapshot then
                local inv = types.Actor.inventory(player)
                local currentCount = inv:countOf(recordId)
                
                -- THE INVENTORY FIX:
                -- If you clicked 'Take', your count is now higher. 
                -- We remove 1 item from your inventory stack to revert it.
                if currentCount > snapshot.count then
                    -- Try removeItem (Standard 0.50)
                    inv:remove(recordId, 1)
                end
                
                -- THE MEMORY FIX (The Ghost):
                -- We delete the 'virtual' object we created so it doesn't 
                -- sit in the engine's memory forever.
                if snapshot.ghost and snapshot.ghost:isValid() and snapshot.ghost.parentContainer == nil then
                    snapshot.ghost:remove()
                end
                
                playerSnapshots[player.id][recordId] = nil
            end
        end
    }
}