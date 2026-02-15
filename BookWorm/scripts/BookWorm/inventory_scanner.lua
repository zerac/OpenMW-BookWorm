--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
--]]

local ui = require('openmw.ui')
local types = require('openmw.types')
local ambient = require('openmw.ambient')

local inventory_scanner = {}

-- UPDATED: Added 'owner' to the parameters
function inventory_scanner.scan(inv, sourceLabel, booksRead, notesRead, utils, cfg, sessionState, player, owner)
    if not inv or not utils or not sessionState then return end
    
    -- Identify if the owner of the inventory is the player
    local isPlayerInv = (owner == player)

    for _, item in ipairs(inv:getAll(types.Book)) do
        local id = item.recordId:lower()
        if utils.isTrackable(id) and not (booksRead[id] or notesRead[id]) then
            local bookName = utils.getBookName(id)
            local skillId, _ = utils.getSkillInfo(id)
            local isNote = utils.isLoreNote(id)
            
            local currentMsg = ""
            if isNote then
                currentMsg = string.format("New letter %s: %s", sourceLabel, bookName)
            elseif skillId then
                local labelText = "rare tome"
                if cfg.showSkillNames then
                    local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                    labelText = skillLabel .. " tome"
                end
                currentMsg = string.format("New %s %s: %s", labelText, sourceLabel, bookName)
            else
                currentMsg = string.format("New tome %s: %s", sourceLabel, bookName)
            end

            -- THROTTLING LOGIC
            local shouldDisplay = true
            if isPlayerInv and cfg.throttleInventoryNotifications then
                if currentMsg == sessionState.InventoryDiscoveryMessage then
                    shouldDisplay = false
                else
                    sessionState.InventoryDiscoveryMessage = currentMsg
                end
            end

            if shouldDisplay then
                if cfg.displayNotificationMessage then
                    ui.showMessage(currentMsg)
                end

                if cfg.playNotificationSounds then
                    if skillId and cfg.playSkillNotificationSounds then 
                        ambient.playSound("skillraise") 
                    else
                        ambient.playSound("Book Open")
                    end
                end
            end
            return 
        end
    end
end

return inventory_scanner