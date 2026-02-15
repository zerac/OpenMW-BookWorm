--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    Work should have been available at https://www.gnu.org.
--]]

local ui = require('openmw.ui')
local camera = require('openmw.camera')
local ambient = require('openmw.ambient')
local input = require('openmw.input')
local I = require('openmw.interfaces')

local scanner_controller = {}

-- Persistent internal state to prevent desync during async callbacks
local internalState = {
    scanTimer = 0,
    lastTargetId = nil,
    isScanning = false,
    lastLookedAtObj = nil
}

function scanner_controller.update(dt, params)
    local uiMode = I.UI.getMode()
    local camMode = camera.getMode()

    -- Exit if UI is open, camera is static, or a scan is already in progress
    if uiMode ~= nil or camMode == camera.MODE.Vanity or camMode == camera.MODE.Static or internalState.isScanning then 
        return 
    end
    
    -- Throttling: If idle and not in preview, don't scan
    if input.isIdle() and camMode ~= camera.MODE.Preview then return end

    internalState.scanTimer = internalState.scanTimer + dt
    if internalState.scanTimer < 0.25 then return end
    
    -- LOCK: Prevent multiple concurrent raycasts
    internalState.isScanning = true
    internalState.scanTimer = 0
    
    params.scanner.findBestBook(250, function(best)
        -- UNLOCK
        internalState.isScanning = false

        if best and best.container == nil then
            if best.id ~= internalState.lastTargetId then
                local id = best.recordId:lower()
                if params.utils.isTrackable(id) and not (params.booksRead[id] or params.notesRead[id]) then
                    local bookName = params.utils.getBookName(id)
                    local skillId, _ = params.utils.getSkillInfo(id)
                    
                    if params.utils.isLoreNote(id) then
                        ui.showMessage("New letter: " .. bookName)
                        if params.cfg.playNotificationSounds then ambient.playSound("Book Open") end
                    elseif skillId then
                        -- DYNAMIC SKILL NOTIFICATION
                        local labelText = "rare tome"
                        if params.cfg.showSkillNames then
                            local skillLabel = skillId:sub(1,1):upper() .. skillId:sub(2)
                            labelText = skillLabel .. " tome"
                        end
                        ui.showMessage(string.format("New %s: %s", labelText, bookName))
                        
                        -- Play skill sound if both master sounds and skill sounds are on
                        if params.cfg.playNotificationSounds and params.cfg.playSkillNotificationSounds then 
                            ambient.playSound("skillraise") 
                        elseif params.cfg.playNotificationSounds then
                            ambient.playSound("Book Open")
                        end
                    else
                        ui.showMessage("New tome: " .. bookName)
                        if params.cfg.playNotificationSounds then ambient.playSound("Book Open") end
                    end
                end
                internalState.lastTargetId = best.id
            end
        else
            internalState.lastTargetId = nil 
        end
        internalState.lastLookedAtObj = best
    end)
end

function scanner_controller.getLastLookedAt()
    return internalState.lastLookedAtObj
end

return scanner_controller