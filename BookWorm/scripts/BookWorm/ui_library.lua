local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local self = require('openmw.self')

local ui_library = {}

function ui_library.createLibraryWindow(params)
    local booksRead = params.booksRead
    local currentPage = params.currentPage
    local itemsPerPage = params.itemsPerPage
    local utils = params.utils
    
    local contentItems = {}
    local playerName = types.Player.record(self).name or "Scholar"
    local titleText = string.format("--- %s'S LIBRARY ---", string.upper(playerName))
    
    local sortedData = {}
    local counts = { combat = 0, magic = 0, stealth = 0, lore = 0 }
    
    for id, _ in pairs(booksRead) do 
        local _, cat = utils.getSkillInfo(id)
        counts[cat] = (counts[cat] or 0) + 1
        table.insert(sortedData, { id = id, name = utils.getBookName(id) }) 
    end
    
    table.sort(sortedData, function(a, b) return a.name < b.name end)
    local totalItems = #sortedData
    local maxPages = math.max(1, math.ceil(totalItems / itemsPerPage))
    
    -- Ensure page is within bounds
    local activePage = math.min(math.max(1, currentPage), maxPages)

    -- Header
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = titleText, textSize = 30, textColor = utils.inkColor, font = "DefaultBold" }})
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = string.format("Page %d of %d", activePage, maxPages), textSize = 14, textColor = utils.inkColor }})
    local navText = (activePage > 1 and "[I] Prev  " or "") .. "  [K] Close  " .. (activePage < maxPages and "  Next [O]" or "")
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = navText, textSize = 16, textColor = utils.inkColor, font = "DefaultBold" }})
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = " ", textSize = 10 }})

    -- List
    local startIdx = ((activePage - 1) * itemsPerPage) + 1
    local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
    for i = startIdx, endIdx do
        local book = sortedData[i]
        local skillId, category = utils.getSkillInfo(book.id)
        local displayText = "- " .. book.name
        if skillId then displayText = displayText .. " (" .. skillId:sub(1,1):upper() .. skillId:sub(2) .. ")" end
        table.insert(contentItems, { type = ui.TYPE.Text, props = { text = displayText, textSize = 18, textColor = utils.getSkillColor(category), font = "DefaultBold" }})
    end
    
    -- Footer Summary
    local summaryStr = string.format("Lore: %d    Combat: %d    Magic: %d    Stealth: %d", counts.lore, counts.combat, counts.magic, counts.stealth)
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = " ", textSize = 10 }})
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = summaryStr, textColor = utils.blackColor, font = "DefaultBold", textSize = 14 }})

    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = "Total Books: " .. totalItems, textSize = 16, textColor = utils.inkColor }})
    table.insert(contentItems, { type = ui.TYPE.Text, props = { text = "[Shift + K] Export to Log", textSize = 14, textColor = utils.inkColor, font = "DefaultBold" }})

    return ui.create({
        layer = 'Windows',
        type = ui.TYPE.Container,
        props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), size = util.vector2(750, 850) },
        content = ui.content({
            { type = ui.TYPE.Image, props = { resource = ui.texture({path = 'textures/tx_menubook.dds'}), size = util.vector2(750, 850), color = utils.overlayTint } },
            { type = ui.TYPE.Flex, props = { column = true, arrange = ui.ALIGNMENT.Center, align = ui.ALIGNMENT.Center, padding = 70, size = util.vector2(750, 850) }, content = ui.content(contentItems) }
        })
    })
end

return ui_library