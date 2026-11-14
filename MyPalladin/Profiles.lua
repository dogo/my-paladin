local _, addon = ...

addon.profileOrder = { "leveling", "dungeon", "raid" }
addon.profiles = {
    leveling = {
        name = "Leveling",
        focus = "Save mana between pulls. Use Consecration for groups when mana permits.",
        preparation = "Prepare: food, drinking water, a weapon buff and your chosen Blessing.",
        spells = {
            "Judgement", "Holy Strike", "Hammer of Wrath", "Exorcism",
            "Consecration", "Holy Light", "Divine Shield", "Lay on Hands",
        },
    },
    dungeon = {
        name = "Dungeon",
        focus = "Use Consecration for packs when mana permits. Save control for dangerous enemies.",
        preparation = "Prepare: agree on Blessings and Aura with your group; carry Mana Potions.",
        spells = {
            "Judgement", "Holy Strike", "Hammer of Wrath", "Exorcism",
            "Consecration", "Cleanse", "Hammer of Justice", "Blessing of Protection",
        },
    },
    raid = {
        name = "Raid",
        focus = "Use the same damage core. Coordinate Blessings, Auras and support with your raid.",
        preparation = "Prepare: assigned Blessing/Aura, food, weapon buff, elixirs and Mana Potions.",
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
