local ui = require('openmw.ui')
local types = require('openmw.types')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')

local utils = require('scripts.BookWorm.utils')
local ui_library = require('scripts.BookWorm.ui_library')
local scanner = require('scripts.BookWorm.scanner')
local state = require('scripts.BookWorm.state_manager')
local handler = require('scripts.BookWorm.input_handler')

local booksRead, notesRead = {}, {}
local activeWindow, activeMode = nil, nil
local lastTargetId, lastLookedAtObj = nil, nil
local scanTimer, bookPage, notePage = 0, 1, 1
local itemsPerPage = 20
local currentRemoteRecordId = nil 
local currentRemoteTarget = nil

local function markAsRead(obj)
    if not obj or obj.type ~= types.Book or utils.blacklist[obj.recordId:lower()] then return end
    local id = obj.recordId
    local isNote = utils.isLoreNote(id)
    local targetTable = isNote and notesRead or booksRead
    if targetTable[id] then 
        ui.showMessage("(Already read) " .. utils.getBookName(id))
        return 
    end 
    targetTable[id] = core.getSimulationTime()
    ui.showMessage("Marked as read: " .. utils.getBookName(id))
    if isNote then ambient.playSound("Book Open") else
        local skill, _ = utils.getSkillInfo(id)
        if skill then ambient.playSound("skillraise") else ambient.playSound("Book Open") end
    end
end

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
                if not (booksRead[best.recordId] or notesRead[best.recordId] or utils.blacklist[best.recordId:lower()]) then
                    local _, cat = utils.getSkillInfo(best.recordId)
                    ui.showMessage((cat ~= "lore" and "RARE TOME: " or "New discovery: ") .. utils.getBookName(best.recordId))
                    if cat ~= "lore" then ambient.playSound("skillraise") end
                end
                lastTargetId = best.id
            elseif not best then lastTargetId = nil end
            lastLookedAtObj = best
        end,
        onKeyPress = function(key)
            if key.code == input.KEY.K or key.code == input.KEY.L then
                local mode = (key.code == input.KEY.K) and "TOMES" or "LETTERS"
                if input.isShiftPressed() then
                    if mode == "TOMES" then state.exportBooks(booksRead, utils) else state.exportLetters(notesRead, utils) end
                    ambient.playSound("book page2"); ui.showMessage("Exported " .. mode)
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
        BookWorm_ManualMark = markAsRead,
        BookWorm_RemoteRead = function(data)
            local isNote = utils.isLoreNote(data.recordId)
            local uiMode = isNote and "Scroll" or "Book"
            if activeWindow then activeWindow:destroy(); activeWindow, activeMode = nil, nil end
            core.sendGlobalEvent('BookWorm_RequestRemoteObject', { recordId = data.recordId, player = self, mode = uiMode })
        end,
        BookWorm_OpenRemoteUI = function(data)
            currentRemoteRecordId = data.recordId 
            currentRemoteTarget = data.target
            I.UI.setMode(data.mode, { target = data.target })
        end,
        UiModeChanged = function(data)
            if data.newMode == "Book" or data.newMode == "Scroll" then 
                markAsRead(data.arg or lastLookedAtObj) 
            elseif data.newMode == nil and currentRemoteRecordId then
                core.sendGlobalEvent('BookWorm_CleanupRemote', { 
                    recordId = currentRemoteRecordId, 
                    player = self,
                    target = currentRemoteTarget 
                })
                currentRemoteRecordId = nil
                currentRemoteTarget = nil
            end
            if activeWindow and data.newMode ~= 'Interface' and data.newMode ~= nil then 
                activeWindow:destroy(); activeWindow, activeMode = nil, nil 
            end
        end
    },
    interfaceName = "BookWorm",
    interface = { reset = function() booksRead, notesRead = {}, {}; bookPage, notePage = 1, 1 end }
}