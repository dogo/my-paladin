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
local combat = false
local weaponType, weaponSpeed = "INVTYPE_2HWEAPON", "Speed 3.40"
local methods = {}
for name in ("SetSize SetPoint SetWidth SetHeight SetJustifyH SetJustifyV SetClampedToScreen " ..
    "SetMovable EnableMouse RegisterForDrag StartMoving StopMovingOrSizing SetUserPlaced " ..
    "SetBackdrop SetBackdropColor SetBackdropBorderColor SetAllPoints SetDesaturated " ..
    "SetStatusBarTexture SetStatusBarColor SetColorTexture SetTextColor ClearAllPoints SetHighlightTexture SetFrameStrata"):gmatch("%S+") do
    methods[name] = function() end
end
function methods:SetEnabled(value) self.disabled = not value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:EnableMouse(value) self.mouseEnabled = value end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:SetAttribute(name, value)
    error("The seal alert must never configure a casting action")
end
function methods:RegisterForClicks(...) self.clicks = {...} end
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
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, template = template, shown = true,
        scripts = {}, events = {}, attributes = {} }, { __index = methods })
    assert(template ~= "InsecureActionButtonTemplate" and template ~= "SecureActionButtonTemplate",
        "Seal reminders must not create casting buttons")
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
function InCombatLockdown() return combat end
function GetInventoryItemID() assert(not combat, "No equipment queries in combat"); return 101 end
C_Item = { GetItemInfoInstant = function() return 101, "Weapon", "Mace", weaponType end }
C_TooltipInfo = { GetInventoryItem = function() return { lines = {{rightText = weaponSpeed}} } end }
UIParent, SlashCmdList = {}, {}
C_Spell = { GetSpellCooldownDuration = function() return secret end }
local activeBuffs = { ["Seal of Command"] = true, ["Blessing of Might"] = true, ["Retribution Aura"] = true }
local restrictedBuffs = false
local targetExists, targetHostile, targetDead, targetVisible = false, true, false, true
local targetDebuff, targetRestricted = false, false
function UnitExists(unit) assert(unit == "target"); return targetExists end
function UnitCanAttack(unit, target) assert(unit == "player" and target == "target"); return targetHostile end
function UnitIsDeadOrGhost(unit) assert(unit == "target"); return targetDead end
function UnitIsVisible(unit) assert(unit == "target"); return targetVisible end
C_Secrets = { ShouldSpellAuraBeSecret = function(name)
    if name == "Judgement of the Crusader" then return targetRestricted end
    return restrictedBuffs
end }
C_UnitAuras = {
    GetAuraDataBySpellName = function(unit, name, filter)
        if unit == "target" then
            assert(name == "Judgement of the Crusader" and filter == "HARMFUL|PLAYER")
            assert(not targetRestricted, "Secret target auras must not be queried")
            return targetDebuff and setmetatable({}, { __index = function() error("Target aura fields must not be inspected") end }) or nil
        end
        assert(unit == "player" and filter == "HELPFUL")
        assert(not restrictedBuffs, "Secret aura data must never be queried")
        return activeBuffs[name] and setmetatable({}, { __index = function() error("Aura fields must not be inspected") end }) or nil
    end,
}
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name)
        if name == "Hammer of Wrath" or name == "Holy Shock" then return nil end
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
assert(not FindText(addon.GetPreparationText()):IsShown())
assert(FindText("Seal: Command"))
assert(FindText("Blessing: Might"))
assert(FindText("Aura: Retribution"))
local sealAlert
for _, frame in ipairs(frames) do
    if frame.name == "MyPalladinSealAlert" then sealAlert = frame end
