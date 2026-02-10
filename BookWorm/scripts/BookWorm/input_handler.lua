local input = require('openmw.input')
local ambient = require('openmw.ambient')
local ui_library = require('scripts.BookWorm.ui_library')
local aux_ui = require('openmw_aux.ui') -- Added for deepDestroy

local input_handler = {}

function input_handler.toggleWindow(params)
    if params.activeWindow then 
        aux_ui.deepDestroy(params.activeWindow) -- Refactored
        ambient.playSound("Book Close")
        if params.activeMode == params.mode then 
            return nil, nil 
        end 
    end

    ambient.playSound("Book Open")
    local data = (params.mode == "TOMES") and params.booksRead or params.notesRead
    local page = (params.mode == "TOMES") and params.bookPage or params.notePage
    
    local newWindow = ui_library.createWindow({
        dataMap = data, 
        currentPage = page, 
        itemsPerPage = params.itemsPerPage, 
        utils = params.utils, 
        mode = params.mode,
        masterTotals = params.masterTotals -- Relay master list totals
    })
    return newWindow, params.mode
end

function input_handler.handlePagination(key, params)
    local data = (params.activeMode == "TOMES") and params.booksRead or params.notesRead
    local count = 0; for _ in pairs(data) do count = count + 1 end
    local maxPages = math.max(1, math.ceil(count / params.itemsPerPage))
    
    local newPage = (params.activeMode == "TOMES") and params.bookPage or params.notePage

    if key.code == input.KEY.O and newPage < maxPages then
        newPage = newPage + 1
    elseif key.code == input.KEY.I and newPage > 1 then
        newPage = newPage - 1
    else
        return params.activeWindow, (params.activeMode == "TOMES" and params.bookPage or params.notePage)
    end
    
    aux_ui.deepDestroy(params.activeWindow) -- Refactored
    ambient.playSound("book page2")
    local newWin = ui_library.createWindow({
        dataMap = data, 
        currentPage = newPage, 
        itemsPerPage = params.itemsPerPage, 
        utils = params.utils, 
        mode = params.activeMode,
        masterTotals = params.masterTotals -- Relay master list totals
    })
    return newWin, newPage
end

return input_handler