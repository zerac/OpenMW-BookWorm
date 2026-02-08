local ui = require('openmw.ui')
local types = require('openmw.types')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local utils = require('scripts.BookWorm.utils')
local ui_library = require('scripts.BookWorm.ui_library')
local scanner = require('scripts.BookWorm.scanner')
local state = require('scripts.BookWorm.state_manager')

local booksRead = {} 
local notesRead = {}
local activeWindow = nil -- Tracks if Library or LetterBox is open
local activeMode = nil   -- "BOOKS" or "LETTERS"
local lastTargetId = nil 
local lastLookedAtObj = nil 
local scanTimer = 0
local bookPage = 1 
local notePage = 1
local itemsPerPage = 20

local function markAsRead(obj)
    if not obj or obj.type ~= types.Book then return end
    local id = obj.recordId
    local isNote = utils.isLoreNote(id)
    local targetTable = isNote and notesRead or booksRead
    
    if targetTable[id] then return end -- Silent for repeats

    targetTable[id] = core.getSimulationTime()
    ui.showMessage("Marked as read: " .. utils.getBookName(id))
    
    if isNote then
        ambient.playSound("Book Open")
    else
        local skillId, _ = utils.getSkillInfo(id)
        if skillId then ambient.playSound("skillraise") else ambient.playSound("Book Open") end
    end
end

local function toggleWindow(mode)
    if activeWindow then 
        activeWindow:destroy()
        activeWindow = nil
        ambient.playSound("Book Close")
        if activeMode == mode then activeMode = nil return end 
    end

    activeMode = mode
    ambient.playSound("Book Open")
    local data = (mode == "BOOKS") and booksRead or notesRead
    local page = (mode == "BOOKS") and bookPage or notePage
    
    activeWindow = ui_library.createWindow({
        dataMap = data, 
        currentPage = page, 
        itemsPerPage = itemsPerPage, 
        utils = utils, 
        mode = mode
    })
end

local function checkShelf(dt)
    scanTimer = scanTimer + dt
    if scanTimer < 0.25 then return end
    scanTimer = 0
    
    local bestObj = scanner.findBestBook(350, 0.995)
    if bestObj then
        lastLookedAtObj = bestObj
        if bestObj.id ~= lastTargetId then
            local id = bestObj.recordId
            if not (booksRead[id] or notesRead[id]) then
                local _, category = utils.getSkillInfo(id)
                if category ~= "lore" then
                    ui.showMessage("RARE BOOK: " .. utils.getBookName(id))
                    ambient.playSound("skillraise")
                else 
                    ui.showMessage("New discovery: " .. utils.getBookName(id)) 
                end
            end
            lastTargetId = bestObj.id
        end
    else lastTargetId = nil; lastLookedAtObj = nil end
end

return {
    engineHandlers = {
        onSave = function() return { booksRead = booksRead, notesRead = notesRead, saveTimestamp = core.getSimulationTime() } end,
        onLoad = function(data) 
            local loaded = state.processLoad(data)
            booksRead = loaded.books
            notesRead = loaded.notes
        end,
        onUpdate = function(dt) if I.UI.getMode() == nil then checkShelf(dt) end end,
        onKeyPress = function(key)
            if key.code == input.KEY.K then
                if input.isShiftPressed() then
                    state.exportToLog(booksRead, notesRead, utils)
                    ambient.playSound("book page2")
                    ui.showMessage("Exported to Log")
                else toggleWindow("BOOKS") end
            elseif key.code == input.KEY.L then
                toggleWindow("LETTERS")
            end

            if activeWindow then
                local data = (activeMode == "BOOKS") and booksRead or notesRead
                local count = 0; for _ in pairs(data) do count = count + 1 end
                local maxPages = math.max(1, math.ceil(count / itemsPerPage))
                
                if key.code == input.KEY.O or key.code == input.KEY.I then
                    if key.code == input.KEY.O and (activeMode == "BOOKS" and bookPage < maxPages or activeMode == "LETTERS" and notePage < maxPages) then
                        if activeMode == "BOOKS" then bookPage = bookPage + 1 else notePage = notePage + 1 end
                    elseif key.code == input.KEY.I and (activeMode == "BOOKS" and bookPage > 1 or activeMode == "LETTERS" and notePage > 1) then
                        if activeMode == "BOOKS" then bookPage = bookPage - 1 else notePage = notePage - 1 end
                    else return end
                    
                    activeWindow:destroy()
                    local newPage = (activeMode == "BOOKS") and bookPage or notePage
                    activeWindow = ui_library.createWindow({dataMap = data, currentPage = newPage, itemsPerPage = itemsPerPage, utils = utils, mode = activeMode})
                    ambient.playSound("book page2")
                end
            end
        end
    },
    eventHandlers = {
        BookWorm_ManualMark = markAsRead,
        UiModeChanged = function(data)
            if data.newMode == "Book" then markAsRead(data.arg or lastLookedAtObj) end
            if activeWindow and data.newMode ~= nil then 
                ambient.playSound("Book Close"); activeWindow:destroy(); activeWindow = nil; activeMode = nil
            end
        end
    },
    interfaceName = "BookWorm",
    interface = { reset = function() booksRead = {}; notesRead = {}; bookPage = 1; notePage = 1 end }
}