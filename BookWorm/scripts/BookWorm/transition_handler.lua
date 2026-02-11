-- transition_handler.lua
local input = require('openmw.input')
local I = require('openmw.interfaces')
local aux_ui = require('openmw_aux.ui')

local transition_handler = {}

function transition_handler.check(state)
    local uiMode = I.UI.getMode()
    local remoteId, _ = state.remote.get()

    -- Seamless Menu Transitions
    if state.activeWindow or (uiMode == "Book" or uiMode == "Scroll") and remoteId then
        if input.isActionPressed(input.ACTION.Inventory) or input.isActionPressed(input.ACTION.GameMenu) then
            local targetMode = input.isActionPressed(input.ACTION.Inventory) and "Interface" or "MainMenu"
            
            if state.activeWindow then 
                aux_ui.deepDestroy(state.activeWindow)
            end
            
            if remoteId then
                state.remote.cleanup(state.self)
            end
            
            state.remote.handleAudio() -- Manages suppressCloseSound logic
            I.UI.setMode(targetMode)
            return true -- Transition occurred
        end
    end
    return false
end

return transition_handler