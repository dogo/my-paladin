local addon = {}
assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
local settings = { combatHints = true, combatMode = "single", manaWarning = true, manaThreshold = 20 }
function addon.GetSettings() return settings end
local learned = {
    Judgement = { spellID = 1 }, ["Holy Strike"] = { spellID = 2 },
    Exorcism = { spellID = 3 }, Consecration = { spellID = 4 }, ["Hammer of Wrath"] = { spellID = 5 },
}
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name) return learned[name] and name, 0 end,
    GetSpellBookItemInfo = function(name) return learned[name] end,
}
local secret = setmetatable({}, {
    __lt = function() error("Secret compared") end,
    __le = function() error("Secret compared") end,
    __div = function() error("Secret calculated") end,
    __tostring = function() error("Secret formatted") end,
})
function issecretvalue(value) return rawequal(value, secret) end
local combat = true
function InCombatLockdown() return combat end
local flags = { true, true, false, true }
function UnitExists() return flags[1] end
function UnitCanAttack() return flags[2] end
function UnitIsDeadOrGhost() return flags[3] end
function UnitIsVisible() return flags[4] end
local health, maxHealth, mana, maxMana, creature = 100, 100, 100, 100, "Humanoid"
function UnitHealth(unit) assert(unit == "target"); return health end
function UnitHealthMax(unit) assert(unit == "target"); return maxHealth end
function UnitPower(unit, power) assert(unit == "player" and power == 0); return mana end
function UnitPowerMax(unit, power) assert(unit == "player" and power == 0); return maxMana end
function UnitCreatureType(unit) assert(unit == "target"); return creature end
local info, name, help, uncertain = addon.GetCombatHint()
assert(info == learned.Judgement and name == "Judgement" and not uncertain)
health = 19
info, name = addon.GetCombatHint()
assert(info == learned["Hammer of Wrath"] and name == "Hammer of Wrath")
health = 20
assert(addon.GetCombatHint() == learned.Judgement, "Execute requires strictly below 20%")
for _, invalid in ipairs({ secret, -1, 101, 0/0, "19" }) do
    health = invalid
    info, name, help, uncertain = addon.GetCombatHint()
    assert(info == learned.Judgement and uncertain, "Never infer execute from secret or invalid health")
end
health, maxHealth = 19, secret
info, name, help, uncertain = addon.GetCombatHint()
assert(info == learned.Judgement and uncertain)
health, maxHealth = 0, 100
assert(addon.GetCombatHint() == nil, "Clear hints when health reaches zero before the dead flag updates")
health, creature = secret, "Undead"
info, name, help, uncertain = addon.GetCombatHint()
assert(info == learned.Exorcism and name == "Exorcism" and not uncertain, "A public creature type can establish Exorcism eligibility independently")
creature = "Demon"
assert(addon.GetCombatHint() == learned.Exorcism)
health, creature = 100, secret
info, name, help, uncertain = addon.GetCombatHint()
assert(info == learned.Judgement and uncertain)
creature, settings.combatMode = "Humanoid", "aoe"
info, name, help, uncertain = addon.GetCombatHint()
assert(info == learned.Consecration and help == "Area damage when mana permits" and not uncertain)
mana = 19
info, name, help = addon.GetCombatHint()
assert(info == learned.Consecration and help:find("Low mana"))
mana = secret
info, name, help, uncertain = addon.GetCombatHint()
assert(info == learned.Consecration and uncertain and help:find("Check mana"))
mana, maxMana = 20, 100
settings.manaThreshold = 30
info, name, help = addon.GetCombatHint()
assert(help:find("Low mana"))
settings.manaWarning = false
info, name, help = addon.GetCombatHint()
assert(not help:find("Low mana"))
settings.manaWarning, settings.combatMode = true, "single"
learned["Hammer of Wrath"], learned.Exorcism = nil, nil
UnitHealth = function() error("Do not read requirements of unlearned spells") end
UnitCreatureType = function() error("Do not read requirements of unlearned spells") end
assert(addon.GetCombatHint() == learned.Judgement)
learned.Judgement = nil
assert(addon.GetCombatHint() == learned["Holy Strike"])
for index, invalid in ipairs({ false, false, true, false }) do
    local original = flags[index]
    flags[index] = invalid
    assert(addon.GetCombatHint() == nil)
    flags[index] = secret
    info, name, help, uncertain = addon.GetCombatHint()
    assert(info == learned["Holy Strike"] and uncertain and help:find("restricted"))
    flags[index] = original
end
combat = false
assert(addon.GetCombatHint() == nil)
combat, settings.combatHints = true, false
C_SpellBook.FindSpellBookSlotForSpell = function() error("Disabled hints must not query spells") end
assert(addon.GetCombatHint() == nil)
print("OK: combat context, execute/type requirements, mana guidance and secret-data/target guards")
