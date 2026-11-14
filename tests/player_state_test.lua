local addon = {}
assert(loadfile("MyPalladin/PlayerState.lua"))("MyPalladin", addon)
local secret = setmetatable({}, {
    __index = function() error("Secret inspected") end,
    __div = function() error("Secret calculated") end,
    __lt = function() error("Secret compared") end,
    __tostring = function() error("Secret formatted") end,
})
function issecretvalue(value) return rawequal(value, secret) end

local settings = { manaWarning = true, manaThreshold = 20 }
local text, low = addon.GetManaText(15, 100, settings)
assert(text == "Low mana: 15%" and low)
text, low = addon.GetManaText(20, 100, settings)
assert(text == "Mana: 20%" and not low)
text, low = addon.GetManaText(100, 100, settings)
assert(text == "Mana: 100%" and not low)
for _, input in ipairs({ {secret, 100}, {15, secret}, {secret, secret} }) do
    text, low = addon.GetManaText(input[1], input[2], settings)
    assert(text == "Mana" and not low)
end
text, low = addon.GetManaText(0, 0, settings)
assert(text == "Mana unavailable" and not low)

settings.manaThreshold = 40
text, low = addon.GetManaText(35, 100, settings)
assert(text == "Low mana: 35%" and low)
settings.manaWarning = false
text, low = addon.GetManaText(35, 100, settings)
assert(text == "Mana: 35%" and not low)
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
text, low = addon.GetManaText(15, 100, settings)
assert(text == "Mana" and not low)
function issecretvalue(value) return rawequal(value, secret) end
local combat = false
function InCombatLockdown() return combat end
local learned = { ["Seal of Righteousness"] = {spellID=101,iconID=201} }
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name) return learned[name] and name, 0 end,
    GetSpellBookItemInfo = function(name) return learned[name] end,
}
local info, sealName, reason = addon.GetRecommendedSeal()
assert(info.spellID == 101 and sealName == "Seal of Righteousness" and reason == "Command not learned")
learned["Seal of Command"] = {spellID=102,iconID=202}
local itemID, equipLoc, speedText = 501, "INVTYPE_2HWEAPON", "Speed 3.40"
function GetInventoryItemID() return itemID end
C_Item = { GetItemInfoInstant = function() return itemID,"Weapon","Mace",equipLoc end }
C_TooltipInfo = { GetInventoryItem = function() return {lines={{rightText=speedText}}} end }
info, sealName = addon.GetRecommendedSeal()
assert(sealName == "Seal of Command" and info.spellID == 102)
speedText = "Speed 2.80"
info, sealName = addon.GetRecommendedSeal()
assert(sealName == "Seal of Command")
speedText = "Speed 2.79"
info, sealName = addon.GetRecommendedSeal()
assert(sealName == "Seal of Righteousness")
equipLoc = "INVTYPE_WEAPON"
info, sealName, reason = addon.GetRecommendedSeal()
assert(sealName == "Seal of Righteousness" and reason == "One-handed weapon")
equipLoc, speedText = "INVTYPE_2HWEAPON", "Speed 3.40"
learned["Holy Shock"] = {spellID=103}
info, sealName = addon.GetRecommendedSeal()
assert(sealName == "Seal of Righteousness")
learned["Holy Shock"] = nil
speedText = secret
info, sealName, reason = addon.GetRecommendedSeal()
assert(sealName == "Seal of Righteousness" and reason:find("unavailable"))
C_TooltipInfo.GetInventoryItem = function() error("Tooltip unavailable") end
info, sealName = addon.GetRecommendedSeal()
assert(sealName == "Seal of Righteousness")
itemID = nil
info, sealName, reason = addon.GetRecommendedSeal()
assert(reason == "No weapon equipped")
learned["Seal of Righteousness"] = nil
info, sealName = addon.GetRecommendedSeal()
assert(sealName == "Seal of Command" and info.spellID == 102)
learned["Seal of Command"] = nil
assert(addon.GetRecommendedSeal() == nil)
combat = true
assert(addon.GetRecommendedSeal() == nil)
learned["Seal of Righteousness"] = {spellID=101,iconID=201}
learned["Seal of Command"] = {spellID=102,iconID=202}
GetInventoryItemID = function() error("No equipment queries in combat") end
info, sealName, reason = addon.GetRecommendedSeal()
assert(info.spellID == 101 and sealName == "Seal of Righteousness" and reason == "Weapon check after combat")
print("OK: buff states, mana safety and learned-seal recommendations for weapon/build variants")
