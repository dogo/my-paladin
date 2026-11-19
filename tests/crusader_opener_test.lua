local addon = {}
assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
local settings = { crusaderOpener = true }
function addon.GetSettings() return settings end
local learned = {
    ["Seal of the Crusader"] = { spellID = 1, iconID = 11 },
    Judgement = { spellID = 2, iconID = 12 },
}
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name) return learned[name] and name, 0 end,
    GetSpellBookItemInfo = function(name) return learned[name] end,
}
local secret = setmetatable({}, { __index = function() error("Secret fields inspected") end })
function issecretvalue(value) return rawequal(value, secret) end
local flags = { true, true, false, true }
function UnitExists() return flags[1] end
function UnitCanAttack() return flags[2] end
function UnitIsDeadOrGhost() return flags[3] end
function UnitIsVisible() return flags[4] end
local debuff, restriction, queries = nil, false, 0
C_Secrets = { ShouldSpellAuraBeSecret = function(name)
    assert(name == "Judgement of the Crusader")
    return restriction
end }
C_UnitAuras = { GetAuraDataBySpellName = function(unit, name, filter)
    queries = queries + 1
    assert(unit == "target" and name == "Judgement of the Crusader" and filter == "HARMFUL|PLAYER")
    return debuff
end }
local step, info = addon.GetCrusaderStep("missing")
assert(step == "apply" and info == learned["Seal of the Crusader"])
step, info = addon.GetCrusaderStep("active", "Seal of the Crusader")
assert(step == "judge" and info == learned.Judgement)
assert(addon.GetCrusaderStep("active", "Seal of Command") == "apply")
debuff = setmetatable({}, { __index = function() error("Aura fields inspected") end })
assert(addon.GetCrusaderStep("active", "Seal of the Crusader") == "damage")
assert(addon.GetCrusaderStep("active", "Seal of Command") == nil, "Keep the damage seal once the debuff is present")
assert(addon.GetCrusaderStep("active", "Seal of Righteousness") == nil, "Do not interrupt an echo-spending seal")
assert(addon.GetCrusaderStep("missing") == nil, "A missing seal with Crusader judged uses the ordinary damage-seal reminder")
local previousQueries = queries
assert(addon.GetCrusaderStep("restricted") == "restricted")
assert(queries == previousQueries, "Unknown self buffs must not advance the opener")
restriction = true
assert(addon.GetCrusaderStep("active", "Seal of the Crusader") == "restricted")
assert(queries == previousQueries, "Do not query secret debuffs")
restriction = false
debuff = secret
assert(addon.GetCrusaderStep("active", "Seal of the Crusader") == "restricted")
C_UnitAuras.GetAuraDataBySpellName = function() error("Aura access denied") end
assert(addon.GetCrusaderStep("active", "Seal of the Crusader") == "unavailable")
local existingAPI = C_UnitAuras
C_UnitAuras = nil
assert(addon.GetCrusaderStep("missing") == "unavailable")
C_UnitAuras = existingAPI
for index, invalid in ipairs({ false, false, true, false }) do
    local original = flags[index]
    flags[index] = invalid
    assert(addon.GetCrusaderStep("missing") == nil, "No opener for absent, friendly, dead or invisible targets")
    flags[index] = secret
    assert(addon.GetCrusaderStep("missing") == "restricted", "Secret target flags must not be used as public booleans")
    flags[index] = "invalid"
    assert(addon.GetCrusaderStep("missing") == "unavailable")
    flags[index] = nil
    assert(addon.GetCrusaderStep("missing") == "unavailable")
    flags[index] = original
end
local existsAPI = UnitExists
UnitExists = nil
assert(addon.GetCrusaderStep("missing") == "unavailable")
UnitExists = function() error("Unit access denied") end
assert(addon.GetCrusaderStep("missing") == "unavailable")
UnitExists = existsAPI
learned.Judgement = nil
assert(addon.GetCrusaderStep("missing") == nil)
learned.Judgement = { spellID = 2, iconID = 12 }
learned["Holy Shock"] = { spellID = 3, iconID = 13 }
assert(addon.GetCrusaderStep("missing") ~= nil, "The guide opens the Shockadin priority with Crusader too")
learned["Holy Shock"], learned["Seal of the Crusader"] = nil, nil
assert(addon.GetCrusaderStep("missing") == nil)
settings.crusaderOpener = false
C_SpellBook.FindSpellBookSlotForSpell = function() error("Disabled opener must not query the spellbook") end
assert(addon.GetCrusaderStep("missing") == nil)
print("OK: Crusader opener steps, learned abilities, target validity and secret/unavailable data")
