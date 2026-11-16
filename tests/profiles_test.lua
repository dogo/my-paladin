local function LoadProfiles()
    local addon = {}
    assert(loadfile("MyPaladin/GuideInfo.lua"))("MyPaladin", addon)
    assert(loadfile("MyPaladin/Profiles.lua"))("MyPaladin", addon)
    assert(loadfile("MyPaladin/Diagnostics.lua"))("MyPaladin", addon)
    assert(loadfile("MyPaladin/PlayerState.lua"))("MyPaladin", addon)
    assert(loadfile("MyPaladin/CombatState.lua"))("MyPaladin", addon)
    assert(loadfile("MyPaladin/ActionHints.lua"))("MyPaladin", addon)
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
local unsealedLearned, hammerLearned = false, false
local unlearnedAssignments = {}
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
function methods:SetNormalFontObject(value) self.font = value end
function methods:SetBlendMode(mode) self.blend = mode end
function methods:CreateAnimationGroup()
    return {SetLooping = function() end, Play = function(group) group.playing = true end,
        Stop = function(group) group.playing = false end, IsPlaying = function(group) return group.playing end,
        CreateAnimation = function()
            return {SetFromAlpha = function() end, SetToAlpha = function() end, SetDuration = function() end}
        end}
end
function methods:SetHighlightFontObject(value) self.highlightFont = value end
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
function GetTime() return 42 end
function time() return 100000 end
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
local targetHealth, targetMaxHealth, creatureType = 100, 100, "Humanoid"
local echoAura, echoRestricted = nil, false
function UnitExists(unit) assert(unit == "target"); return targetExists end
function UnitCanAttack(unit, target) assert(unit == "player" and target == "target"); return targetHostile end
function UnitIsDeadOrGhost(unit) assert(unit == "target"); return targetDead end
function UnitIsVisible(unit) assert(unit == "target"); return targetVisible end
function UnitHealth(unit) assert(unit == "target"); return targetHealth end
function UnitHealthMax(unit) assert(unit == "target"); return targetMaxHealth end
function UnitCreatureType(unit) assert(unit == "target"); return creatureType end
C_Secrets = { ShouldSpellAuraBeSecret = function(name)
    if name == "Judgement of the Crusader" then return targetRestricted end
    if name == "Echo of Command" then return echoRestricted end
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
        if name == "Echo of Command" then
            assert(not echoRestricted, "Secret echo data must not be queried")
            return echoAura
        end
        assert(not restrictedBuffs, "Secret aura data must never be queried")
        return activeBuffs[name] and setmetatable({}, { __index = function() error("Aura fields must not be inspected") end }) or nil
    end,
}
C_SpellBook = {
    FindSpellBookSlotForSpell = function(name)
        if (name == "Hammer of Wrath" and not hammerLearned) or name == "Holy Shock" or unlearnedAssignments[name] then return nil end
        if name == "Unsealed Wrath" and not unsealedLearned then return nil end
        if not known[name] then
            nextID = nextID + 1
            known[name] = nextID
        end
        return known[name], 0
    end,
    GetSpellBookItemInfo = function(slot) return { spellID = slot, iconID = slot } end,
}
MyPaladinDB = { activeProfile = "dungeon" }
addon = LoadProfiles()
assert(loadfile("MyPaladin/MyPaladin.lua"))("MyPaladin", addon)
local events = frames[1]
local function Emit(event, unit) events.scripts.OnEvent(events, event, unit) end
Emit("ADDON_LOADED", "AnotherAddon")
assert(not SlashCmdList.MYPALADIN)
Emit("ADDON_LOADED", "MyPaladin")
assert(MyPaladinDB.activeProfile == "dungeon")
-- Legacy standalone HUD remains available with the unified combat helper disabled.
for _, settings in pairs(MyPaladinDB.profileSettings) do settings.combatHints = false end
local panel
for _, frame in ipairs(frames) do
    if frame.name == "MyPaladinPanel" then panel = frame end
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
assert(MyPaladinDB.compact == true)
assert(FindText("Expand"))
assert(not FindText(addon.GetPreparationText()):IsShown())
assert(FindText("Seal: Command"))
assert(FindText("Blessing: Might"))
assert(FindText("Aura: Retribution"))
local sealAlert
for _, frame in ipairs(frames) do
    if frame.name == "MyPaladinSealAlert" then sealAlert = frame end
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
SlashCmdList.MYPALADIN("compact")
assert(addon.GetSettings().compact == true and panel.height == compactHeight)
assert(FindText(addon.GetPreparationText()))
local utilityCard
for _, frame in ipairs(frames) do
    if frame.spellID == known["Hammer of Justice"] then utilityCard = frame end
