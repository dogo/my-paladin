local addon = {}
assert(loadfile("MyPaladin/Profiles.lua"))("MyPaladin", addon)
assert(loadfile("MyPaladin/Diagnostics.lua"))("MyPaladin", addon)
assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
addon.Initialize(nil)
local secret = setmetatable({}, { __tostring = function() error("Secret formatted") end,
    __index = function() error("Secret inspected") end, __lt = function() error("Secret compared") end,
    __le = function() error("Secret compared") end, __div = function() error("Secret calculated") end })
function issecretvalue(value) return rawequal(value, secret) end
function GetTime() return 123 end
function time() return 123456 end
function GetBuildInfo() return "1.60.1", "70938" end
local combat = false
function InCombatLockdown() return combat end
local saved = addon.StartDiagnostics(nil)
local function Last(feature)
    for serial = saved.serial, math.max(1, saved.serial - 999), -1 do
        local record = saved.entries[(serial - 1) % 1000 + 1]
        if record:find('"feature":"' .. feature .. '"', 1, true) then return record end
    end
    error("No record for " .. feature)
end
local function State(feature, state, detail)
    local record = Last(feature)
    assert(record:find('"state":"' .. state .. '"', 1, true), record)
    if detail then assert(record:find(detail, 1, true), record) end
end
local learned = { Judgement = { spellID = 1 }, ["Hammer of Wrath"] = { spellID = 2 }, Exorcism = { spellID = 3 } }
C_SpellBook = { FindSpellBookSlotForSpell = function(name) return learned[name] and name end,
    GetSpellBookItemInfo = function(name) return learned[name] end }
function UnitExists() return true end
function UnitCanAttack() return true end
function UnitIsDeadOrGhost() return false end
function UnitIsVisible() return true end
local health, creature = 100, "Humanoid"
function UnitHealth() return health end
function UnitHealthMax() return 100 end
function UnitCreatureType() return creature end
addon.GetManaText(50, 100, addon.GetSettings())
State("api_mana", "public")
combat = true
addon.GetManaText(secret, 100, addon.GetSettings())
State("api_mana", "restricted")
assert(Last("api_mana"):find('"combat":true', 1, true))
addon.GetCombatHint()
State("api_target_health", "public")
health = secret
addon.GetCombatHint()
State("api_target_health", "restricted", "UnitHealth returned a secret")
local before = saved.serial
addon.GetCombatHint()
assert(saved.serial == before, "Repeated restrictions must not generate new records")
creature = secret
addon.GetCombatHint()
State("api_target_type", "restricted")
UnitHealth = nil
addon.GetCombatHint()
State("api_target_health", "api_missing")
UnitHealth = function() error(secret) end
addon.GetCombatHint()
State("api_target_health", "call_failed")
UnitHealth = function() return -10 end
addon.GetCombatHint()
State("api_target_health", "invalid")
learned["Hammer of Wrath"] = nil
addon.GetCombatHint()
State("api_target_health", "not_checked")
UnitExists = function() return secret end
addon.GetCombatHint()
State("api_target", "restricted", "UnitExists")
local restricted, aura, queries = true, nil, 0
C_Secrets = { ShouldSpellAuraBeSecret = function() return restricted end }
C_UnitAuras = { GetAuraDataBySpellName = function() queries = queries + 1; return aura end }
local group = { spells = { "Seal of Command" } }
assert(addon.GetBuffStatus(group) == "restricted" and queries == 0)
State("api_aura_Seal_of_Command", "restricted", "query skipped")
restricted = false
assert(addon.GetBuffStatus(group) == "missing")
State("api_aura_Seal_of_Command", "missing")
aura = { spellId = 1311703, applications = secret }
assert(addon.GetEchoCount() == "restricted")
State("api_echo_fields", "restricted", "applications is secret")
aura.applications = 2
assert(addon.GetEchoCount() == "known")
State("api_echo_fields", "public")
C_UnitAuras.GetAuraDataBySpellName = function() error(secret) end
assert(addon.GetBuffStatus(group) == "unavailable")
State("api_aura_Seal_of_Command", "call_failed")
C_UnitAuras = nil
assert(addon.GetBuffStatus(group) == "unavailable")
State("api_auras", "api_missing")
print("OK: API diagnostic reasons, combat context, secret safety and transition deduplication")
