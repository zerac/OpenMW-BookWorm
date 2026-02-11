-- input_handler.lua
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local ui_library = require('scripts.BookWorm.ui_library')
local aux_ui = require('openmw_aux.ui') 

local input_handler = {}

-- Helper to sync filter logic for pagination counting
local function matchesFilter(id, name, params)
    if not params.activeFilter then return true end
    
    if #params.activeFilter == 1 then -- Letter Filter
        local upperName = string.upper(name)
        local upperChar = string.upper(params.activeFilter)
        if upperName:sub(1,1) == upperChar then return true end
        if upperName:sub(1, 4) == "THE " and upperName:sub(5, 5) == upperChar then return true end
        if upperName:sub(1, 3) == "AN " and upperName:sub(4, 4) == upperChar then return true end
        if upperName:sub(1, 2) == "A " and upperName:sub(3, 3) == upperChar then return true end
        return false
    else -- Skill Filter
        local _, cat = params.utils.getSkillInfo(id)
        return cat == params.activeFilter
    end
end

function input_handler.toggleWindow(params)
    if params.activeWindow then 
        if params.isJump or params.isFilterChange then 
            aux_ui.deepDestroy(params.activeWindow)
        elseif params.activeMode == params.mode then 
            aux_ui.deepDestroy(params.activeWindow)
            ambient.playSound("Book Close") 
            return nil, nil 
        else
            aux_ui.deepDestroy(params.activeWindow)
            ambient.playSound("book page2") 
        end 
    else
        ambient.playSound("Book Open") 
    end

    local data = (params.mode == "TOMES") and params.booksRead or params.notesRead
    local page = (params.mode == "TOMES") and params.bookPage or params.notePage
    
    local newWindow = ui_library.createWindow({
        dataMap = data, currentPage = page, itemsPerPage = params.itemsPerPage, 
        utils = params.utils, mode = params.mode, masterTotals = params.masterTotals,
        activeFilter = params.activeFilter 
    })
    return newWindow, params.mode
end

function input_handler.handlePagination(key, params)
    local data = (params.activeMode == "TOMES") and params.booksRead or params.notesRead
    
    -- CALCULATE FILTERED MAX PAGES
    local filteredCount = 0
    for id, _ in pairs(data) do
        local name = params.utils.getBookName(id)
        if matchesFilter(id, name, params) then
            filteredCount = filteredCount + 1
        end
    end
    
    local maxPages = math.max(1, math.ceil(filteredCount / params.itemsPerPage))
    local currentPage = (params.activeMode == "TOMES") and params.bookPage or params.notePage
    local newPage = currentPage

    if key.code == input.KEY.O and currentPage < maxPages then 
        newPage = currentPage + 1
    elseif key.code == input.KEY.I and currentPage > 1 then 
        newPage = currentPage - 1
    else 
        -- No valid page turn
        return params.activeWindow, currentPage 
    end
    
    aux_ui.deepDestroy(params.activeWindow) 
    ambient.playSound("book page2") 
    
    local newWin = ui_library.createWindow({
        dataMap = data, currentPage = newPage, itemsPerPage = params.itemsPerPage, 
        utils = params.utils, mode = params.activeMode, masterTotals = params.masterTotals,
        activeFilter = params.activeFilter
    })
    return newWin, newPage
end

return input_handler