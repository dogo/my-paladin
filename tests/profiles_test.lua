local function LoadProfiles()
    local addon = {}
    assert(loadfile("MyPalladin/GuideInfo.lua"))("MyPalladin", addon)
    assert(loadfile("MyPalladin/Profiles.lua"))("MyPalladin", addon)
    assert(loadfile("MyPalladin/PlayerState.lua"))("MyPalladin", addon)
    return addon
end

local addon = LoadProfiles()
for _, saved in ipairs({ false, 10, "invalid", {}, { activeProfile = "missing" }, { activeProfile = {} } }) do
    local db = addon.Initialize(saved)
    assert(db.activeProfile == "leveling", "Invalid saved data must recover to Leveling")
end
local character = { activeProfile = "raid", unrelated = 42 }
assert(addon.Initialize(character) == character)
assert(addon.GetProfile().name == "Raid" and character.unrelated == 42)
assert(character.compact == true)
addon.Initialize({ activeProfile = "raid", compact = false })
assert(addon.db.compact == false, "Saved display preferences must survive initialization")
addon.Initialize(character)
assert(not addon.SelectProfile("unknown") and character.activeProfile == "raid")
assert(not addon.SelectProfile({}) and character.activeProfile == "raid")
assert(addon.SelectProfile("dungeon") and character.activeProfile == "dungeon")
local reloaded = LoadProfiles()
reloaded.Initialize(character)
assert(reloaded.GetProfile().name == "Dungeon", "Reload must preserve the active profile")
local otherCharacter = LoadProfiles()
otherCharacter.Initialize(nil)
assert(otherCharacter.GetProfile().name == "Leveling", "Characters must have independent profiles")
assert(reloaded.GetProfile().name == "Dungeon")

local secret = setmetatable({}, {
    __index = function() error("Secret value inspected") end,
    __add = function() error("Secret value calculated") end,
    __div = function() error("Secret value calculated") end,
    __lt = function() error("Secret value compared") end,
    __tostring = function() error("Secret value formatted") end,
})
local frames, nextID, known = {}, 0, {}
local methods = {}
for name in ("SetSize SetPoint SetWidth SetHeight SetJustifyH SetJustifyV SetClampedToScreen " ..
    "SetMovable EnableMouse RegisterForDrag StartMoving StopMovingOrSizing SetUserPlaced " ..
    "SetBackdrop SetBackdropColor SetBackdropBorderColor SetAllPoints SetDesaturated " ..
    "SetStatusBarTexture SetStatusBarColor SetColorTexture SetTextColor ClearAllPoints"):gmatch("%S+") do
    methods[name] = function() end
end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:RegisterUnitEvent(event) self.events[event] = true end
function methods:SetText(value) self.text = value end
function methods:SetTexture(value) self.texture = value end
function methods:Disable() self.disabled = true end
function methods:Enable() self.disabled = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value)
    local wasShown = self.shown
    self.shown = value
    if value and not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:Clear() self.duration = nil end
function methods:SetCooldownFromDurationObject(value)
    assert(value == secret, "Native cooldown must receive the opaque duration")
    self.duration = value
end
function methods:SetMinMaxValues(minimum, maximum)
    assert(minimum == 0)
    self.maximum = maximum
end
function methods:SetValue(value) self.value = value end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, shown = true,
        scripts = {}, events = {} }, { __index = methods })
    frames[#frames + 1] = frame
    return frame
end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function UnitClass() return "Paladin", "PALADIN" end
function UnitLevel() return 25 end
function UnitPower() return secret end
function UnitPowerMax() return secret end
function issecretvalue(value) return value == secret end
function GetBuildInfo() return "1.60.1", "70938", "", 16001 end
function GetLocale() return "enUS" end
UIParent, SlashCmdList = {}, {}
C_Spell = { GetSpellCooldownDuration = function() return secret end }
local activeBuffs = { ["Seal of Command"] = true, ["Blessing of Might"] = true, ["Retribution Aura"] = true }
local restrictedBuffs = false
C_Secrets = { ShouldSpellAuraBeSecret = function() return restrictedBuffs end }
C_UnitAuras = {
    GetAuraDataBySpellName = function(unit, name, filter)
        assert(unit == "player" and filter == "HELPFUL")
        assert(not restrictedBuffs, "Secret aura data must never be queried")
        return activeBuffs[name] and setmetatable({}, { __index = function() error("Aura fields must not be inspected") end }) or nil
    end,
}
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name)
        if name == "Hammer of Wrath" then return nil end
        if not known[name] then
            nextID = nextID + 1
            known[name] = nextID
        end
        return known[name], 0
    end,
    GetSpellBookItemInfo = function(slot) return { spellID = slot, iconID = slot } end,
}
MyPalladinDB = { activeProfile = "dungeon" }
addon = LoadProfiles()
assert(loadfile("MyPalladin/MyPalladin.lua"))("MyPalladin", addon)
local events = frames[1]
local function Emit(event, unit) events.scripts.OnEvent(events, event, unit) end
Emit("ADDON_LOADED", "AnotherAddon")
assert(not SlashCmdList.MYPALLADIN)
Emit("ADDON_LOADED", "MyPalladin")
assert(MyPalladinDB.activeProfile == "dungeon")
local panel
for _, frame in ipairs(frames) do
    if frame.name == "MyPalladinPanel" then panel = frame end