end
assert(utilityCard, "Dungeon must track control")
SlashCmdList.MYPALADIN("  RAID  ")
assert(MyPaladinDB.activeProfile == "raid")
assert(FindText("Active profile: Raid  |  Level 25"))
assert(FindText("Raid").disabled and not FindText("Dungeon").disabled)
assert(utilityCard.spellID == known["Blessing of Freedom"], "Profile switch must update tracked spells")
assert(FindText(addon.GetPreparationText()))
SlashCmdList.MYPALADIN("unknown")
assert(MyPaladinDB.activeProfile == "raid")
FindText("Leveling").scripts.OnClick()
assert(MyPaladinDB.activeProfile == "leveling", "Profile buttons must save the selection")
assert(utilityCard.spellID == known["Divine Shield"])
restrictedBuffs = true
combat = true
Emit("PLAYER_REGEN_DISABLED")
assert(FindText("Seal: Restricted"), "Combat restrictions must clear previously visible buff status")
assert(FindText("Blessing: Restricted"))
assert(not FindText("Seal: Missing"))
weaponType = "INVTYPE_WEAPON"
Emit("PLAYER_EQUIPMENT_CHANGED", 16)
assert(not sealAlert:IsShown(), "Unknown seal status must not show a seal reminder during combat")
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
SlashCmdList.MYPALADIN("")
assert(not panel:IsShown())
SlashCmdList.MYPALADIN("")
assert(panel:IsShown())
-- Aura events keep the combat reminder current with the management panel closed.
SlashCmdList.MYPALADIN("")
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
activeBuffs = {}
Emit("UNIT_AURA", secret)
assert(sealAlert:IsShown(), "Public missing-seal detection must still show a reminder")
restrictedBuffs = true
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown(), "A previously missing seal must not leave a stale instruction after access is restricted")
restrictedBuffs = false
activeBuffs = { ["Seal of the Crusader"] = true }
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown(), "Another active seal must not trigger a replacement instruction")
restrictedBuffs = true
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown(), "An active but restricted Crusader must not produce a misleading seal reminder")
local auraAPI = C_UnitAuras
C_UnitAuras = nil
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown(), "Unavailable aura data must not produce a seal reminder")
C_UnitAuras = auraAPI
combat, restrictedBuffs = false, false
Emit("PLAYER_REGEN_ENABLED")
assert(not sealAlert:IsShown() and not panel:IsShown())
SlashCmdList.MYPALADIN("")
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
    if frame.name == "MyPaladinSettings" then settingsPanel = frame end
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
savedSettings.Initialize(MyPaladinDB)
assert(savedSettings.GetSettings().manaThreshold == 100)
assert(savedSettings.GetSettings().hiddenSpells["Holy Strike"])
assert(savedSettings.GetSettings().hiddenPreparation.Food)
SlashCmdList.MYPALADIN("settings")
assert(not settingsPanel:IsShown())
SlashCmdList.MYPALADIN("settings")
assert(settingsPanel:IsShown())
SetCheck("Crusader opener (long fights)", true)
assert(levelingSettings.crusaderOpener and not FindText("Apply Crusader"))
SlashCmdList.MYPALADIN("settings")
SlashCmdList.MYPALADIN("")
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
openerReload.Initialize(MyPaladinDB)
assert(openerReload.GetSettings().crusaderOpener, "Opener preference must survive reload")
SlashCmdList.MYPALADIN("")
SlashCmdList.MYPALADIN("opener")
assert(not addon.GetSettings().crusaderOpener and not panel:IsShown())
assert(not sealAlert:IsShown(), "Disabling the opener must restore the normal seal reminder")
unsealedLearned, weaponType, weaponSpeed = true, "INVTYPE_2HWEAPON", "Speed 3.40"
activeBuffs = { ["Seal of Command"] = true }
Emit("SPELLS_CHANGED")
assert(not sealAlert:IsShown(), "Echo guidance only runs in combat")
combat = true
Emit("PLAYER_REGEN_DISABLED")
assert(FindText("Build echoes") and FindText("Echoes: 0/2 | Keep Command") and not panel:IsShown())
echoAura = { spellId = 1311703, applications = 1 }
Emit("UNIT_AURA", secret)
assert(FindText("Echoes: 1/2 | Keep Command"))
echoAura.applications = 2
Emit("UNIT_AURA", secret)
assert(FindText("Spend echoes") and sealAlert.icon.texture == known["Seal of Righteousness"])
SetCheck("Crusader opener (long fights)", true)
targetDebuff = false
Emit("UNIT_AURA", secret)
assert(FindText("Apply Crusader") and not FindText("Spend echoes"), "The long-fight opener takes priority")
targetDebuff = true
Emit("UNIT_AURA", secret)
assert(FindText("Spend echoes"), "Echo guidance resumes once the opener needs no action")
SetCheck("Crusader opener (long fights)", false)
activeBuffs = { ["Seal of Righteousness"] = true }
Emit("UNIT_AURA", secret)
for _ = 1, 3 do
    Emit("SPELL_UPDATE_COOLDOWN")
    Emit("UNIT_HEALTH", secret)
    assert(FindText("Land a melee hit") and not FindText("Return to Command"), "Do not return merely because the seal changed or a hit was attempted")