end
assert(sealAlert and sealAlert.parent == UIParent and sealAlert.kind == "Frame")
assert(not sealAlert:IsShown(), "An active seal must hide the standalone reminder")
assert(not sealAlert.scripts.OnClick, "The reminder must not cast spells")
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
assert(addon.GetSettings().compact == false and panel.height > compactHeight)
assert(FindText(addon.GetPreparationText()):IsShown())
SlashCmdList.MYPALLADIN("compact")
assert(addon.GetSettings().compact == true and panel.height == compactHeight)
assert(FindText(addon.GetPreparationText()))
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
assert(FindText(addon.GetPreparationText()))
SlashCmdList.MYPALLADIN("unknown")
assert(MyPalladinDB.activeProfile == "raid")
FindText("Leveling").scripts.OnClick()
assert(MyPalladinDB.activeProfile == "leveling", "Profile buttons must save the selection")
assert(utilityCard.spellID == known["Divine Shield"])
restrictedBuffs = true
combat = true
Emit("PLAYER_REGEN_DISABLED")
assert(FindText("Seal: Restricted"), "Combat restrictions must clear previously visible buff status")
assert(FindText("Blessing: Restricted"))
assert(not FindText("Seal: Missing"))
weaponType = "INVTYPE_WEAPON"
Emit("PLAYER_EQUIPMENT_CHANGED", 16)
assert(sealAlert.icon.texture == known["Seal of Command"], "Keep the base seal recommendation during combat")
assert(sealAlert:IsShown() and FindText("Check seal") and FindText("Status restricted"))
restrictedBuffs = false
combat = false
activeBuffs = {}
Emit("PLAYER_REGEN_ENABLED")
assert(FindText("Seal: Missing"))
assert(FindText("Blessing: Missing"))
assert(FindText("Aura: Missing"))
assert(sealAlert:IsShown() and FindText("Seal missing") and FindText("Seal of Righteousness"))
assert(sealAlert.icon.texture == known["Seal of Righteousness"], "Refresh the base seal after weapon changes outside combat")
assert(sealAlert.mouseEnabled)
sealAlert.scripts.OnDragStart(sealAlert)
assert(sealAlert.moving)
sealAlert.scripts.OnDragStop(sealAlert)
assert(not sealAlert.moving)
activeBuffs["Seal of Righteousness"] = true
Emit("UNIT_AURA", secret)
assert(FindText("Seal: Righteousness"), "UNIT_AURA updates must not inspect a potentially secret payload")
assert(not sealAlert:IsShown(), "Applying a seal must hide the independent reminder")
Emit("SPELL_UPDATE_COOLDOWN")
Emit("UNIT_POWER_UPDATE", "player")
SlashCmdList.MYPALLADIN("")
assert(not panel:IsShown())
SlashCmdList.MYPALLADIN("")
assert(panel:IsShown())
-- Aura events keep the combat reminder current with the management panel closed.
SlashCmdList.MYPALLADIN("")
assert(not panel:IsShown())
combat = true
Emit("PLAYER_REGEN_DISABLED")
assert(not sealAlert:IsShown())
assert(not sealAlert.mouseEnabled, "Combat reminders must let mouse clicks pass through")
sealAlert.scripts.OnDragStart(sealAlert)
assert(not sealAlert.moving, "The reminder must not start dragging in combat")
for _ = 1, 3 do
    activeBuffs["Seal of Righteousness"] = nil
    Emit("UNIT_AURA", secret)
    assert(not panel:IsShown() and sealAlert:IsShown() and FindText("Seal missing"))
    assert(FindText("Use your action bar"))
    activeBuffs["Seal of Righteousness"] = true
    Emit("UNIT_AURA", secret)
    assert(not sealAlert:IsShown(), "Every reapplication must clear the reminder during combat")
end
activeBuffs = { ["Seal of the Crusader"] = true }
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown(), "Another active seal must not trigger a replacement instruction")
restrictedBuffs = true
Emit("UNIT_AURA", secret)
assert(sealAlert:IsShown() and FindText("Check seal") and FindText("Status restricted"))
assert(not FindText("Seal missing"), "Restricted data must not leave a stale missing-seal assertion")
local auraAPI = C_UnitAuras
C_UnitAuras = nil
Emit("UNIT_AURA", secret)
assert(sealAlert:IsShown() and FindText("Status unavailable"))
C_UnitAuras = auraAPI
combat, restrictedBuffs = false, false
Emit("PLAYER_REGEN_ENABLED")
assert(not sealAlert:IsShown() and not panel:IsShown())
SlashCmdList.MYPALLADIN("")
C_Spell.GetSpellCooldownDuration = nil
Emit("SPELL_UPDATE_COOLDOWN")
assert(FindText("Cooldown unavailable"), "Missing APIs must not imply ready abilities")
local originalSpellLookup = C_SpellBook.FindSpellBookSlotForSpell
C_SpellBook.FindSpellBookSlotForSpell = function() return nil end
Emit("SPELLS_CHANGED")
assert(FindText("No cooldowns shown. Check Settings or train abilities."):IsShown())
assert(not sealAlert:IsShown(), "No learned damage seal must hide the reminder")
for _, frame in ipairs(frames) do
    if frame.cooldown then assert(not frame:IsShown()) end
end
C_SpellBook.FindSpellBookSlotForSpell = originalSpellLookup
Emit("SPELLS_CHANGED")
assert(not FindText("No cooldowns shown. Check Settings or train abilities."):IsShown())
for _, frame in ipairs(frames) do
    if frame.cooldown then
        assert((frame.spellID ~= nil) == frame:IsShown(), "Only learned spell cards may be shown")
    end
