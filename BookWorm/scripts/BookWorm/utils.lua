local types = require('openmw.types')
local util = require('openmw.util')

local utils = {}

-- UI COLORS
utils.inkColor = util.color.rgb(0.15, 0.1, 0.05)      
utils.combatColor = util.color.rgb(0.6, 0.2, 0.1)    
utils.magicColor = util.color.rgb(0.0, 0.35, 0.65)   
utils.stealthColor = util.color.rgb(0.1, 0.5, 0.2)   
utils.blackColor = util.color.rgb(0, 0, 0)
utils.overlayTint = util.color.rgba(1, 1, 1, 0.3)

-- FILTER DATA (Quest IDs and Generic Junk)
utils.blacklist = {
    -- Generic Paper/Scrolls
    ["sc_paper plain"] = true, 
    ["sc_paper_plain_01"] = true,
    ["sc_note_01"] = true, 
    ["sc_scroll"] = true,
    
    -- Main Quest / Mandatory Items (The "Don't Read" Items)
    ["bk_a1_1_caiuspackage"] = true, -- Package for Caius Cosades
    ["bk_a1_1_caiusorders"] = true,  -- Caius' Initial Orders
    ["char_gen_sheet"] = true,       -- Census and Excise Office Papers
    ["char_gen_papers"] = true,      -- Release Information
    ["chargen statssheet"] = true,   -- Stats papers (breaking game if taken as ghost)
    
    -- Common Duplicate Notes
    ["sc_messenger_note"] = true,
}

utils.skillCategories = {
    armorer = "combat", athletics = "combat", axe = "combat", block = "combat", 
    bluntweapon = "combat", heavyarmor = "combat", longblade = "combat", 
    mediumarmor = "combat", spear = "combat",
    alchemy = "magic", alteration = "magic", conjuration = "magic", destruction = "magic", 
    enchant = "magic", illusion = "magic", mysticism = "magic", restoration = "magic", 
    unarmored = "magic",
    acrobatics = "stealth", lightarmor = "stealth", marksman = "stealth", 
    mercantile = "stealth", security = "stealth", shortblade = "stealth", 
    sneak = "stealth", speechcraft = "stealth", handtohand = "stealth"
}

function utils.getBookName(id)
    local record = types.Book.record(id)
    return record and record.name or "Unknown Tome: " .. id
end

function utils.getSkillInfo(id)
    local record = types.Book.record(id)
    if record and record.skill then
        local skillId = record.skill:lower()
        return skillId, utils.skillCategories[skillId] or "unknown"
    end
    return nil, "lore"
end

function utils.getSkillColor(category)
    if category == "combat" then return utils.combatColor
    elseif category == "magic" then return utils.magicColor
    elseif category == "stealth" then return utils.stealthColor
    end
    return utils.blackColor
end

-- FIXED FILTER: Separates Books from Notes/Letters
function utils.isLoreNote(id)
    if utils.blacklist[id:lower()] then return false end
    local record = types.Book.record(id)
    
    return record and record.isScroll and (record.enchant == nil)
end

return utils