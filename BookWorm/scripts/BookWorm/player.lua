local types = require('openmw.types')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
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
            if I.UI.getMode() ~= nil then return end
            scanTimer = scanTimer + dt
            if scanTimer < 0.25 then return end
            scanTimer = 0
            
            local best = scanner.findBestBook(350, 0.995)
            if best and best.id ~= lastTargetId then
                local id = best.recordId
                if not (booksRead[id] or notesRead[id] or utils.blacklist[id:lower()]) then
                    local bookName = utils.getBookName(id)
                    local skill, _ = utils.getSkillInfo(id)
                    local isNote = utils.isLoreNote(id)
                    
                    if isNote then
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
            elseif not best then 
                lastTargetId = nil 
            end
            lastLookedAtObj = best
        end,
        onKeyPress = function(key)
            if key.code == input.KEY.K or key.code == input.KEY.L then
                local mode = (key.code == input.KEY.K) and "TOMES" or "LETTERS"
                if input.isShiftPressed() then
                    if mode == "TOMES" then state.exportBooks(booksRead, utils) else state.exportLetters(notesRead, utils) end
                    ambient.playSound("book page2")
                else
                    if activeMode == mode then 
                        ambient.playSound("Book Close"); if activeWindow then activeWindow:destroy() end; activeWindow, activeMode = nil, nil; I.UI.setMode(nil)
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
            local isNote = utils.isLoreNote(data.recordId)
            local uiMode = isNote and "Scroll" or "Book"
            if activeWindow then activeWindow:destroy(); activeWindow, activeMode = nil, nil end
            core.sendGlobalEvent('BookWorm_RequestRemoteObject', { recordId = data.recordId, player = self, mode = uiMode })
        end,
        BookWorm_OpenRemoteUI = function(data)
            currentRemoteRecordId, currentRemoteTarget = data.recordId, data.target
            I.UI.setMode(data.mode, { target = data.target })
        end,
        UiModeChanged = function(data)
            if data.newMode == "Book" or data.newMode == "Scroll" then 
                reader.mark(data.arg or lastLookedAtObj, booksRead, notesRead, utils) 
            elseif data.newMode == nil and currentRemoteRecordId then
                core.sendGlobalEvent('BookWorm_CleanupRemote', { recordId = currentRemoteRecordId, player = self, target = currentRemoteTarget })
                currentRemoteRecordId, currentRemoteTarget = nil, nil
            end

            -- INVENTORY, CONTAINER, AND BARTER SCAN
            if data.newMode == "Interface" and activeWindow == nil then
                invScanner.scan(types.Actor.inventory(self), "inventory", false, booksRead, notesRead, utils)
            elseif (data.newMode == "Container" or data.newMode == "Barter") and data.arg then
                local obj = data.arg
                local name = obj.type.record(obj).name or (data.newMode == "Barter" and "merchant" or "container")
                
                -- Determine specific source label
                local isCorpse = (obj.type == types.NPC or obj.type == types.Creature)
                local sourceLabel = isCorpse and "the corpse" or ("the " .. name)
                if data.newMode == "Barter" then sourceLabel = "the merchant" end
                
                invScanner.scan(types.Actor.inventory(obj), sourceLabel, true, booksRead, notesRead, utils)
            end

            if activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then 
                activeWindow:destroy(); activeWindow, activeMode = nil, nil 
            end
        end
    }
}