end
echoAura = nil
Emit("UNIT_AURA", secret)
assert(FindText("Return to Command") and FindText("No Command echoes detected"))
assert(sealAlert.icon.texture == known["Seal of Command"])
activeBuffs = { ["Seal of Command"] = true }
Emit("UNIT_AURA", secret)
assert(FindText("Build echoes"))
echoAura = { spellId = 1311703, applications = 3 }
Emit("UNIT_AURA", secret)
assert(FindText("Spend echoes"))
targetDead = true
Emit("UNIT_HEALTH", secret)
assert(not sealAlert:IsShown())
targetDead, targetExists = false, false
Emit("PLAYER_TARGET_CHANGED")
assert(not sealAlert:IsShown())
targetExists = true
Emit("PLAYER_TARGET_CHANGED")
assert(FindText("Spend echoes"), "Changing target must retain actual player echoes")
echoRestricted = true
Emit("UNIT_AURA", secret)
assert(FindText("Check echoes") and FindText("Status restricted") and not FindText("Spend echoes"))
echoRestricted, echoAura.applications = false, secret
Emit("UNIT_AURA", secret)
assert(FindText("Check echoes") and FindText("Status restricted"), "Secret counts must not be formatted")
echoAura.spellId, echoAura.applications = 1311704, 2
Emit("UNIT_AURA", secret)
assert(FindText("Check echoes") and FindText("Status unavailable"))
echoAura.spellId = 1311703
SetCheck("Unsealed Wrath echoes", false)
assert(not sealAlert:IsShown() and not addon.GetSettings().echoGuidance)
SettingsProfile("Dungeon")
assert(addon.GetSettings().echoGuidance and FindText("Spend echoes"))
SettingsProfile("Leveling")
assert(not addon.GetSettings().echoGuidance and not sealAlert:IsShown())
local echoesReload = LoadProfiles()
echoesReload.Initialize(MyPaladinDB)
assert(not echoesReload.GetSettings().echoGuidance)
SlashCmdList.MYPALADIN("")
SlashCmdList.MYPALADIN("echoes")
assert(addon.GetSettings().echoGuidance and FindText("Spend echoes") and not panel:IsShown())
SlashCmdList.MYPALADIN("echoes")
assert(not addon.GetSettings().echoGuidance and not sealAlert:IsShown())
combat, unsealedLearned, weaponType = false, false, "INVTYPE_WEAPON"
targetExists, activeBuffs = false, {}
activeBuffs = { ["Seal of Righteousness"] = true }
Emit("PLAYER_REGEN_ENABLED")
settingsPanel:Show()
local function AssignmentButton(text)
    for _, frame in ipairs(frames) do
        if frame.parent == settingsPanel and frame.kind == "Button" and frame.text == text then return frame end
    end
    error("Missing assignment selector: " .. text)
