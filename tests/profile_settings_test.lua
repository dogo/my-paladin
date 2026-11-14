local function Load(saved)
    local addon = {}
    assert(loadfile("MyPalladin/Profiles.lua"))("MyPalladin", addon)
    addon.Initialize(saved)
    return addon
end

local legacy = { activeProfile = "dungeon", compact = false, unrelated = 42 }
local addon = Load(legacy)
assert(addon.db == legacy and legacy.unrelated == 42)
for _, id in ipairs(addon.profileOrder) do
    addon.SelectProfile(id)
    local settings = addon.GetSettings()
    assert(not settings.compact and settings.buffWarnings and settings.manaWarning and settings.showPreparation)
    assert(settings.manaThreshold == 20)
    assert(next(settings.hiddenSpells) == nil and next(settings.hiddenPreparation) == nil)
end
addon.SelectProfile("leveling")
local leveling = addon.GetSettings()
leveling.compact, leveling.manaThreshold, leveling.buffWarnings = true, 35, false
leveling.hiddenSpells.Judgement = true
leveling.hiddenPreparation.Food = true
assert(not addon.GetPreparationText():find("Food") and addon.GetPreparationText():find("Drinking water"))
for _, item in ipairs(addon.GetProfile().preparation) do leveling.hiddenPreparation[item] = true end
assert(addon.GetPreparationText() == nil, "An empty preparation list must not leave a blank heading")
addon.SelectProfile("dungeon")
assert(addon.GetSettings() ~= leveling and addon.GetSettings().manaThreshold == 20)
assert(not addon.GetSettings().hiddenSpells.Judgement)
assert(not addon.GetSettings().compact and addon.GetSettings().buffWarnings)
addon.SelectProfile("leveling")
local reloaded = Load(legacy)
assert(reloaded.GetSettings() == leveling and leveling.manaThreshold == 35)
assert(leveling.hiddenSpells.Judgement and not leveling.buffWarnings)
local other = Load(nil)
assert(other.GetSettings().compact and not other.GetSettings().hiddenSpells.Judgement)
assert(other.GetSettings().hiddenSpells ~= leveling.hiddenSpells)
for _, invalid in ipairs({ "bad", -1, 101, 0/0, math.huge, -math.huge }) do
    local recovered = Load({ profileSettings = { leveling = {
        compact = "false", manaWarning = 1, buffWarnings = {}, showPreparation = "bad",
        manaThreshold = invalid, hiddenSpells = { Judgement = "true", Exorcism = true }, hiddenPreparation = 2,
    }, dungeon = "bad" } })
    local settings = recovered.GetSettings()
    assert(settings.compact and settings.manaWarning and settings.buffWarnings and settings.showPreparation)
    assert(settings.manaThreshold == 20 and settings.hiddenSpells.Judgement == nil)
    assert(settings.hiddenSpells.Exorcism and next(settings.hiddenPreparation) == nil)
    recovered.SelectProfile("dungeon")
    assert(recovered.GetSettings().manaThreshold == 20)
end
for _, malformed in ipairs({ false, 1, "invalid" }) do
    assert(Load({ profileSettings = malformed }).GetSettings().manaThreshold == 20)
end
for _, valid in ipairs({ 0, 25, 100 }) do
    assert(Load({ profileSettings = { leveling = { manaThreshold = valid } } }).GetSettings().manaThreshold == valid)
end
print("OK: settings migration, recovery, profile/character isolation, reload and preparation filtering")
