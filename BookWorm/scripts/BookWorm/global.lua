local types = require('openmw.types')

return {
    eventHandlers = {
        onObjectUse = function(data)
            if data.object.type == types.Book then
                -- Send the object to the player; we only care about the recordId
                data.actor:sendEvent('BookWorm_ManualMark', data.object)
            end
        end
    }
}