end
AssignmentButton("Blessing: Any").scripts.OnClick()
assert(addon.GetSettings().blessing == "Blessing of Might" and FindText("Blessing: Might missing"))
assert(FindText("Prepare blessing") and sealAlert.icon.texture == known["Blessing of Might"])
AssignmentButton("Aura: Any").scripts.OnClick()
activeBuffs["Blessing of Might"] = true
Emit("UNIT_AURA", secret)
assert(FindText("Prepare aura") and sealAlert.icon.texture == known["Devotion Aura"])
activeBuffs["Devotion Aura"] = true
Emit("UNIT_AURA", secret)
assert(not sealAlert:IsShown())
AssignmentButton("Blessing: Might").scripts.OnClick()
assert(addon.GetSettings().blessing == "Blessing of Wisdom" and FindText("Blessing: Wisdom missing"))
unlearnedAssignments["Blessing of Wisdom"] = true
Emit("SPELLS_CHANGED")
assert(FindText("Blessing: Wisdom (not learned)") and not sealAlert:IsShown())
activeBuffs["Blessing of Wisdom"] = true
Emit("UNIT_AURA", secret)
assert(FindText("Blessing: Wisdom") and not sealAlert:IsShown())
activeBuffs["Blessing of Wisdom"] = nil
combat = true
Emit("PLAYER_REGEN_DISABLED")
assert(not sealAlert:IsShown(), "Assigned buff preparation must not interrupt the fight")
combat, restrictedBuffs = false, true
Emit("PLAYER_REGEN_ENABLED")
assert(FindText("Blessing: Restricted") and not sealAlert:IsShown())
restrictedBuffs = false
AssignmentButton("Blessing: Wisdom").scripts.OnClick()
AssignmentButton("Blessing: Kings").scripts.OnClick()
assert(addon.GetSettings().blessing == "any", "Selector must cycle back to Any")
for _, name in ipairs(addon.buffGroups[3].spells) do
    local short = name:gsub(" Aura$", "")
    AssignmentButton("Aura: " .. short).scripts.OnClick()
end
assert(addon.GetSettings().aura == "any")
unlearnedAssignments["Blessing of Wisdom"] = nil
SettingsProfile("Dungeon")
AssignmentButton("Blessing: Any").scripts.OnClick()
SettingsProfile("Raid")
assert(addon.GetSettings().blessing == "any")
SettingsProfile("Dungeon")
assert(addon.GetSettings().blessing == "Blessing of Might")
local foundSupport = false
for _, frame in ipairs(frames) do
    if frame.cooldown and frame.label.text == "Lay on Hands" and frame:IsShown() then foundSupport = true end
end
assert(foundSupport, "Expanded support spells must fit beyond the old eight-card limit")
SetCheck("Weapon buff", false)
assert(not addon.GetPreparationText():find("Weapon buff"))
local assignmentsReload = LoadProfiles()
assignmentsReload.Initialize(MyPaladinDB)
assert(assignmentsReload.GetSettings().blessing == "Blessing of Might")
SettingsProfile("Leveling")
settingsPanel:Hide()
targetExists, activeBuffs = false, {}
local combatHint
for _, frame in ipairs(frames) do
    if frame.name == "MyPaladinCombatHint" then combatHint = frame end