end
local settingsPanel
for _, frame in ipairs(frames) do
    if frame.name == "MyPalladinSettings" then settingsPanel = frame end
end
assert(settingsPanel and not settingsPanel:IsShown())
FindText("Settings").scripts.OnClick()
assert(settingsPanel:IsShown() and FindText("Editing profile: Leveling"))
local function SetCheck(caption, checked)
    local check = FindText(caption).parent
    assert(check.kind == "CheckButton")
    check:SetChecked(checked)
    check.scripts.OnClick(check)
end
local function SettingsProfile(name)
    for _, frame in ipairs(frames) do
        if frame.parent == settingsPanel and frame.text == name then
            frame.scripts.OnClick()
            return
        end
    end
    error("Missing settings profile button")
end
local levelingSettings = addon.GetSettings()
SetCheck("Compact panel", false)
assert(not levelingSettings.compact and FindText(addon.GetPreparationText()):IsShown())
local expandedHeight = panel.height
SetCheck("Show preparation when expanded", false)
assert(not FindText(addon.GetPreparationText()):IsShown() and panel.height < expandedHeight)
SetCheck("Show preparation when expanded", true)
SetCheck("Food", false)
assert(levelingSettings.hiddenPreparation.Food and not addon.GetPreparationText():find("Food"))
local preparationFrame = FindText(addon.GetPreparationText())
for _, item in ipairs(addon.GetProfile().preparation) do SetCheck(item, false) end
assert(addon.GetPreparationText() == nil and not preparationFrame:IsShown())
-- Captions for spells also appear on cooldown cards; select the checkbox caption explicitly.
local function SetSpell(name, checked)
    for _, frame in ipairs(frames) do
        if frame.text == name and frame.parent.kind == "CheckButton" then
            frame.parent:SetChecked(checked)
            frame.parent.scripts.OnClick(frame.parent)
            return
        end
    end
    error("Missing spell checkbox")
end
for _, name in ipairs(addon.GetProfile().spells) do SetSpell(name, false) end
assert(FindText("No cooldowns shown. Check Settings or train abilities."):IsShown())
for _, frame in ipairs(frames) do if frame.cooldown then assert(not frame:IsShown()) end end
SetSpell("Judgement", true)
local displayed = 0
for _, frame in ipairs(frames) do
    if frame.cooldown and frame:IsShown() then
        displayed = displayed + 1
        assert(frame.spellID == known.Judgement)
    end
