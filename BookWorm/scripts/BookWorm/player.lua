local ui = require('openmw.ui')
local types = require('openmw.types')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local utils = require('scripts.BookWorm.utils')
local scanner = require('scripts.BookWorm.scanner')
local state = require('scripts.BookWorm.state_manager')
local handler = require('scripts.BookWorm.input_handler')

local booksRead, notesRead = {}, {}
local activeWindow, activeMode = nil, nil
local lastTargetId, lastLookedAtObj = nil, nil
local scanTimer, bookPage, notePage = 0, 1, 1
local itemsPerPage = 20

local function markAsRead(obj)
    if not obj or obj.type ~= types.Book or utils.blacklist[obj.recordId:lower()] then return end
    local isNote = utils.isLoreNote(obj.recordId)
    local targetTable = isNote and notesRead or booksRead
    
    if targetTable[obj.recordId] then 
        ui.showMessage("(Already read) " .. utils.getBookName(obj.recordId))
        return 
    end 

    targetTable[obj.recordId] = core.getSimulationTime()
    ui.showMessage("Marked as read: " .. utils.getBookName(obj.recordId))
    if isNote then ambient.playSound("Book Open") else
        local skill, _ = utils.getSkillInfo(obj.recordId)
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
            if key.code == input.KEY.K then
                if input.isShiftPressed() then state.exportBooks(booksRead, utils); ambient.playSound("book page2"); ui.showMessage("Exported Tomes")
                else activeWindow, activeMode = handler.toggleWindow({activeWindow=activeWindow, activeMode=activeMode, mode="TOMES", booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage, itemsPerPage=itemsPerPage, utils=utils}) end
            elseif key.code == input.KEY.L then
                if input.isShiftPressed() then state.exportLetters(notesRead, utils); ambient.playSound("book page2"); ui.showMessage("Exported Letters")
                else activeWindow, activeMode = handler.toggleWindow({activeWindow=activeWindow, activeMode=activeMode, mode="LETTERS", booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage, itemsPerPage=itemsPerPage, utils=utils}) end
            elseif activeWindow and (key.code == input.KEY.O or key.code == input.KEY.I) then
                local win, page = handler.handlePagination(key, {activeWindow=activeWindow, activeMode=activeMode, booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage, itemsPerPage=itemsPerPage, utils=utils})
                activeWindow = win
                if activeMode == "TOMES" then bookPage = page else notePage = page end
            end
        end
    },
    eventHandlers = {
        BookWorm_ManualMark = markAsRead,
        UiModeChanged = function(data)
            if data.newMode == "Book" or data.newMode == "Scroll" then markAsRead(data.arg or lastLookedAtObj) end
            if activeWindow and data.newMode ~= nil then ambient.playSound("Book Close"); activeWindow:destroy(); activeWindow, activeMode = nil, nil end
        end
    },
    interfaceName = "BookWorm",
    interface = { reset = function() booksRead, notesRead = {}, {}; bookPage, notePage = 1, 1 end }
}