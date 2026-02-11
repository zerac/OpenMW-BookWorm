-- player.lua
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
local bookPage, notePage = 1, 1
local itemsPerPage, masterTotals = 20, nil
local activeFilter = nil 

return {
    engineHandlers = {
        onSave = function() return { booksRead = booksRead, notesRead = notesRead, saveTimestamp = core.getSimulationTime() } end,
        onLoad = function(data) 
            local loaded = state_manager.processLoad(data)
            booksRead, notesRead = loaded.books, loaded.notes
            bookPage, notePage = 1, 1
            activeFilter = nil 
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
            if key.code == input.KEY.K or key.code == input.KEY.L then
                local mode = (key.code == input.KEY.K) and "TOMES" or "LETTERS"
                if input.isShiftPressed() then
                    if mode == "TOMES" then state_manager.exportBooks(booksRead, utils); ui.showMessage("Exported Tomes to Log")
                    else state_manager.exportLetters(notesRead, utils); ui.showMessage("Exported Letters to Log") end
                    ambient.playSound("book page2")
                else
                    activeWindow, activeMode = handler.toggleWindow({
                        activeWindow=activeWindow, activeMode=activeMode, mode=mode, 
                        booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, 
                        notePage=notePage, itemsPerPage=itemsPerPage, utils=utils, 
                        masterTotals=masterTotals, activeFilter=activeFilter
                    })
                    I.UI.setMode(activeWindow and 'Interface' or nil, {windows = {}})
                end
            elseif activeWindow and (key.code == input.KEY.O or key.code == input.KEY.I) then
                local win, page = handler.handlePagination(key, {
                    activeWindow=activeWindow, activeMode=activeMode, booksRead=booksRead, 
                    notesRead=notesRead, bookPage=bookPage, notePage=notePage, 
                    itemsPerPage=itemsPerPage, utils=utils, masterTotals=masterTotals,
                    activeFilter=activeFilter 
                })
                activeWindow = win
                if activeMode == "TOMES" then bookPage = page else notePage = page end
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
        BookWorm_ChangeFilter = function(data)
            if activeFilter == data.filter then activeFilter = nil else activeFilter = data.filter end
            bookPage = 1 
            activeWindow, activeMode = handler.toggleWindow({
                activeWindow=activeWindow, activeMode=activeMode, mode=activeMode or "TOMES", 
                booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, 
                notePage=notePage, itemsPerPage=itemsPerPage, utils=utils, 
                masterTotals=masterTotals, activeFilter=activeFilter,
                isFilterChange = true 
            })
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