end
assert(combatHint and combatHint.parent == UIParent and not combatHint.mouseEnabled)
SlashCmdList.MYPALADIN("")
assert(not panel:IsShown())
activeBuffs, targetExists, combat = { ["Seal of Righteousness"] = true }, true, true
addon.GetSettings().combatHints = true
C_Spell.GetSpellCooldownDuration = function() return secret end
local cooldowns, usable, ranges = {}, {}, {}
C_Spell.IsSpellUsable = function(id) return usable[id] ~= false, false end
C_Spell.IsSpellInRange = function(id) return ranges[id] ~= false end
C_Spell.GetSpellCooldown = function(id)
    return { startTime = 42, duration = cooldowns[id] or 0, isEnabled = true, modRate = 1 }
end
Emit("PLAYER_REGEN_DISABLED")
assert(combatHint:IsShown() and FindText("Now: Judgement") and not panel:IsShown())
local hintCooldown
for _, frame in ipairs(frames) do
    if frame.parent == combatHint and frame.kind == "Cooldown" then hintCooldown = frame end
end
assert(hintCooldown.duration == secret, "Forward the hint cooldown duration without inspecting it")
cooldowns[known.Judgement] = 8
Emit("SPELL_UPDATE_COOLDOWN")
assert(FindText("Now: Holy Strike"), "The hint must change when Judgement goes on cooldown")
cooldowns[known["Holy Strike"]] = 10
Emit("SPELL_UPDATE_COOLDOWN")
assert(FindText("Wait: Judgement") and FindText("Ready in 8.0s"))
local originalTime = GetTime
GetTime = function() return 50 end
combatHint.scripts.OnUpdate(combatHint, 0.1)
assert(FindText("Now: Judgement"), "Time expiry must update the action without another cooldown event")
GetTime = originalTime
cooldowns[known["Holy Strike"]] = 0
addon.GetSettings().manaThreshold = 20
UnitPower = function() return 100 end
UnitPowerMax = function() return 100 end
SlashCmdList.MYPALADIN("aoe")
assert(addon.GetSettings().combatMode == "aoe" and FindText("Now: Consecration"))
UnitPower = function() return 10 end
UnitPowerMax = function() return 100 end
Emit("UNIT_POWER_UPDATE", secret)
assert(FindText("Now: Holy Strike"), "Avoid optional area damage below the public mana threshold")
UnitPower = function() return secret end
Emit("UNIT_POWER_UPDATE", secret)
assert(FindText("Now: Consecration"), "Public native usability can check the cast cost when raw mana is secret")
SlashCmdList.MYPALADIN("single")
cooldowns[known["Holy Strike"]] = 10
creatureType = "Undead"
Emit("PLAYER_TARGET_CHANGED")
assert(FindText("Now: Exorcism"))
creatureType = secret
Emit("PLAYER_TARGET_CHANGED")
assert(FindText("Wait: Judgement"), "Never recommend Exorcism without an eligible creature type")
creatureType, hammerLearned, targetHealth = "Humanoid", true, 19
Emit("SPELLS_CHANGED")
assert(FindText("Now: Hammer of Wrath"))
-- The client makes Hammer of Wrath unusable at 20% health or more.
targetHealth, usable[known["Hammer of Wrath"]] = 20, false
Emit("UNIT_HEALTH", secret)
assert(FindText("Wait: Judgement"))
targetHealth, usable[known["Hammer of Wrath"]] = secret, true
Emit("UNIT_HEALTH", secret)
assert(FindText("Now: Hammer of Wrath"), "Secret health: the client's public usability enforces the execute window")
usable[known["Hammer of Wrath"]] = false
Emit("UNIT_HEALTH", secret)
assert(not FindText("Now: Hammer of Wrath") and FindText("Wait: Judgement"))
targetDead = true
Emit("UNIT_HEALTH", secret)
assert(not combatHint:IsShown() and hintCooldown.duration == nil)
targetDead = false
Emit("UNIT_FLAGS", secret)
SlashCmdList.MYPALADIN("aoe")
settingsPanel:Show()
SettingsProfile("Dungeon")
assert(addon.GetSettings().combatMode == "single")
FindText("Mode: Single").scripts.OnClick()
assert(addon.GetSettings().combatMode == "aoe" and FindText("Combat: Area (AoE)"))
FindText("Combat: Area (AoE)").scripts.OnClick()
assert(addon.GetSettings().combatMode == "single")
SettingsProfile("Leveling")
assert(addon.GetSettings().combatMode == "aoe")
SetCheck("Combat context hints", false)
assert(not combatHint:IsShown())
local contextReload = LoadProfiles()
contextReload.Initialize(MyPaladinDB)
assert(contextReload.GetSettings().combatMode == "aoe" and not contextReload.GetSettings().combatHints)
SetCheck("Combat context hints", true)
assert(combatHint:IsShown())
-- Replay a public seal cast followed by hidden auras and timer expiry through the actual event handler.
addon.GetSettings().combatMode = "single"
restrictedBuffs, activeBuffs = true, {}
cooldowns[known.Judgement], cooldowns[known["Holy Strike"]] = 0, 0
local clockBeforeEstimate = GetTime
local estimateTime = 100
GetTime = function() return estimateTime end
events.scripts.OnEvent(events, "UNIT_SPELLCAST_SUCCEEDED", "player", secret, known["Seal of Righteousness"])
assert(FindText("Now: Judgement") and not sealAlert:IsShown())
estimateTime = 131
local usableBeforeProbe = C_Spell.IsSpellUsable
-- Judgement usability is the seal probe: usable means some seal is still up.
combatHint.scripts.OnUpdate(combatHint, 0.1)
assert(FindText("Now: Judgement"), "A usable Judgement proves a seal outlived the estimate")
C_Spell.IsSpellUsable = function(id)
    if id == known.Judgement then return secret, secret end
    return usableBeforeProbe(id)
