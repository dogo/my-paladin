local addon = {}
assert(loadfile("MyPaladin/Profiles.lua"))("MyPaladin", addon)
addon.Initialize(nil)
local now, combat, raw, active, aura = 100, false, "restricted", nil, nil
local secret = setmetatable({}, {__tostring = function() error("Secret formatted") end,
    __index = function() error("Secret indexed") end, __le = function() error("Secret compared") end})
function issecretvalue(value) return rawequal(value, secret) end
function GetTime() return now end
function InCombatLockdown() return combat end
local known, byName = {}, {}
function addon.GetLearnedSpell(name)
    if name == "Holy Shock" then return nil end
    if not byName[name] then byName[name] = {spellID = #known + 1}; known[#known + 1] = name end
    return byName[name]
end
function addon.GetBuffStatus() return raw, nil, active, aura end
local traces = {}
function addon.Trace(...) traces[#traces + 1] = {...} end
function addon.GetCrusaderStep() return "restricted" end
function addon.GetEchoStep() return nil end
assert(loadfile("MyPaladin/CombatState.lua"))("MyPaladin", addon)
addon.RebuildCombatSpells()
addon.primarySeal = "Seal of Righteousness"
local function Cast(name) addon.RecordCombatCast(addon.GetLearnedSpell(name).spellID) end
local function Evidence(status, name, confidence)
    local actual, seal, source = addon.GetSealEvidence()
    assert(actual == status and seal == name and source == confidence, tostring(actual) .. "/" .. tostring(seal) .. "/" .. tostring(source))
end
Evidence("unknown", nil, "unknown")
Cast("Seal of Righteousness")
combat = true
Evidence("active", "Seal of Righteousness", "estimated")
now = 105
Cast("Seal of the Crusader")
Evidence("active", "Seal of the Crusader", "estimated")
addon.GetSettings().crusaderOpener = true
local _, name, _, source = addon.GetSealAction()
assert(name == "Judgement" and source == "estimated")
Cast("Judgement")
_, name, _, source = addon.GetSealAction()
assert(name == "Seal of Righteousness" and source == "estimated")
addon.CombatTargetChanged()
_, name = addon.GetSealAction()
assert(name == "Judgement", "Never reuse estimated opener progress for a different target")
addon.GetSettings().crusaderOpener = false
now = 136
Evidence("missing", nil, "estimated")
_, name, _, source = addon.GetSealAction()
assert(name == "Seal of Righteousness" and source == "estimated")
addon.RecordCombatCast(secret)
Evidence("missing", nil, "estimated")
C_Spell = {GetSpellName = function(id) assert(id == 999); return "Seal of Command" end}
addon.RecordCombatCast(999)
Evidence("active", "Seal of Command", "estimated")
raw, active, aura = "active", "Seal of Command", {expirationTime = 160}
Evidence("active", active, "observed")
raw = "restricted"
Evidence("active", active, "estimated")
raw, now = "missing", 140
Evidence("missing", nil, "observed")
raw = "restricted"
Evidence("unknown", nil, "unknown")
raw, active, aura = "active", "Seal of Command", {expirationTime = secret}
Evidence("active", active, "observed")
raw = "restricted"
Evidence("unknown", nil, "unknown")
raw = "missing"
Cast("Seal of Righteousness")
Evidence("active", "Seal of Righteousness", "estimated")
now = now + 0.3
Evidence("missing", nil, "observed")
addon.SetCombatCast(addon.GetLearnedSpell("Holy Light").spellID, true)
local busy, info, casting = addon.GetCombatCast()
assert(busy and info and casting == "Holy Light")
addon.SetCombatCast(secret, true)
assert(addon.GetCombatCast() == true)
addon.SetCombatCast(nil, false)
assert(addon.GetCombatCast() == false)
raw = "restricted"
Cast("Seal of Righteousness")
addon.ResetCombatEvidence()
Evidence("unknown", nil, "unknown")
-- A fresh Lua load must not pretend a previous session's hidden seal is known.
local reloaded = setmetatable({}, {__index = addon})
assert(loadfile("MyPaladin/CombatState.lua"))("MyPaladin", reloaded)
raw = "restricted"
assert(reloaded.GetSealEvidence() == "unknown")
-- Cooldown Manager items show seal presence when aura queries are restricted.
local spellNames = {[20375] = "Seal of Command", [20154] = "Seal of Righteousness", [7] = "Blessing of Might"}
C_Spell = {GetSpellName = function(id) return spellNames[id] end}
C_CooldownViewer = {
    GetCooldownViewerCategorySet = function(category) return category == 2 and {11, 12, 13, 14} or {} end,
    GetCooldownViewerCooldownInfo = function(id)
        if id == 11 then return {spellID = 20375, linkedSpellIDs = {}} end
        if id == 12 then return {spellID = 1, overrideSpellID = 20154, linkedSpellIDs = {}} end
        if id == 14 then return {spellID = 999, linkedSpellIDs = {20375, 20154}} end
        return {spellID = 7, linkedSpellIDs = {}}
    end,
}
local function Item(cooldownID, auraInstanceID, shown, auraSpellID)
    return {cooldownID = cooldownID, auraInstanceID = auraInstanceID, auraSpellID = auraSpellID,
        IsShown = function() return shown end}
end
local items = {}
BuffIconCooldownViewer = {IsShown = function() return true end, GetChildren = function() return unpack(items) end}
addon.RebuildCombatSpells()
raw, seal, now = "restricted", nil, 300
addon.ResetCombatEvidence()
items = {Item(13, secret, true), Item(11, nil, true), Item(12, secret, true)}
Evidence("active", "Seal of Righteousness", "observed")
items = {Item(12, secret, false), Item(11, nil, true)}
Evidence("unknown", nil, "unknown")
items = {Item(secret, secret, true)}
Evidence("unknown", nil, "unknown")
items = {Item(11, 42, true)}
Evidence("active", "Seal of Command", "observed")
-- Forever's grouped "Seals" item: a public auraSpellID names the seal, a secret one falls back to our last cast.
addon.ResetCombatEvidence()
items = {Item(14, secret, true, 20154)}
Evidence("active", "Seal of Righteousness", "observed")
addon.ResetCombatEvidence()
items = {Item(14, secret, true, secret)}
Evidence("unknown", nil, "unknown")
Cast("Seal of Command")
now = 400
Evidence("active", "Seal of Command", "estimated")
BuffIconCooldownViewer, C_CooldownViewer, items = nil, nil, {}
addon.ResetCombatEvidence()
-- A fresh seal cast counts as settling for 1.5s.
now = 190
Cast("Seal of Command")
now = 191.4
assert(addon.SealJustCast())
now = 191.6
assert(not addon.SealJustCast())
-- GCD-only cooldown memory: ready and not cast since, for at most 1.6s.
now = 200
addon.NoteSpellReady("Consecration")
now = 201
assert(addon.IsGcdOnlyCooldown("Consecration"))
Cast("Consecration")
assert(not addon.IsGcdOnlyCooldown("Consecration"), "A cast starts the real cooldown")
addon.NoteSpellReady("Consecration")
now = 202.7
assert(not addon.IsGcdOnlyCooldown("Consecration"), "Longer than any GCD means a real cooldown or a missed cast")
addon.NoteSpellReady("Judgement")
addon.ResetCombatEvidence()
assert(not addon.IsGcdOnlyCooldown("Judgement"))
print("OK: estimated seals, replacement, expiry, public reconciliation, opener target scope and cast holds")
