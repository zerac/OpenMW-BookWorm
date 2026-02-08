local types = require('openmw.types')
local util = require('openmw.util')

local utils = {}

-- CATEGORY COLORS
utils.inkColor = util.color.rgb(0.15, 0.1, 0.05)      
utils.combatColor = util.color.rgb(0.6, 0.2, 0.1)    
utils.magicColor = util.color.rgb(0.0, 0.35, 0.65)   
utils.stealthColor = util.color.rgb(0.1, 0.5, 0.2)   
utils.blackColor = util.color.rgb(0, 0, 0)
utils.overlayTint = util.color.rgba(1, 1, 1, 0.3)

-- SKILL CATEGORY MAP
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

return utils