end
combatHint.scripts.OnUpdate(combatHint, 0.1)
assert(FindText("Estimate: Seal of Righteousness"), "Hidden seal expiry must produce an explicitly estimated maintenance action")
C_Spell.IsSpellUsable = function(id)
    if id == known.Judgement then return false, false end
    return usableBeforeProbe(id)
end
combatHint.scripts.OnUpdate(combatHint, 0.1)
assert(FindText("Now: Seal of Righteousness"), "Judgement unusable without lack of mana is observed seal absence")
C_Spell.IsSpellUsable = usableBeforeProbe
events.scripts.OnEvent(events, "UNIT_SPELLCAST_SUCCEEDED", "player", secret, known["Seal of Righteousness"])
assert(FindText("Now: Judgement"), "Recasting the seal must release the damage rotation")
events.scripts.OnEvent(events, "UNIT_SPELLCAST_START", "player", secret, known["Holy Light"])
assert(FindText("Casting: Holy Light"), "The combat engine must not tell the player to interrupt their own cast")
events.scripts.OnEvent(events, "UNIT_SPELLCAST_STOP", "player", secret, known["Holy Light"])
assert(FindText("Now: Judgement"))
events.scripts.OnEvent(events, "UNIT_SPELLCAST_START", "player", secret, secret)
assert(not combatHint:IsShown(), "A secret cast ID must not be used to invent a casting icon")
events.scripts.OnEvent(events, "UNIT_SPELLCAST_STOP", "player", secret, secret)
GetTime = clockBeforeEstimate
restrictedBuffs, activeBuffs = false, {["Seal of Righteousness"] = true}
-- Replay the player's macro through the real HUD and cast/action-bar event handlers.
combat = false
ActionButton2 = CreateFrame("Button", nil, UIParent)
ActionButton2.action = 2
GetActionInfo = function() return "macro", known["Holy Strike"], "spell" end
GetActionText = function() return "Holy Strike Macro" end
GetMacroBody = function() return "#showtooltip Holy Strike\n/targetenemy [noharm][dead]\n/startattack\n/cast Judgement\n/cast Holy Strike" end
GetBindingKey = function() return "2" end
Emit("PLAYER_REGEN_ENABLED")
combat = true
Emit("PLAYER_REGEN_DISABLED")
assert(FindText("Now: Holy Strike macro") and not FindText("Also ready: Holy Strike"))
cooldowns[known.Judgement], cooldowns[known["Holy Strike"]] = 8, 10
events.scripts.OnEvent(events, "UNIT_SPELLCAST_SUCCEEDED", "player", secret, known.Judgement)
assert(FindText("Wait: Holy Strike macro") and not FindText("Now: Judgement"), "A confirmed macro cast must release the Judgement recommendation")
Emit("ACTIONBAR_SLOT_CHANGED", 2)
assert(FindText("Wait: Holy Strike macro") and addon.ShowActionHint(known.Judgement, "wait") == "2",
    "Macro notifications during combat must retain a verified binding")
