-- player.lua
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
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org>.
--]]
 
local input = require('openmw.input')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local aux_ui = require('openmw_aux.ui')
local ui = require('openmw.ui') 
local ambient = require('openmw.ambient') 

local utils = require('scripts.BookWorm.utils')
local ui_library = require('scripts.BookWorm.ui_library')
local scanner = require('scripts.BookWorm.scanner')
local state_manager = require('scripts.BookWorm.state_manager') 
local handler = require('scripts.BookWorm.input_handler')
local invScanner = require('scripts.BookWorm.inventory_scanner')
local reader = require('scripts.BookWorm.reader')
local ui_handler = require('scripts.BookWorm.ui_handler')
local remote = require('scripts.BookWorm.remote_manager')
local transition = require('scripts.BookWorm.transition_handler')
local scanner_ctrl = require('scripts.BookWorm.scanner_controller')

local booksRead, notesRead = {}, {}
local activeWindow, activeMode = nil, nil
local itemsPerPage, masterTotals = 20, nil
local searchString = ""
local isSearchActive = false 

-- Persistent Session States
local bookFilter, noteFilter = utils.FILTER_NONE, utils.FILTER_NONE
local bookPage, notePage = 1, 1

-- REFRESH LOGIC
local function refreshUI(isSearchUpdate, isFilterUpdate)
    local targetFilter = (activeMode == "TOMES" and bookFilter or noteFilter)
    local targetPage = (activeMode == "TOMES" and bookPage or notePage)
    
    if isSearchUpdate then
        if activeMode == "TOMES" then bookPage = 1 else notePage = 1 end
        targetPage = 1
    end

    activeWindow, activeMode = handler.toggleWindow({
        activeWindow=activeWindow, activeMode=activeMode, mode=activeMode, 
        booksRead=booksRead, notesRead=notesRead, 
        bookPage=targetPage, notePage=targetPage, 
        itemsPerPage=itemsPerPage, utils=utils, masterTotals=masterTotals, 
        activeFilter=targetFilter, searchString=searchString,
        isSearchChange = isSearchUpdate, 
        isFilterChange = isFilterUpdate,
        isSearchActive = isSearchActive
    })
end

