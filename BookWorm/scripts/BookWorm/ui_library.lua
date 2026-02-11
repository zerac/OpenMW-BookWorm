-- ui_library.lua
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
 
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces') 

local ui_library = {} 

local function nameMatchesLetter(name, char)
    local upperName = string.upper(name)
    local upperChar = string.upper(char)
    if upperName:sub(1,1) == upperChar then return true end
    if upperName:sub(1, 4) == "THE " and upperName:sub(5, 5) == upperChar then return true end
    if upperName:sub(1, 3) == "AN " and upperName:sub(4, 4) == upperChar then return true end
    if upperName:sub(1, 2) == "A " and upperName:sub(3, 3) == upperChar then return true end
    return false
end

function ui_library.createWindow(params)
    local dataMap = params.dataMap
    local currentPage = params.currentPage
    local itemsPerPage = params.itemsPerPage
    local utils = params.utils
    local mode = params.mode
    local master = params.masterTotals 
    local activeFilter = params.activeFilter
    local searchString = params.searchString or ""
    local isSearchActive = params.isSearchActive
    
    local isNone = (activeFilter == utils.FILTER_NONE)
    local contentItems = {}
    local playerName = types.Player.record(self).name or "Scholar"
    local titleText = string.format("--- %s'S %s ---", string.upper(playerName), mode)
    
    local sortedData = {}
    local counts = { combat = 0, magic = 0, stealth = 0, lore = 0 }
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local availableLetters = {}

    for id, _ in pairs(dataMap) do
        local name = utils.getBookName(id)
        local _, cat = utils.getSkillInfo(id)
        counts[cat] = (counts[cat] or 0) + 1
        for i = 1, #alphabet do
            local char = alphabet:sub(i, i)
            if not availableLetters[char] and nameMatchesLetter(name, char) then availableLetters[char] = true end
        end
    end

    local timestamps = {}
    for id, ts in pairs(dataMap) do 
        local name = utils.getBookName(id)
        local _, cat = utils.getSkillInfo(id)
        local match = true
        if not isNone then
            if #activeFilter == 1 then match = nameMatchesLetter(name, activeFilter)
            else match = (cat == activeFilter) end
        end
        if match and searchString ~= "" then
            match = string.find(name:lower(), searchString:lower(), 1, true) ~= nil
        end
        if match then
            table.insert(sortedData, { id = id, name = name, ts = ts })
            table.insert(timestamps, ts)
        end
    end
    
    table.sort(timestamps, function(a, b) return a > b end)
    local newThreshold = timestamps[math.min(5, #timestamps)] or 0
    table.sort(sortedData, function(a, b) return a.name < b.name end)
    
    local totalItems = #sortedData
    local maxPages = math.max(1, math.ceil(totalItems / itemsPerPage))
    local activePage = math.min(math.max(1, currentPage), maxPages)

    local ribbonContent = {}
    local intervalSize = util.vector2(2, 2)
    local grayColor = util.color.rgb(0.5, 0.5, 0.5)
    for i = 1, #alphabet do
        local char = alphabet:sub(i, i)
        local isActive = (activeFilter == char)
        local isAvailable = availableLetters[char]
        local charColor = isAvailable and utils.blackColor or grayColor
        local charHover = isAvailable and util.color.rgb(0.8, 0.6, 0.1) or grayColor
        table.insert(ribbonContent, {
            type = ui.TYPE.Container,
            template = isActive and I.MWUI.templates.box or nil, 
            props = { padding = 2 },
            content = ui.content({{
                type = ui.TYPE.Text,
                props = { text = char, textSize = 15, textColor = charColor, font = "DefaultBold" },
                events = {
                    mouseClick = (isAvailable and not isSearchActive) and async:callback(function() self:sendEvent('BookWorm_ChangeFilter', { filter = char }) end) or nil,
                }
            }})
        })
        if i < #alphabet then table.insert(ribbonContent, { props = { size = intervalSize } }) end
    end

    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = titleText, textSize = 26, font = "DefaultBold", textColor = utils.inkColor }})
    
    -- --- IMPROVED SEARCH LABEL ---
    local searchLabel = ""
    local searchColor = utils.inkColor
    if isSearchActive then
        searchLabel = "SEARCHING (press ENTER to end): " .. searchString .. "_"
        searchColor = util.color.rgb(0.6, 0.2, 0.1)
    elseif searchString ~= "" then
        -- Updated: Guidance for modification
        searchLabel = string.format("RESULTS: '%s' (BACKSPACE TO CANCEL OR MODIFY)", searchString:upper())
    else
        searchLabel = "PRESS BACKSPACE TO SEARCH (avoid UI keys like J)"
    end
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = searchLabel, textSize = 14, textColor = searchColor, font = "DefaultBold" }})

    table.insert(contentItems, { type = ui.TYPE.Flex, props = { horizontal = true, arrange = ui.ALIGNMENT.Center }, content = ui.content(ribbonContent) })
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = string.format("Page %d of %d", activePage, maxPages), textSize = 14, textColor = utils.inkColor }})
    
    local closeKey = (mode == "TOMES") and "K" or "L"
    local navText = (activePage > 1 and "[I] Prev  " or "") .. "  ["..closeKey.."] Close  " .. (activePage < maxPages and "  Next [O]" or "")
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = navText, textSize = 16, textColor = utils.inkColor, font = "DefaultBold" }})
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = " ", textSize = 10 }})

    local startIdx = ((activePage - 1) * itemsPerPage) + 1
    local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
    for i = startIdx, endIdx do
        local entry = sortedData[i]
        local _, category = utils.getSkillInfo(entry.id)
        local normalColor = utils.getSkillColor(category)
        local hoverColor = util.color.rgb(0.8, 0.6, 0.1)
        local isNew = (entry.ts >= newThreshold and entry.ts > 0)
        local displayText = (isNew and "(NEW) " or "") .. "- " .. entry.name
        if mode == "TOMES" then
            local skillId, _ = utils.getSkillInfo(entry.id)
            if skillId then displayText = displayText .. " (" .. skillId:sub(1,1):upper() .. skillId:sub(2) .. ")" end
        end
        local textProps = { text = displayText, textSize = 18, textColor = normalColor, font = "DefaultBold" }
        table.insert(contentItems, { 
            type = ui.TYPE.Text, 
            events = {
                mouseClick = not isSearchActive and async:callback(function() self:sendEvent('BookWorm_RemoteRead', { recordId = entry.id }) end) or nil,
                mouseMove = not isSearchActive and async:callback(function() textProps.textColor = hoverColor end) or nil,
                mouseLeave = not isSearchActive and async:callback(function() textProps.textColor = normalColor end) or nil
            },
            props = textProps
        })
    end
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = " ", textSize = 10 }})

    if mode == "TOMES" then
        local function createFilterBox(label, count, max, category)
            local isActive = (activeFilter == category)
            return {
                type = ui.TYPE.Container,
                template = isActive and I.MWUI.templates.box or nil, 
                props = { padding = 3 },
                content = ui.content({{
                    type = ui.TYPE.Text,
                    props = { text = string.format("%s: %d/%d", label, count, max), textColor = utils.getSkillColor(category), font = isActive and "DefaultBold" or "Default", textSize = 14 },
                    events = { mouseClick = not isSearchActive and async:callback(function() self:sendEvent('BookWorm_ChangeFilter', { filter = category }) end) or nil }
                }})
            }
        end
        table.insert(contentItems, {
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            content = ui.content({
                createFilterBox("Lore", counts.lore, master.lore, "lore"),
                { props = { size = util.vector2(10, 0) } },
                createFilterBox("Combat", counts.combat, master.combat, "combat"),
                { props = { size = util.vector2(10, 0) } },
                createFilterBox("Magic", counts.magic, master.magic, "magic"),
                { props = { size = util.vector2(10, 0) } },
                createFilterBox("Stealth", counts.stealth, master.stealth, "stealth")
            })
        })
        
        local isSkillFilter = (not isNone and #activeFilter > 1)
        local divisor = isSkillFilter and master[activeFilter] or master.totalTomes
        local perc = math.floor((totalItems / divisor) * 100)
        local footerLabel = isSkillFilter and (activeFilter:sub(1,1):upper() .. activeFilter:sub(2) .. " Tomes") or "Total Tomes"
        if not isNone and #activeFilter == 1 then footerLabel = "Filtered (" .. activeFilter .. ")" end
        if searchString ~= "" then footerLabel = "Found" end
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = string.format("%s: %d of %d (%d%%)", footerLabel, totalItems, divisor, perc), textSize = 16, textColor = utils.inkColor }})
    else
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = "Click on letter to filter list", textSize = 12, textColor = util.color.rgb(0.4, 0.4, 0.4), font = "Default" } })
        local perc = math.floor((totalItems / master.totalLetters) * 100)
        local footerLabel = (not isNone and #activeFilter == 1) and ("Filtered (" .. activeFilter .. ")") or "Total Letters"
        if searchString ~= "" then footerLabel = "Found" end
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = string.format("%s: %d of %d (%d%%)", footerLabel, totalItems, master.totalLetters, perc), textSize = 16, textColor = utils.inkColor }})
    end

    return ui.create({
        layer = 'Windows',
        type = ui.TYPE.Container,
        props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), size = util.vector2(750, 780) },
        content = ui.content({
            { type = ui.TYPE.Image, props = { resource = ui.texture({path = 'textures/tx_menubook.dds'}), size = util.vector2(750, 780), color = utils.overlayTint } },
            { type = ui.TYPE.Flex, props = { column = true, arrange = ui.ALIGNMENT.Center, align = ui.ALIGNMENT.Center, padding = 60, size = util.vector2(750, 780) }, content = ui.content(contentItems) }
        })
    })
end

return ui_library