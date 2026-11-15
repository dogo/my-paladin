local addon = {}
assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
local settings = { echoGuidance = true }
function addon.GetSettings() return settings end
local learned = {
    ["Unsealed Wrath"] = { spellID = 1 },
    ["Seal of Command"] = { spellID = 2 },
    ["Seal of Righteousness"] = { spellID = 3 },
}
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name) return learned[name] and name, 0 end,
    GetSpellBookItemInfo = function(name) return learned[name] end,
}
local combat = true
function InCombatLockdown() return combat end
local flags = { true, true, false, true }
function UnitExists() return flags[1] end
function UnitCanAttack() return flags[2] end
function UnitIsDeadOrGhost() return flags[3] end
function UnitIsVisible() return flags[4] end
local secret = setmetatable({}, {
    __index = function() error("Secret fields inspected") end,
    __lt = function() error("Secret compared") end,
    __le = function() error("Secret compared") end,
    __mod = function() error("Secret calculated") end,
    __tostring = function() error("Secret formatted") end,
})
function issecretvalue(value) return rawequal(value, secret) end
local aura, restriction, queries = nil, false, 0
C_Secrets = { ShouldSpellAuraBeSecret = function(name)
    assert(name == "Echo of Command")
    return restriction
end }
C_UnitAuras = { GetAuraDataBySpellName = function(unit, name, filter)
    queries = queries + 1
    assert(unit == "player" and name == "Echo of Command" and filter == "HELPFUL")
    assert(restriction == false, "Secret auras must not be queried")
    return aura
end }
local function Step(seal) return addon.GetEchoStep("active", seal, "Seal of Command") end
local state, count = addon.GetEchoCount()
assert(state == "known" and count == 0)
local step, info
step, info, count = Step("Seal of Command")
assert(step == "build" and info == learned["Seal of Command"] and count == 0)
for stacks = 1, 3 do
    aura = { spellId = 1311703, applications = stacks }
    step, info, count = Step("Seal of Command")
    assert(step == (stacks >= 2 and "swap" or "build") and count == stacks)
    assert(info == learned[stacks >= 2 and "Seal of Righteousness" or "Seal of Command"])
    for _ = 1, 3 do
        step, info, count = Step("Seal of Righteousness")
        assert(step == "wait" and count == stacks, "Swaps, misses and dodges must not imply the echoes were spent")
        assert(info == learned["Seal of Righteousness"])
    end
end
aura = nil
step, info, count = Step("Seal of Righteousness")
assert(step == "return" and info == learned["Seal of Command"] and count == 0)
assert(Step("Seal of Command") == "build", "Rebuild after removal, including consumption, expiry or dispel")
assert(Step("Seal of the Crusader") == nil and Step("Seal of Wisdom") == nil)
assert(addon.GetEchoStep("missing", nil, "Seal of Command") == nil)
assert(addon.GetEchoStep("active", "Seal of Righteousness", "Seal of Righteousness") == nil,
    "Keep the existing weapon/build recommendation for a Righteousness primary")
local previousQueries = queries
assert(addon.GetEchoStep("restricted", nil, "Seal of Command") == "restricted")
assert(queries == previousQueries)
restriction = true
assert(Step("Seal of Command") == "restricted" and queries == previousQueries)
restriction = secret
assert(Step("Seal of Command") == "unavailable" and queries == previousQueries)
restriction = false
for _, value in ipairs({ secret, { spellId = secret, applications = 2 }, { spellId = 1311703, applications = secret } }) do
    aura = value
    assert(Step("Seal of Command") == "restricted")
end
for _, invalid in ipairs({ 0, -1, 4, 1.5, "2", 0/0, math.huge }) do
    aura = { spellId = 1311703, applications = invalid }
    assert(Step("Seal of Command") == "unavailable")
end
for _, invalid in ipairs({ false, 42, "invalid", {}, { spellId = 1311703 }, { spellId = 1311704, applications = 2 } }) do
    aura = invalid
    assert(Step("Seal of Command") == "unavailable")
end
aura = setmetatable({}, { __index = function() error("Aura field access denied") end })
assert(Step("Seal of Command") == "unavailable")
local originalAuraAPI = C_UnitAuras
C_UnitAuras = nil
assert(Step("Seal of Command") == "unavailable")
C_UnitAuras = { GetAuraDataBySpellName = function() error("Aura access denied") end }
assert(Step("Seal of Command") == "unavailable")
C_UnitAuras = originalAuraAPI
for index, invalid in ipairs({ false, false, true, false }) do
    local original = flags[index]
    flags[index] = invalid
    assert(Step("Seal of Command") == nil)
    flags[index] = secret
    assert(Step("Seal of Command") == "restricted")
    flags[index] = original
end
combat = false
assert(Step("Seal of Command") == nil)
combat = true
learned["Holy Shock"] = { spellID = 4 }
assert(Step("Seal of Command") == nil)
learned["Holy Shock"] = nil
for _, name in ipairs({ "Unsealed Wrath", "Seal of Command", "Seal of Righteousness" }) do
    local original = learned[name]
    learned[name] = nil
    assert(Step("Seal of Command") == nil, "Require the talent and both learned seals")
    learned[name] = original
end
aura = nil
local talent = learned["Unsealed Wrath"]
learned["Unsealed Wrath"] = nil
C_SpellBook.IsSpellKnown = function(id) assert(id == 1310735); return true end
assert(Step("Seal of Command") == "build", "Known passive talents need not occupy a visible spellbook slot")
for _, invalid in ipairs({ false, secret, "true" }) do
    C_SpellBook.IsSpellKnown = function() return invalid end
    assert(Step("Seal of Command") == nil)
end
C_SpellBook.IsSpellKnown = function() error("Known-spell API unavailable") end
assert(Step("Seal of Command") == nil)
C_SpellBook.IsSpellKnown, learned["Unsealed Wrath"] = nil, talent
settings.echoGuidance = false
C_SpellBook.FindSpellBookSlotForSpell = function() error("Disabled guidance must not query the spellbook") end
assert(Step("Seal of Command") == nil)
print("OK: Command echo counts/cycle, invalid metadata, secret data and learned-build/target guards")