return {
    engineHandlers = {
        onSave = function() return { booksRead = booksRead, notesRead = notesRead, saveTimestamp = core.getSimulationTime() } end,
        onLoad = function(data) 
            local loaded = state_manager.processLoad(data)
            booksRead, notesRead = loaded.books, loaded.notes
            bookFilter, noteFilter = utils.FILTER_NONE, utils.FILTER_NONE
            bookPage, notePage = 1, 1
            searchString = ""
            isSearchActive = false
            masterTotals = state_manager.buildMasterList(utils) 
        end,
        onUpdate = function(dt) 
            if transition.check({ activeWindow = activeWindow, remote = remote, self = self }) then 
                activeWindow, activeMode = nil, nil 
                return 
            end
            scanner_ctrl.update(dt, { scanner = scanner, utils = utils, booksRead = booksRead, notesRead = notesRead })
        end,
        onKeyPress = function(key)
            -- 1. SEARCH FOCUS MODE (Input Capture)
            if activeWindow and isSearchActive then
                -- FIXED: Use input.KEY.Enter instead of Return
                if key.code == input.KEY.Enter then
                    isSearchActive = false
                    refreshUI(false, true)
                    ambient.playSound("book page2")
                elseif key.code == input.KEY.Backspace then
                    searchString = searchString:sub(1, -2)
                    refreshUI(true, false)
                    ambient.playSound("book page2")
                elseif key.symbol and key.symbol:match("[%a%d%-%_% ]") and #searchString < 30 then
                    searchString = searchString .. key.symbol
                    refreshUI(true, false)
                    ambient.playSound("book page2")
                end
                -- Block all other keys (like J, Escape, etc.) while searching
                return
            end

            -- 2. NAVIGATION MODE
            if key.code == input.KEY.K or key.code == input.KEY.L then
                local newMode = (key.code == input.KEY.K) and "TOMES" or "LETTERS"
                if input.isShiftPressed() then
                    if newMode == "TOMES" then state_manager.exportBooks(booksRead, utils); ui.showMessage("Exported Tomes to Log")
                    else state_manager.exportLetters(notesRead, utils); ui.showMessage("Exported Letters to Log") end
                else
                    searchString = ""
                    isSearchActive = false
                    local targetFilter = (newMode == "TOMES" and bookFilter or noteFilter)
                    local targetPage = (newMode == "TOMES" and bookPage or notePage)
                    activeWindow, activeMode = handler.toggleWindow({
                        activeWindow=activeWindow, activeMode=activeMode, mode=newMode, 
                        booksRead=booksRead, notesRead=notesRead, bookPage=targetPage, notePage=targetPage, 
                        itemsPerPage=itemsPerPage, utils=utils, masterTotals=masterTotals, 
                        activeFilter=targetFilter, searchString=searchString, isSearchActive = isSearchActive
                    })
                    I.UI.setMode(activeWindow and 'Interface' or nil, {windows = {}})
                end
                return
            end

            if activeWindow then
                if key.code == input.KEY.Backspace then
                    isSearchActive = true
                    refreshUI(false, true)
                    ambient.playSound("book page2")
                elseif key.code == input.KEY.O or key.code == input.KEY.I then
                    local currentFilter = (activeMode == "TOMES" and bookFilter or noteFilter)
                    local win, page = handler.handlePagination(key, {
                        activeWindow=activeWindow, activeMode=activeMode, booksRead=booksRead, 
                        notesRead=notesRead, bookPage=bookPage, notePage=notePage, 
                        itemsPerPage=itemsPerPage, utils=utils, masterTotals=masterTotals,
                        activeFilter=currentFilter, searchString=searchString, isSearchActive = isSearchActive
                    })
                    activeWindow = win
                    if activeMode == "TOMES" then bookPage = page else notePage = page end
                end
            end
        end
    },
    eventHandlers = {
        BookWorm_ManualMark = function(obj) reader.mark(obj, booksRead, notesRead, utils) end,
        BookWorm_RemoteRead = function(data)
            if activeWindow then remote.handleAudio(true); aux_ui.deepDestroy(activeWindow); activeWindow, activeMode = nil, nil end
            remote.request(data.recordId:lower(), self, utils.isLoreNote(data.recordId:lower()))
        end,
        BookWorm_OpenRemoteUI = function(data)
            remote.set(data.recordId:lower(), data.target)
            I.UI.setMode(data.mode, { target = data.target })
        end,
        BookWorm_JumpToPage = function(data)
            if not activeWindow then return end
            if data.mode == "TOMES" then bookPage = data.page else notePage = data.page end
            local currentFilter = (data.mode == "TOMES" and bookFilter or noteFilter)
            activeWindow, activeMode = handler.toggleWindow({
                activeWindow=activeWindow, activeMode=activeMode, mode=data.mode, 
                booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage,
                itemsPerPage=itemsPerPage, utils=utils, masterTotals=masterTotals,
                isJump = true, activeFilter=currentFilter, searchString=searchString, isSearchActive = isSearchActive
            })
            ambient.playSound("book page2")
        end,
        BookWorm_ChangeFilter = function(data)
            if not activeMode or isSearchActive then return end
            if activeMode == "TOMES" then
                bookFilter = (bookFilter == data.filter) and utils.FILTER_NONE or data.filter
                bookPage = 1
            else
                noteFilter = (noteFilter == data.filter) and utils.FILTER_NONE or data.filter
                notePage = 1
            end
            refreshUI(false, true)
            ambient.playSound("book page2")
        end,
        UiModeChanged = function(data)
            local rId, rTarget = remote.get()
            local result = ui_handler.handleModeChange(data, {
                activeWindow = activeWindow, lastLookedAtObj = scanner_ctrl.getLastLookedAt(),
                booksRead = booksRead, notesRead = notesRead, currentRemoteRecordId = rId, currentRemoteTarget = rTarget,
                reader = reader, invScanner = invScanner, utils = utils, self = self
            })
            if result == "CLOSE_LIBRARY" then activeWindow, activeMode = nil, nil
            elseif result == "CLEANUP_GHOST" then remote.cleanup(self); remote.handleAudio(false) end
        end
    }
}