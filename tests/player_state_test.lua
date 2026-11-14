local addon = {}
assert(loadfile("MyPalladin/PlayerState.lua"))("MyPalladin", addon)
local secret = setmetatable({}, {
    __index = function() error("Secret inspected") end,
    __div = function() error("Secret calculated") end,
    __lt = function() error("Secret compared") end,
    __tostring = function() error("Secret formatted") end,
})
function issecretvalue(value) return rawequal(value, secret) end

local text, low = addon.GetManaText(15, 100)
assert(text == "Low mana: 15%" and low)
text, low = addon.GetManaText(20, 100)
assert(text == "Mana: 20%" and not low)
text, low = addon.GetManaText(100, 100)
assert(text == "Mana: 100%" and not low)
for _, input in ipairs({ {secret, 100}, {15, secret}, {secret, secret} }) do
    text, low = addon.GetManaText(input[1], input[2])
    assert(text == "Mana" and not low)
end
text, low = addon.GetManaText(0, 0)
assert(text == "Mana unavailable" and not low)

local seal = addon.buffGroups[1]
assert(addon.GetBuffStatus(seal) == "unavailable")
local queries = 0
C_Secrets = { ShouldSpellAuraBeSecret = function() return false end }
C_UnitAuras = { GetAuraDataBySpellName = function(unit, name)
    queries = queries + 1
    assert(unit == "player")
    if name == "Seal of Command" then
        return setmetatable({}, { __index = function() error("Aura data must not be read") end })
    end
end }
local status, name = addon.GetBuffStatus(seal)
assert(status == "active" and name == "Command")
C_UnitAuras.GetAuraDataBySpellName = function() queries = queries + 1 end
assert(addon.GetBuffStatus(seal) == "missing")
queries = 0
C_Secrets.ShouldSpellAuraBeSecret = function() return true end
assert(addon.GetBuffStatus(seal) == "restricted" and queries == 0)
C_Secrets.ShouldSpellAuraBeSecret = function() return secret end
assert(addon.GetBuffStatus(seal) == "unavailable" and queries == 0)
C_Secrets.ShouldSpellAuraBeSecret = function() return nil end
assert(addon.GetBuffStatus(seal) == "unavailable" and queries == 0)
C_Secrets.ShouldSpellAuraBeSecret = function() error("Unavailable API") end
assert(addon.GetBuffStatus(seal) == "unavailable" and queries == 0)
C_Secrets.ShouldSpellAuraBeSecret = function() return false end
C_UnitAuras.GetAuraDataBySpellName = function() error("Aura access denied") end
assert(addon.GetBuffStatus(seal) == "unavailable")
C_UnitAuras.GetAuraDataBySpellName = function() return secret end
assert(addon.GetBuffStatus(seal) == "restricted")
C_Secrets.ShouldSpellAuraBeSecret = function(spell) return spell ~= "Seal of Command" end
C_UnitAuras.GetAuraDataBySpellName = function() return {} end
status, name = addon.GetBuffStatus(seal)
assert(status == "active" and name == "Command", "Readable active buff outweighs unknown alternatives")
C_Secrets = nil
assert(addon.GetBuffStatus(seal) == "unavailable")
issecretvalue = nil
text, low = addon.GetManaText(15, 100)
assert(text == "Mana" and not low)
print("OK: buff presence, missing vs restricted, API failures and safe low-mana threshold")
