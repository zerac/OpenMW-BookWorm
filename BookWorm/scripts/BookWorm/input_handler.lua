local input = require('openmw.input')
local ambient = require('openmw.ambient')
local ui_library = require('scripts.BookWorm.ui_library')
local aux_ui = require('openmw_aux.ui') -- Added for deepDestroy

local input_handler = {}

function input_handler.toggleWindow(params)
    if params.activeWindow then 
        aux_ui.deepDestroy(params.activeWindow) -- Refactored
        
        -- CASE: Closing the current mode (e.g., K while K is open)
        if params.activeMode == params.mode then 
            ambient.playSound("Book Close") -- Manual close sound
            return nil, nil 
        else
            -- CASE: Switching between modes (e.g., L while K is open)
            -- We play the page-flip sound to simulate turning to a different section.
            ambient.playSound("book page2") -- [UPDATED] Transition sound
        end 
    else
        -- CASE: Opening the library from a closed state
        ambient.playSound("Book Open") -- Manual open sound
    end

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
    ambient.playSound("book page2") -- Tactical page sound
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