local types = require('openmw.types')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local camera = require('openmw.camera')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local ui = require('openmw.ui')

local utils = require('scripts.BookWorm.utils')
local ui_library = require('scripts.BookWorm.ui_library')
local scanner = require('scripts.BookWorm.scanner')
local state = require('scripts.BookWorm.state_manager')
local handler = require('scripts.BookWorm.input_handler')
local invScanner = require('scripts.BookWorm.inventory_scanner')
local reader = require('scripts.BookWorm.reader')
local ui_handler = require('scripts.BookWorm.ui_handler')

local booksRead, notesRead = {}, {}
local activeWindow, activeMode = nil, nil
local lastTargetId, lastLookedAtObj = nil, nil
local scanTimer, bookPage, notePage = 0, 1, 1
local itemsPerPage = 20
local currentRemoteRecordId, currentRemoteTarget = nil, nil

return {
    engineHandlers = {
        onSave = function() return { booksRead = booksRead, notesRead = notesRead, saveTimestamp = core.getSimulationTime() } end,
        onLoad = function(data) 
            local loaded = state.processLoad(data)
            booksRead, notesRead = loaded.books, loaded.notes
            bookPage, notePage = 1, 1
        end,
        onUpdate = function(dt) 
            local uiMode = I.UI.getMode()
            local camMode = camera.getMode()

            if activeWindow or (uiMode == "Book" or uiMode == "Scroll") and currentRemoteRecordId then
                if input.isActionPressed(input.ACTION.Inventory) or input.isActionPressed(input.ACTION.GameMenu) then
                    local targetMode = input.isActionPressed(input.ACTION.Inventory) and "Interface" or "MainMenu"
                    if activeWindow then activeWindow:destroy(); activeWindow, activeMode = nil, nil end
                    if currentRemoteRecordId then
                        core.sendGlobalEvent('BookWorm_CleanupRemote', { recordId = currentRemoteRecordId, player = self, target = currentRemoteTarget })
                        currentRemoteRecordId, currentRemoteTarget = nil, nil
                    end
                    ambient.playSound("Book Close")
                    I.UI.setMode(targetMode)
                    return 
                end
            end

            if uiMode ~= nil then return end
            if camMode == camera.MODE.Vanity or camMode == camera.MODE.Static then return end

            scanTimer = scanTimer + dt
            if scanTimer < 0.25 then return end
            scanTimer = 0
            
            -- Call the async scanner
            scanner.findBestBook(250, function(best)
                if best and best.container == nil then
                    if best.id ~= lastTargetId then
                        local id = best.recordId:lower()
                        if utils.isTrackable(id) and not (booksRead[id] or notesRead[id]) then
                            local bookName = utils.getBookName(id)
                            local skill, _ = utils.getSkillInfo(id)
                            if utils.isLoreNote(id) then
                                ui.showMessage("New letter: " .. bookName)
                                ambient.playSound("Book Open")
                            elseif skill then
                                ui.showMessage("New RARE tome: " .. bookName)
                                ambient.playSound("skillraise")
                            else
                                ui.showMessage("New tome: " .. bookName)
                                ambient.playSound("Book Open")
                            end
                        end
                        lastTargetId = best.id
                    end
                else
                    lastTargetId = nil 
                end
                lastLookedAtObj = best
            end)
        end,
        onKeyPress = function(key)
            if key.code == input.KEY.K or key.code == input.KEY.L then
                local mode = (key.code == input.KEY.K) and "TOMES" or "LETTERS"
                if input.isShiftPressed() then
                    if mode == "TOMES" then state.exportBooks(booksRead, utils); ui.showMessage("Exported Tomes to Log")
                    else state.exportLetters(notesRead, utils); ui.showMessage("Exported Letters to Log") end
                    ambient.playSound("book page2")
                else
                    if activeMode == mode then ambient.playSound("Book Close"); if activeWindow then activeWindow:destroy() end; activeWindow, activeMode = nil, nil; I.UI.setMode(nil)
                    else
                        if activeWindow then activeWindow:destroy() end
                        activeWindow, activeMode = handler.toggleWindow({activeWindow=activeWindow, activeMode=activeMode, mode=mode, booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage, itemsPerPage=itemsPerPage, utils=utils})
                        I.UI.setMode('Interface', {windows = {}})
                    end
                end
            elseif activeWindow and (key.code == input.KEY.O or key.code == input.KEY.I) then
                local win, page = handler.handlePagination(key, {activeWindow=activeWindow, activeMode=activeMode, booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage, itemsPerPage=itemsPerPage, utils=utils})
                activeWindow = win
                if activeMode == "TOMES" then bookPage = page else notePage = page end
            end
        end
    },
    eventHandlers = {
        BookWorm_ManualMark = function(obj) reader.mark(obj, booksRead, notesRead, utils) end,
        BookWorm_RemoteRead = function(data)
            local id = data.recordId:lower()
            local isNote = utils.isLoreNote(id)
            local uiMode = isNote and "Scroll" or "Book"
            if activeWindow then activeWindow:destroy(); activeWindow, activeMode = nil, nil end
            core.sendGlobalEvent('BookWorm_RequestRemoteObject', { recordId = id, player = self, mode = uiMode })
        end,
        BookWorm_OpenRemoteUI = function(data)
            currentRemoteRecordId, currentRemoteTarget = data.recordId:lower(), data.target
            I.UI.setMode(data.mode, { target = data.target })
        end,
        UiModeChanged = function(data)
            local result = ui_handler.handleModeChange(data, {
                activeWindow = activeWindow, lastLookedAtObj = lastLookedAtObj, 
                booksRead = booksRead, notesRead = notesRead, 
                currentRemoteRecordId = currentRemoteRecordId, currentRemoteTarget = currentRemoteTarget,
                reader = reader, invScanner = invScanner, utils = utils, self = self
            })
            if result == "CLOSE_LIBRARY" then activeWindow, activeMode = nil, nil
            elseif result == "CLEANUP_GHOST" then currentRemoteRecordId, currentRemoteTarget = nil, nil end
        end
    }
}