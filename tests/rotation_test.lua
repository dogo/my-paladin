local addon = {}
assert(loadfile("MyPaladin/Profiles.lua"))("MyPaladin", addon)
assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
addon.Initialize(nil)
local secret = setmetatable({}, { __tostring = function() error("Secret formatted") end,
    __index = function() error("Secret indexed") end, __lt = function() error("Secret compared") end,
    __le = function() error("Secret compared") end, __add = function() error("Secret calculated") end,
    __div = function() error("Secret calculated") end })
function issecretvalue(value) return rawequal(value, secret) end
local now, combat, target = 100, true, true
function GetTime() return now end
function InCombatLockdown() return combat end
function UnitExists() return target end
function UnitCanAttack() return true end
function UnitIsDeadOrGhost() return false end
function UnitIsVisible() return true end
function UnitPower() return secret end
function UnitPowerMax() return secret end
local learned = { Judgement = {spellID = 1}, ["Holy Strike"] = {spellID = 2}, Consecration = {spellID = 3} }
C_SpellBook = { FindSpellBookSlotForSpell = function(name) return learned[name] and name end,
    GetSpellBookItemInfo = function(name) return learned[name] end }
local cds, noMana, usable, ranges = {}, false, true, true
C_Spell = {
    IsSpellUsable = function() return usable, noMana end,
    IsSpellInRange = function() return ranges end,
    GetSpellCooldown = function(id) return cds[id] or { startTime = 0, duration = 0, modRate = 1, isEnabled = true } end,
}
local function Action(name, state, text)
    local info, actual, help, uncertain, actualState = addon.GetCombatAction()
    assert(info and actual == name and actualState == state, tostring(actual) .. " / " .. tostring(actualState))
    if state == "ready" then assert(not uncertain) end
    if text then assert(help:find(text, 1, true), help) end
end
Action("Judgement", "ready")
cds[1] = { startTime = 100, duration = 8, modRate = 1, isEnabled = true }
Action("Holy Strike", "ready")
cds[2] = { startTime = 100, duration = 10, modRate = 1, isEnabled = true }
Action("Judgement", "wait", "8.0s")
now = 108
Action("Judgement", "ready")
now = 100
cds[1] = {isEnabled = true, isActive = false, startTime = secret, duration = 0, modRate = secret}
Action("Judgement", "ready")
cds[1] = setmetatable({isEnabled = true, isActive = false}, {
    __index = function() error("Inactive public flag must not read timing fields") end,
})
Action("Judgement", "ready")
cds[1] = {isEnabled = true, isActive = true, startTime = secret, duration = 8, modRate = secret}
cds[2] = nil
Action("Holy Strike", "ready")
cds[2] = {isEnabled = true, isActive = true, startTime = secret, duration = 10, modRate = secret}
Action("Judgement", "wait", "Cooldown active")
cds[2] = {isEnabled = true, isActive = true, startTime = 100, duration = 3, modRate = 1}
Action("Holy Strike", "wait", "3.0s")
cds[1] = {isEnabled = false, isActive = false}
local held = addon.GetSpellReadiness(learned.Judgement, "Judgement")
assert(held == "unusable", "Inactive must not mean ready when the cooldown is on hold")
cds[1] = {startTime = 100, duration = 8, modRate = 1, isEnabled = true}
cds[2] = {startTime = 100, duration = 10, modRate = 1, isEnabled = true}
addon.GetSettings().combatMode = "aoe"
Action("Consecration", "ready")
addon.GetSettings().combatMode = "single"
ranges = false
Action("Judgement", "check", "Move into range")
ranges, noMana, usable = true, true, false
Action("Judgement", "check", "Not enough mana")
noMana, usable = false, false
Action("Judgement", "check", "unusable")
usable = secret
Action("Judgement", "check", "protected")
usable, ranges = true, secret
Action("Judgement", "check", "protected")
ranges = true
for _, field in ipairs({"startTime", "duration", "modRate", "isEnabled"}) do
    cds[1] = { startTime = 100, duration = 8, modRate = 1, isEnabled = true }
    cds[1][field] = secret
    Action("Judgement", "check", "protected")