end
assert(displayed == 1)
activeBuffs = {}
SetCheck("Highlight missing buffs", false)
assert(not sealAlert:IsShown() and FindText("Blessing: Missing").textColor[1] == 0.7)
SetCheck("Highlight missing buffs", true)
assert(sealAlert:IsShown() and FindText("Blessing: Missing").textColor[1] == 1)
UnitPower = function() return 25 end
UnitPowerMax = function() return 100 end
FindText("+").scripts.OnClick()
assert(levelingSettings.manaThreshold == 25 and FindText("Mana: 25%"))
FindText("+").scripts.OnClick()
assert(levelingSettings.manaThreshold == 30 and FindText("Low mana: 25%"))
SetCheck("Warn low mana below", false)
assert(FindText("Mana: 25%") and FindText("+").disabled and FindText("-").disabled)
SetCheck("Warn low mana below", true)
for _ = 1, 30 do FindText("-").scripts.OnClick() end
assert(levelingSettings.manaThreshold == 0 and FindText("-").disabled)
for _ = 1, 30 do FindText("+").scripts.OnClick() end
assert(levelingSettings.manaThreshold == 100 and FindText("+").disabled)
SettingsProfile("Dungeon")
assert(addon.GetSettings().compact and addon.GetSettings().manaThreshold == 20)
assert(FindText("Editing profile: Dungeon"))
assert(FindText("Compact panel").parent:GetChecked())
assert(FindText("Low mana: 25%") == nil, "Switching profile must clear the previous mana warning")
SettingsProfile("Leveling")
assert(addon.GetSettings() == levelingSettings and not levelingSettings.compact)
assert(FindText("100%") and FindText("Low mana: 25%"))
local savedSettings = LoadProfiles()
savedSettings.Initialize(MyPalladinDB)
assert(savedSettings.GetSettings().manaThreshold == 100)
assert(savedSettings.GetSettings().hiddenSpells["Holy Strike"])
assert(savedSettings.GetSettings().hiddenPreparation.Food)
SlashCmdList.MYPALLADIN("settings")
assert(not settingsPanel:IsShown())
SlashCmdList.MYPALLADIN("settings")
assert(settingsPanel:IsShown())
SetCheck("Crusader opener (long fights)", true)
assert(levelingSettings.crusaderOpener and not FindText("Apply Crusader"))
SlashCmdList.MYPALLADIN("settings")
SlashCmdList.MYPALLADIN("")
assert(not panel:IsShown())
targetExists = true
Emit("PLAYER_TARGET_CHANGED")
assert(sealAlert:IsShown() and FindText("Apply Crusader") and sealAlert.icon.texture == known["Seal of the Crusader"])
activeBuffs = { ["Seal of the Crusader"] = true }
Emit("UNIT_AURA", secret)
assert(FindText("Judge Crusader") and sealAlert.icon.texture == known.Judgement)
combat = true
Emit("PLAYER_REGEN_DISABLED")
Emit("SPELL_UPDATE_COOLDOWN")
assert(FindText("Judge Crusader"), "Casting attempts/cooldown changes must not confirm a target debuff")
targetDebuff = true
Emit("UNIT_AURA", secret)
assert(FindText("Switch seal") and FindText("Crusader debuff detected on target"))
assert(sealAlert.icon.texture == known["Seal of Righteousness"])
activeBuffs = { ["Seal of Righteousness"] = true }
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown() and not panel:IsShown())
targetDebuff = false
Emit("PLAYER_TARGET_CHANGED")
assert(FindText("Apply Crusader"), "A new target must not inherit completion from the previous one")
activeBuffs = { ["Seal of the Crusader"] = true }
Emit("UNIT_AURA", secret)
targetRestricted = true
Emit("UNIT_AURA", secret)
assert(FindText("Check Crusader") and FindText("Status restricted"))
assert(not FindText("Judge Crusader") and not FindText("Switch seal"), "Restrictions must clear stale instructions")
targetRestricted, targetDead = false, true
Emit("UNIT_HEALTH", secret)
assert(not sealAlert:IsShown(), "Dead targets must clear the opener")
targetDead, targetHostile = false, false
Emit("UNIT_FACTION", secret)
assert(not sealAlert:IsShown(), "Friendly targets must not prompt an offensive opener")
targetHostile, targetVisible = true, false
Emit("UNIT_FLAGS", secret)
assert(not sealAlert:IsShown(), "An invisible target must not imply a missing Judgement")
targetVisible = true
Emit("UNIT_FLAGS", secret)
assert(FindText("Judge Crusader"))
SetCheck("Highlight missing buffs", false)
assert(not sealAlert:IsShown())
SetCheck("Highlight missing buffs", true)
assert(FindText("Judge Crusader"))
combat = false
SettingsProfile("Dungeon")
assert(not addon.GetSettings().crusaderOpener and not sealAlert:IsShown())
SettingsProfile("Leveling")
assert(addon.GetSettings().crusaderOpener and FindText("Judge Crusader"))
local openerReload = LoadProfiles()
openerReload.Initialize(MyPalladinDB)
assert(openerReload.GetSettings().crusaderOpener, "Opener preference must survive reload")
SlashCmdList.MYPALLADIN("")
SlashCmdList.MYPALLADIN("opener")
assert(not addon.GetSettings().crusaderOpener and not panel:IsShown())
assert(not sealAlert:IsShown(), "Disabling the opener must restore the normal seal reminder")
targetExists, activeBuffs = false, {}
local firstCombatFrame = #frames + 1
combat, restrictedBuffs = true, true
local combatAddon = LoadProfiles()
assert(loadfile("MyPalladin/MyPalladin.lua"))("MyPalladin", combatAddon)
local combatEvents = frames[firstCombatFrame]
combatEvents.scripts.OnEvent(combatEvents, "ADDON_LOADED", "MyPalladin")
local combatSealAlert
for index = firstCombatFrame, #frames do
    if frames[index].name == "MyPalladinSealAlert" then combatSealAlert = frames[index] end
end
assert(combatSealAlert:IsShown() and combatSealAlert.icon.texture == known["Seal of Righteousness"],
    "Reloading in combat must show a learned fallback without inspecting equipment")
combat, restrictedBuffs = false, false
combatEvents.scripts.OnEvent(combatEvents, "PLAYER_REGEN_ENABLED")
assert(combatSealAlert:IsShown() and combatSealAlert.icon.texture == known["Seal of Righteousness"])
print("OK: per-profile settings, independent seal/opener alerts, target changes and safe restrictions/reload")
