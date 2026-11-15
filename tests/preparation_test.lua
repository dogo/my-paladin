local addon = {}
assert(loadfile("MyPaladin/Profiles.lua"))("MyPaladin", addon)
assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
addon.Initialize(nil)
local settings = addon.GetSettings()
local blessing, aura = addon.buffGroups[2], addon.buffGroups[3]
local learned = { ["Blessing of Might"] = { spellID = 1 }, ["Retribution Aura"] = { spellID = 2 } }
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name) return learned[name] and name, 0 end,
    GetSpellBookItemInfo = function(name) return learned[name] end,
}
local combat, restricted, queries = false, false, 0
function InCombatLockdown() return combat end
function issecretvalue() return false end
local buffs = { ["Blessing of Wisdom"] = true, ["Devotion Aura"] = true }
C_Secrets = { ShouldSpellAuraBeSecret = function() return restricted end }
C_UnitAuras = { GetAuraDataBySpellName = function(unit, name, filter)
    queries = queries + 1
    assert(unit == "player" and filter == "HELPFUL" and not restricted)
    return buffs[name] and setmetatable({}, { __index = function() error("Do not inspect buff fields") end }) or nil
end }
assert(addon.GetProfileBuffStatus(blessing) == "active")
assert(addon.GetPreparationReminder() == nil, "Any accepts the current buff without choosing for the group")
settings.blessing, settings.aura = "Blessing of Might", "Retribution Aura"
local status, name = addon.GetProfileBuffStatus(blessing)
assert(status == "missing" and name == "Might", "Another blessing must not satisfy the assignment")
status, name = addon.GetProfileBuffStatus(aura)
assert(status == "missing" and name == "Retribution")
local info, spell, label = addon.GetPreparationReminder()
assert(info == learned["Blessing of Might"] and spell == "Blessing of Might" and label == "Blessing")
buffs["Blessing of Might"] = true
info, spell = addon.GetPreparationReminder()
assert(info == learned["Retribution Aura"] and spell == "Retribution Aura")
buffs["Retribution Aura"] = true
assert(addon.GetPreparationReminder() == nil)
buffs["Blessing of Might"] = nil
combat = true
local previousQueries = queries
assert(addon.GetPreparationReminder() == nil and queries == previousQueries, "No preparation interruptions during combat")
combat, restricted = false, true
assert(addon.GetProfileBuffStatus(blessing) == "restricted")
assert(addon.GetPreparationReminder() == nil and queries == previousQueries)
restricted = false
settings.blessing = "Blessing of Kings"
status, name = addon.GetProfileBuffStatus(blessing)
assert(status == "unlearned" and name == "Kings")
assert(addon.GetPreparationReminder() == nil, "Do not request an unlearned buff")
buffs["Blessing of Kings"] = true
assert(addon.GetProfileBuffStatus(blessing) == "active", "An assigned buff supplied by another player still satisfies it")
C_Secrets = nil
assert(addon.GetProfileBuffStatus(blessing) == "unavailable" and addon.GetPreparationReminder() == nil)
for _, profile in pairs(addon.profiles) do
    assert(addon.maxSpells >= #profile.spells and addon.maxPreparation >= #profile.preparation)
end
addon.SelectProfile("dungeon")
assert(addon.GetPreparationText():find("Drinking water") and addon.GetPreparationText():find("Weapon buff"))
addon.GetSettings().hiddenPreparation["Agree on Blessings"] = true
addon.Initialize(addon.db)
assert(not addon.GetPreparationText():find("Agree on Blessings"), "Existing reminder preferences must survive the expanded lists")
print("OK: assigned buffs, unlearned/shared buffs, safe preparation and expanded profile lists")
