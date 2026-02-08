local ui = require('openmw.ui')
local types = require('openmw.types')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local I = require('openmw.interfaces')

-- MODULES
local utils = require('scripts.BookWorm.utils')
local ui_library = require('scripts.BookWorm.ui_library')
local scanner = require('scripts.BookWorm.scanner')
local state = require('scripts.BookWorm.state_manager')

-- LOCAL STATE
local booksRead = {} 
local libraryWindow = nil
local lastTargetId = nil 
local lastLookedAtObj = nil 
local scanTimer = 0
local currentPage = 1 
local itemsPerPage = 20

local function markAsRead(obj)
    if not obj or obj.type ~= types.Book then return end
    local id = obj.recordId
    if booksRead[id] then 
        ui.showMessage("(Already read) " .. utils.getBookName(id))
        return 
    end
    booksRead[id] = core.getSimulationTime()
    ui.showMessage("Marked as read: " .. utils.getBookName(id))
    local skillId, _ = utils.getSkillInfo(id)
    if skillId then ambient.playSound("skillraise") else ambient.playSound("Book Open") end
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
            if not booksRead[id] then
                local _, category = utils.getSkillInfo(id)
                if category ~= "lore" then
                    ui.showMessage("RARE BOOK: " .. utils.getBookName(id))
                    ambient.playSound("skillraise")
                else ui.showMessage("New book: " .. utils.getBookName(id)) end
            end
            lastTargetId = bestObj.id
        end
    else lastTargetId = nil; lastLookedAtObj = nil end
end

return {
    engineHandlers = {
        onSave = function() return { booksRead = booksRead, saveTimestamp = core.getSimulationTime() } end,
        onLoad = function(data) 
            currentPage = 1
            booksRead = state.processLoad(data) 
        end,
        onUpdate = function(dt) if I.UI.getMode() == nil then checkShelf(dt) end end,
        onKeyPress = function(key)
            if key.code == input.KEY.K then
                if input.isShiftPressed() then
                    -- ADDED: Play page turn sound to match I/O behavior
                    ambient.playSound("book page2") 
                    state.exportToLog(booksRead, utils)
                    ui.showMessage("Exported to Log")
                elseif libraryWindow then 
                    ambient.playSound("Book Close")
                    libraryWindow:destroy(); libraryWindow = nil
                else 
                    ambient.playSound("Book Open")
                    libraryWindow = ui_library.createLibraryWindow({booksRead = booksRead, currentPage = currentPage, itemsPerPage = itemsPerPage, utils = utils}) 
                end
            end
            if libraryWindow then
                local count = 0; for _ in pairs(booksRead) do count = count + 1 end
                local maxPages = math.max(1, math.ceil(count / itemsPerPage))
                if key.code == input.KEY.O and currentPage < maxPages then
                    currentPage = currentPage + 1; libraryWindow:destroy()
                    libraryWindow = ui_library.createLibraryWindow({booksRead = booksRead, currentPage = currentPage, itemsPerPage = itemsPerPage, utils = utils})
                    ambient.playSound("book page2")
                elseif key.code == input.KEY.I and currentPage > 1 then
                    currentPage = currentPage - 1; libraryWindow:destroy()
                    libraryWindow = ui_library.createLibraryWindow({booksRead = booksRead, currentPage = currentPage, itemsPerPage = itemsPerPage, utils = utils})
                    ambient.playSound("book page2")
                end
            end
        end
    },
    eventHandlers = {
        BookWorm_ManualMark = markAsRead,
        UiModeChanged = function(data)
            if data.newMode == "Book" then markAsRead(data.arg or lastLookedAtObj) end
            if libraryWindow and data.newMode ~= nil then 
                ambient.playSound("Book Close"); libraryWindow:destroy(); libraryWindow = nil 
            end
        end
    },
    interfaceName = "BookWorm",
    interface = { reset = function() booksRead = {}; currentPage = 1 end }
}