end
assert(panel)
local function FindText(text)
    for _, frame in ipairs(frames) do
        if frame.text == text then return frame end
    end
end
assert(FindText("Active profile: Dungeon  |  Level 25"))
assert(FindText("Guide reviewed: " .. addon.guideInfo.reviewedOn .. " | Patch " .. addon.guideInfo.patch))
assert(not FindText("Not learned"), "Unlearned spells must be hidden")
assert(MyPalladinDB.compact == true)
assert(FindText("Expand"))
assert(not FindText(addon.profiles.dungeon.preparation):IsShown())
assert(FindText("Seal: Command"))
assert(FindText("Blessing: Might"))
assert(FindText("Aura: Retribution"))
local manaBar
for _, frame in ipairs(frames) do
    if frame.kind == "StatusBar" then manaBar = frame end
end
assert(manaBar.value == secret and manaBar.maximum == secret, "Native mana widget must receive opaque values unchanged")
UnitPower = function() return 15 end
UnitPowerMax = function() return 100 end
Emit("UNIT_POWER_UPDATE", "player")
assert(FindText("Low mana: 15%"))
assert(manaBar.value == 15 and manaBar.maximum == 100)
UnitPower = function() return secret end
UnitPowerMax = function() return secret end
Emit("UNIT_POWER_UPDATE", "player")
assert(FindText("Mana"), "A previously computed mana percentage must clear when data becomes secret")
local compactHeight = panel.height
FindText("Expand").scripts.OnClick()
assert(MyPalladinDB.compact == false and panel.height > compactHeight)
assert(FindText(addon.profiles.dungeon.preparation):IsShown())
SlashCmdList.MYPALLADIN("compact")
assert(MyPalladinDB.compact == true and panel.height == compactHeight)
assert(FindText(addon.profiles.dungeon.preparation))
local utilityCard
for _, frame in ipairs(frames) do
    if frame.spellID == known["Hammer of Justice"] then utilityCard = frame end
end
assert(utilityCard, "Dungeon must track control")
SlashCmdList.MYPALLADIN("  RAID  ")
assert(MyPalladinDB.activeProfile == "raid")
assert(FindText("Active profile: Raid  |  Level 25"))
assert(FindText("Raid").disabled and not FindText("Dungeon").disabled)
assert(utilityCard.spellID == known["Blessing of Freedom"], "Profile switch must update tracked spells")
assert(FindText(addon.profiles.raid.preparation))
SlashCmdList.MYPALLADIN("unknown")
assert(MyPalladinDB.activeProfile == "raid")
FindText("Leveling").scripts.OnClick()
assert(MyPalladinDB.activeProfile == "leveling", "Profile buttons must save the selection")
assert(utilityCard.spellID == known["Divine Shield"])
restrictedBuffs = true
Emit("PLAYER_REGEN_DISABLED")
assert(FindText("Seal: Restricted"), "Combat restrictions must clear previously visible buff status")
assert(FindText("Blessing: Restricted"))
assert(not FindText("Seal: Missing"))
restrictedBuffs = false
activeBuffs = {}
Emit("PLAYER_REGEN_ENABLED")
assert(FindText("Seal: Missing"))
assert(FindText("Blessing: Missing"))
assert(FindText("Aura: Missing"))
activeBuffs["Seal of Righteousness"] = true
Emit("UNIT_AURA", secret)
assert(FindText("Seal: Righteousness"), "UNIT_AURA updates must not inspect a potentially secret payload")
Emit("SPELL_UPDATE_COOLDOWN")
Emit("UNIT_POWER_UPDATE", "player")
SlashCmdList.MYPALLADIN("")
assert(not panel:IsShown())
SlashCmdList.MYPALLADIN("")
assert(panel:IsShown())
C_Spell.GetSpellCooldownDuration = nil
Emit("SPELL_UPDATE_COOLDOWN")
assert(FindText("Cooldown unavailable"), "Missing APIs must not imply ready abilities")
local originalSpellLookup = C_SpellBook.FindSpellBookSlotForSpell
C_SpellBook.FindSpellBookSlotForSpell = function() return nil end
Emit("SPELLS_CHANGED")
assert(FindText("Train abilities to track their cooldowns."):IsShown())
for _, frame in ipairs(frames) do
    if frame.cooldown then assert(not frame:IsShown()) end
end
C_SpellBook.FindSpellBookSlotForSpell = originalSpellLookup
Emit("SPELLS_CHANGED")
assert(not FindText("Train abilities to track their cooldowns."):IsShown())
for _, frame in ipairs(frames) do
    if frame.cooldown then
        assert((frame.spellID ~= nil) == frame:IsShown(), "Only learned spell cards may be shown")
    end
end
print("OK: saved profiles, compact layout, learned spells, buff events and opaque combat values")