end
cds[1] = secret
Action("Judgement", "check", "protected")
cds[2] = nil
Action("Holy Strike", "ready")
cds[2] = {startTime = 100, duration = 10, modRate = 1, isEnabled = true}
for _, bad in ipairs({-1, 0/0, math.huge, "8"}) do
    cds[1] = {startTime = 100, duration = bad, modRate = 1, isEnabled = true}
    Action("Judgement", "check", "Invalid")
end
cds[1] = {startTime = 100, duration = 8, modRate = 2, isEnabled = true}
local state, _, remaining = addon.GetSpellReadiness(learned.Judgement, "Judgement")
assert(state == "cooldown" and remaining == 4)
-- During the GCD, the spell that was ready stays as the next action instead of Judgement on its real cooldown.
local gcdOnly = {}
addon.NoteSpellReady = function(name) gcdOnly[name] = true end
addon.IsGcdOnlyCooldown = function(name) return gcdOnly[name] == true end
addon.GetSettings().combatMode = "aoe"
cds[1] = {isEnabled = true, isActive = true, startTime = secret, duration = secret, modRate = secret}
cds[3] = nil
Action("Consecration", "ready")
cds[3] = {isEnabled = true, isActive = true, startTime = secret, duration = secret, modRate = secret}
cds[2] = {isEnabled = true, isActive = true, startTime = secret, duration = secret, modRate = secret}
Action("Consecration", "wait", "global cooldown")
gcdOnly = {}
Action("Judgement", "wait")
-- A public isOnGCD overrides the memory both ways.
cds[3] = {isEnabled = true, isActive = true, isOnGCD = false, startTime = secret, duration = secret, modRate = secret}
gcdOnly = {Consecration = true}
Action("Judgement", "wait")
cds[3].isOnGCD, gcdOnly = true, {}
Action("Consecration", "wait", "global cooldown")
cds[3].isOnGCD = secret
Action("Judgement", "wait")
addon.GetSettings().combatMode = "single"
addon.NoteSpellReady, addon.IsGcdOnlyCooldown = nil, nil
cds[1], cds[2], cds[3] = nil, nil, nil
learned["Seal of Righteousness"] = {spellID = 4}
addon.GetSealAction = function()
    return learned["Seal of Righteousness"], "Seal of Righteousness", "Estimated seal expired; refresh it", "estimated", true
end
usable, noMana = true, false
cds[4] = {isEnabled = true, isActive = true, startTime = secret, duration = secret, modRate = secret}
Action("Seal of Righteousness", "estimated", "refresh it") -- GCD must not flip seal upkeep to a grey check
cds[4] = nil
Action("Seal of Righteousness", "estimated", "refresh it")
addon.GetSealAction = function()
    return learned["Seal of Righteousness"], "Seal of Righteousness", "No active seal detected", "observed", true
end
cds[4] = {isEnabled = true, isActive = true, isOnGCD = true, startTime = secret, duration = secret, modRate = secret}
Action("Seal of Righteousness", "ready", "No active seal") -- steady Now through the GCD, no Now/Wait flicker
cds[4] = nil
addon.GetSealAction = nil
-- Right after a seal cast the server has not applied it yet: Judgement waits instead of a grey check.
local usableBeforeSeal = C_Spell.IsSpellUsable
C_Spell.IsSpellUsable = function(id) if id == 1 then return false, false end return usableBeforeSeal(id) end
cds[2] = {isEnabled = true, isActive = true, startTime = secret, duration = secret, modRate = secret}
addon.SealJustCast = function() return true end
Action("Judgement", "wait", "Seal applying")
addon.SealJustCast = function() return false end
Action("Judgement", "check", "unusable")
addon.SealJustCast, C_Spell.IsSpellUsable, cds[2] = nil, usableBeforeSeal, nil
C_Spell.GetSpellCooldown = function() error(secret) end
Action("Judgement", "check", "C_Spell.GetSpellCooldown")
C_Spell.GetSpellCooldown = nil
Action("Judgement", "check", "unavailable")
target = false
assert(addon.GetCombatAction() == nil)
target, combat = true, false
assert(addon.GetCombatAction() == nil)
combat, addon.GetSettings().combatHints = true, false
C_SpellBook.FindSpellBookSlotForSpell = function() error("Disabled assistant queried spells") end
assert(addon.GetCombatAction() == nil)
print("OK: dynamic Forever priority, cooldown expiry, resources/range and secret-data safety")
