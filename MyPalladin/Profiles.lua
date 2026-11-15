local _, addon = ...

addon.profileOrder = { "leveling", "dungeon", "raid" }
addon.profiles = {
    leveling = {
        name = "Leveling",
        focus = "Save mana between pulls. Use Consecration for groups when mana permits.",
        preparation = { "Food", "Drinking water", "Weapon buff", "Chosen Blessing" },
        spells = {
            "Judgement", "Holy Strike", "Hammer of Wrath", "Exorcism",
            "Consecration", "Holy Light", "Divine Shield", "Lay on Hands",
        },
    },
    dungeon = {
        name = "Dungeon",
        focus = "Use Consecration for packs when mana permits. Save control for dangerous enemies.",
        preparation = { "Agree on Blessings", "Agree on Aura", "Mana Potions" },
        spells = {
            "Judgement", "Holy Strike", "Hammer of Wrath", "Exorcism",
            "Consecration", "Cleanse", "Hammer of Justice", "Blessing of Protection",
        },
    },
    raid = {
        name = "Raid",
        focus = "Use the same damage core. Coordinate Blessings, Auras and support with your raid.",
        preparation = { "Assigned Blessing/Aura", "Food", "Weapon buff", "Elixirs", "Mana Potions" },
        spells = {
            "Judgement", "Holy Strike", "Hammer of Wrath", "Exorcism",
            "Consecration", "Cleanse", "Blessing of Freedom", "Blessing of Protection",
        },
    },
}

function addon.Initialize(saved)
    if type(saved) ~= "table" then
        saved = {}
    end
    if type(saved.activeProfile) ~= "string" or not addon.profiles[saved.activeProfile] then
        saved.activeProfile = "leveling"
    end
    if type(saved.compact) ~= "boolean" then
        saved.compact = true
    end
    if type(saved.profileSettings) ~= "table" then saved.profileSettings = {} end
    for _, id in ipairs(addon.profileOrder) do
        local settings = saved.profileSettings[id]
        if type(settings) ~= "table" then settings = {} end
        local defaults = { compact = saved.compact, buffWarnings = true, manaWarning = true, showPreparation = true, crusaderOpener = false }
        for key, value in pairs(defaults) do
            if type(settings[key]) ~= "boolean" then settings[key] = value end
        end
        if type(settings.manaThreshold) ~= "number" or not (settings.manaThreshold >= 0 and settings.manaThreshold <= 100) then
            settings.manaThreshold = 20
        end
        for _, key in ipairs({ "hiddenSpells", "hiddenPreparation" }) do
            if type(settings[key]) ~= "table" then settings[key] = {} end
            for name, hidden in pairs(settings[key]) do
                if type(hidden) ~= "boolean" then settings[key][name] = nil end
            end
        end
        saved.profileSettings[id] = settings
    end
    addon.db = saved
    return saved
end

function addon.SelectProfile(id)
    if type(id) ~= "string" or not addon.profiles[id] then
        return false
    end
    addon.db.activeProfile = id
    return true
end

function addon.GetProfile()
    return addon.profiles[addon.db.activeProfile]
end

function addon.GetSettings()
    return addon.db.profileSettings[addon.db.activeProfile]
end

function addon.GetPreparationText()
    local items = {}
    local hidden = addon.GetSettings().hiddenPreparation
    for _, item in ipairs(addon.GetProfile().preparation) do
        if not hidden[item] then items[#items + 1] = item end
    end
    if #items > 0 then return "Prepare: " .. table.concat(items, "; ") .. "." end
end