GetTime = function() return 50 end
combatHint.scripts.OnUpdate(combatHint, 0.1)
assert(FindText("Now: Holy Strike macro"), "Recommend the same macro again only after a spell becomes ready")
GetTime = clockBeforeEstimate
cooldowns[known.Judgement], cooldowns[known["Holy Strike"]] = 0, 0
ActionButton2, GetActionInfo, GetActionText, GetMacroBody, GetBindingKey = nil, nil, nil, nil, nil
combat = false
Emit("PLAYER_REGEN_ENABLED")
combat = true
Emit("PLAYER_REGEN_DISABLED")
Emit("PLAYER_DEAD")
Emit("UNIT_AURA", secret)
assert(not combatHint:IsShown() and not sealAlert:IsShown(), "Death must keep both HUDs hidden across following aura updates")
Emit("PLAYER_ALIVE")
assert(combatHint:IsShown())
C_Spell.GetSpellCooldownDuration = nil
Emit("SPELL_UPDATE_COOLDOWN")
assert(FindText("Use now | Usability, range and cooldown checked | Cooldown unavailable"))
settingsPanel:Hide()
combat, targetExists, hammerLearned, targetHealth = false, false, false, 100
activeBuffs = {}
Emit("PLAYER_REGEN_ENABLED")
assert(not combatHint:IsShown())
local firstCombatFrame = #frames + 1
combat, restrictedBuffs = true, true
local combatAddon = LoadProfiles()
assert(loadfile("MyPaladin/MyPaladin.lua"))("MyPaladin", combatAddon)
local combatEvents = frames[firstCombatFrame]
combatEvents.scripts.OnEvent(combatEvents, "ADDON_LOADED", "MyPaladin")
local combatSealAlert
for index = firstCombatFrame, #frames do
    if frames[index].name == "MyPaladinSealAlert" then combatSealAlert = frames[index] end
end
assert(not combatSealAlert:IsShown(), "Reloading in combat with restricted auras must not guess a missing seal")
combat, restrictedBuffs = false, false
combatEvents.scripts.OnEvent(combatEvents, "PLAYER_REGEN_ENABLED")
assert(combatSealAlert:IsShown() and combatSealAlert.icon.texture == known["Seal of Righteousness"])
local traceSerial = MyPaladinLog.serial
combatEvents.scripts.OnEvent(combatEvents, "UNIT_SPELLCAST_SUCCEEDED", "player", secret, secret)
local secretCast = MyPaladinLog.entries[(MyPaladinLog.serial - 1) % 1000 + 1]
assert(MyPaladinLog.serial == traceSerial + 1 and secretCast:find('"feature":"cast"', 1, true)
    and not secretCast:find('"spell"', 1, true), "Secret cast IDs must not be exported")
combatEvents.scripts.OnEvent(combatEvents, "ADDON_ACTION_BLOCKED", "OtherAddon")
assert(MyPaladinLog.serial == traceSerial + 1)
combatEvents.scripts.OnEvent(combatEvents, "ADDON_ACTION_BLOCKED", "MyPaladin", "ProtectedFunction")
local blocked = MyPaladinLog.entries[(MyPaladinLog.serial - 1) % 1000 + 1]
assert(blocked:find('"feature":"error"', 1, true) and blocked:find('"detail":"ProtectedFunction"', 1, true))
SlashCmdList.MYPALADIN("trace mark validation")
assert(MyPaladinLog.entries[(MyPaladinLog.serial - 1) % 1000 + 1]:find('"detail":"validation"', 1, true))
print("OK: per-profile settings, independent seal/opener/echo/context hints, assignments and safe restrictions/reload")
