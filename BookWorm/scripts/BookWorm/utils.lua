-- utils.lua
local types = require('openmw.types')
local util = require('openmw.util')

local utils = {}

-- REVERTED: Using your original hardcoded RGB values for stability
utils.inkColor = util.color.rgb(0.15, 0.1, 0.05)      
utils.combatColor = util.color.rgb(0.6, 0.2, 0.1)    
utils.magicColor = util.color.rgb(0.0, 0.35, 0.65)   
utils.stealthColor = util.color.rgb(0.1, 0.5, 0.2)   
utils.blackColor = util.color.rgb(0, 0, 0)
utils.overlayTint = util.color.rgba(1, 1, 1, 0.3)

utils.blacklist = {
    ["sc_paper plain"] = true, 
    ["sc_paper_plain_01"] = true,
    ["sc_note_01"] = true, 
    ["sc_scroll"] = true,
    ["bk_a1_1_caiuspackage"] = true,
    ["bk_a1_1_caiusorders"] = true,
    ["char_gen_sheet"] = true,
    ["char_gen_papers"] = true,
    ["chargen statssheet"] = true,
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

function utils.isTrackable(id)
    local lowerId = id:lower()
    if utils.blacklist[lowerId] then return false end
    local record = types.Book.record(lowerId)
    if not record then return false end
    if record.enchant ~= nil then return false end
    return true
end

function utils.getBookName(id)
    local record = types.Book.record(id)
    return record and record.name or "Unknown Tome: " .. id
end

function utils.getSkillInfo(id)
    if not utils.isTrackable(id) then return nil, "unknown" end
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

function utils.isLoreNote(id)
    if not utils.isTrackable(id) then return false end
    local record = types.Book.record(id)
    return record and record.isScroll
end

return utils