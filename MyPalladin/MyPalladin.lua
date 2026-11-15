local addonName, addon = ...
local panel, heading, focus, preparation, mana, manaLabel, mode, footer, reference, empty
local cards, buttons, buffLabels = {}, {}, {}
local learnedCount = 0
local Layout
local sealAlert, sealTitle, sealName, sealHelp, recommendedSeal, recommendedSealInfo
local settingsPanel, settingsHeading, thresholdLabel, thresholdMinus, thresholdPlus
local settingsChecks, spellChecks, preparationChecks, settingsButtons, assignmentButtons = {}, {}, {}, {}, {}
local RefreshSettings

local function Say(message)
    print("|cffffca65My Paladin:|r " .. message)
end

local function UpdateMana()
    -- Forward combat values to native widgets without calculating or comparing them.
    local current, maximum = UnitPower("player", 0), UnitPowerMax("player", 0)
    mana:SetMinMaxValues(0, maximum)
    mana:SetValue(current)
    local text, low = addon.GetManaText(current, maximum, addon.GetSettings())
    manaLabel:SetText(text)
    if low then
        mana:SetStatusBarColor(0.85, 0.3, 0.08)
    else
        mana:SetStatusBarColor(0.12, 0.4, 0.9)
    end
end

local function UpdateSealAlert(status, activeSeal)
    local combat = InCombatLockdown()
    sealAlert:EnableMouse(not combat)
    if combat then sealAlert:StopMovingOrSizing() end
    if not addon.GetSettings().buffWarnings or not recommendedSealInfo then
        sealAlert:Hide()
        return
    end
    local step, info = addon.GetCrusaderStep(status, activeSeal)
    if step then
        sealTitle:SetTextColor(1, 0.5, 0.2)
        if step == "apply" then
            sealTitle:SetText("Apply Crusader")
            sealName:SetText("Seal of the Crusader")
            sealHelp:SetText("Long fight opener")
        elseif step == "judge" then
            sealTitle:SetText("Judge Crusader")
            sealName:SetText("Judgement")
            sealHelp:SetText("Use your Judgement / Holy Strike macro")
        elseif step == "damage" then
            sealTitle:SetText("Switch seal")
            sealName:SetText(recommendedSeal)
            sealHelp:SetText("Crusader debuff detected on target")
            info = recommendedSealInfo
        else
            sealTitle:SetText("Check Crusader")
            sealTitle:SetTextColor(0.7, 0.7, 0.7)
            sealName:SetText("Crusader opener")
            sealHelp:SetText(step == "restricted" and "Status restricted" or "Status unavailable")
        end
        sealAlert.icon:SetTexture(info.iconID)
        sealAlert:Show()
        return
    end
    local echo, echoInfo, count = addon.GetEchoStep(status, activeSeal, recommendedSeal)
    if echo then
        sealAlert.icon:SetTexture(echoInfo.iconID)
        sealTitle:SetTextColor(1, 0.5, 0.2)
        if echo == "build" then
            sealTitle:SetText("Build echoes")
            sealTitle:SetTextColor(0.4, 1, 0.4)
            sealName:SetText("Seal of Command")
            sealHelp:SetText("Echoes: " .. count .. "/2 | Keep Command")
        elseif echo == "swap" then
            sealTitle:SetText("Spend echoes")
            sealName:SetText("Seal of Righteousness")
            sealHelp:SetText("Echoes: " .. count .. " | Switch seal")
        elseif echo == "wait" then
            sealTitle:SetText("Land a melee hit")
            sealName:SetText("Seal of Righteousness")
            sealHelp:SetText("Echoes: " .. count .. " | Stay on Righteousness")
        elseif echo == "return" then
            sealTitle:SetText("Return to Command")
            sealName:SetText("Seal of Command")
            sealHelp:SetText("No Command echoes detected")
        else
            sealTitle:SetText("Check echoes")
            sealTitle:SetTextColor(0.7, 0.7, 0.7)
            sealName:SetText("Echo of Command")
            sealHelp:SetText(echo == "restricted" and "Status restricted" or "Status unavailable")
        end
        sealAlert:Show()
        return
    end
    if status == "active" then
        local prepInfo, prepName, label = addon.GetPreparationReminder()
        if prepInfo then
            sealAlert.icon:SetTexture(prepInfo.iconID)
            sealTitle:SetText("Prepare " .. label:lower())
            sealTitle:SetTextColor(1, 0.5, 0.2)
            sealName:SetText(prepName)
            sealHelp:SetText("Use your action bar before the pull")
            sealAlert:Show()
            return
        end
        sealAlert:Hide()
        return
    end
    sealAlert.icon:SetTexture(recommendedSealInfo.iconID)
    sealName:SetText(recommendedSeal)
    if status == "missing" then
        sealTitle:SetText("Seal missing")
        sealTitle:SetTextColor(1, 0.5, 0.2)
        sealHelp:SetText("Use your action bar")
    elseif combat then
        sealTitle:SetText("Check seal")
        sealTitle:SetTextColor(0.7, 0.7, 0.7)
        sealHelp:SetText(status == "restricted" and "Status restricted" or "Status unavailable")
    else
        sealAlert:Hide()
        return
    end
    sealAlert:Show()
end

local function UpdateBuffs()
    local warn = addon.GetSettings().buffWarnings
    for index, group in ipairs(addon.buffGroups) do
        local status, name, spellName = addon.GetProfileBuffStatus(group)
        local label = buffLabels[index]
        if status == "active" then
            label:SetText(group.label .. ": " .. name)
            label:SetTextColor(0.4, 1, 0.4)
        elseif status == "missing" then
            label:SetText(group.label .. ": " .. (name and name .. " missing" or "Missing"))
            if warn and index ~= 1 then label:SetTextColor(1, 0.5, 0.2) else label:SetTextColor(0.7, 0.7, 0.7) end
        elseif status == "unlearned" then
            label:SetText(group.label .. ": " .. name .. " (not learned)")
            label:SetTextColor(0.7, 0.7, 0.7)
        else
            label:SetText(group.label .. (status == "restricted" and ": Restricted" or ": Unavailable"))
            label:SetTextColor(0.7, 0.7, 0.7)
        end
        if index == 1 then UpdateSealAlert(status, spellName) end
    end
end

local function UpdateSealRecommendation()
    if not InCombatLockdown() or not recommendedSealInfo then
        recommendedSealInfo, recommendedSeal = addon.GetRecommendedSeal()
    end
end

local function UpdateCooldowns()
    for _, card in ipairs(cards) do
        if card.spellID then
            if C_Spell.GetSpellCooldownDuration and card.cooldown.SetCooldownFromDurationObject then
                local duration = C_Spell.GetSpellCooldownDuration(card.spellID)
                if duration then
                    card.cooldown:SetCooldownFromDurationObject(duration)
                    card.status:SetText("")
                else
                    card.cooldown:Clear()
                    card.status:SetText("Cooldown unavailable")
                end
            else
                card.cooldown:Clear()
                card.status:SetText("Cooldown unavailable")
            end
        end
    end
end

local function RefreshProfile()
    local profile, settings = addon.GetProfile(), addon.GetSettings()
    heading:SetText("Active profile: " .. profile.name .. "  |  Level " .. UnitLevel("player"))
    focus:SetText(profile.focus)
    preparation:SetText(addon.GetPreparationText() or "")
    for id, button in pairs(buttons) do
        if id == addon.db.activeProfile then
            button:Disable()
        else
            button:Enable()
        end
    end
    learnedCount = 0
    for _, name in ipairs(profile.spells) do
        local info = not settings.hiddenSpells[name] and addon.GetLearnedSpell(name)
        if info and info.spellID then
            learnedCount = learnedCount + 1
            local card = cards[learnedCount]
            card.spellID = info.spellID
            card.label:SetText(name)
            card.icon:SetTexture(info.iconID)
            card.cooldown:Clear()
            card.status:SetText("")
            card:Show()
        end
    end
    for index = learnedCount + 1, #cards do
        cards[index].spellID = nil
        cards[index].cooldown:Clear()
        cards[index]:Hide()
    end
    Layout()
    UpdateSealRecommendation()
    UpdateCooldowns()
    UpdateMana()
    UpdateBuffs()
    if settingsPanel:IsShown() then RefreshSettings() end
end

local function ChooseProfile(id)
    if not addon.SelectProfile(id) then
        Say("Choose a profile: /mp leveling, /mp dungeon or /mp raid")
        return
    end
    RefreshProfile()
    panel:Show()
end

local function Text(parent, font, x, y, width)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    return text
end

Layout = function()
    local settings = addon.GetSettings()
    local compact = settings.compact
    local showPreparation = not compact and settings.showPreparation and addon.GetPreparationText() ~= nil
    local buffY = compact and 104 or 152
    local manaY = buffY + 36
    local cardsY = manaY + 32
    local rowHeight = compact and 44 or 50
    local rows = math.max(1, math.ceil(learnedCount / 2))
    local afterCards = cardsY + rows * rowHeight
    mode:SetText(compact and "Expand" or "Compact")
    focus:SetShown(not compact)
    preparation:SetShown(showPreparation)
    for index, label in ipairs(buffLabels) do
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", 16 + (index - 1) * 132, -buffY)
    end
    mana:ClearAllPoints()
    mana:SetPoint("TOPLEFT", 16, -manaY)
    for index, card in ipairs(cards) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", 16 + ((index - 1) % 2) * 200, -cardsY - math.floor((index - 1) / 2) * rowHeight)
    end
    empty:ClearAllPoints()
    empty:SetPoint("TOPLEFT", 16, -cardsY)
    empty:SetShown(learnedCount == 0)
    preparation:ClearAllPoints()
    preparation:SetPoint("TOPLEFT", 16, -afterCards - 8)
    local footerY = afterCards + (showPreparation and 58 or 8)
    footer:ClearAllPoints()
    footer:SetPoint("TOPLEFT", 16, -footerY)
    footer:SetText("Drag to move | /mp to toggle")
    reference:ClearAllPoints()
    reference:SetPoint("TOPLEFT", 16, -footerY - 24)
    panel:SetSize(420, footerY + 50)
end

local function ToggleCompact()
    local settings = addon.GetSettings()
    settings.compact = not settings.compact
    RefreshProfile()
end

RefreshSettings = function()
    local profile, settings = addon.GetProfile(), addon.GetSettings()
    settingsHeading:SetText("Editing profile: " .. profile.name)
    for id, button in pairs(settingsButtons) do button:SetEnabled(id ~= addon.db.activeProfile) end
    for key, check in pairs(settingsChecks) do check:SetChecked(settings[key]) end
    for _, group in ipairs(addon.buffGroups) do
        if group.setting then
            local selected = settings[group.setting]
            local name = selected == "any" and "Any" or selected:gsub("^Blessing of ", ""):gsub(" Aura$", "")
            assignmentButtons[group.setting]:SetText(group.label .. ": " .. name)
        end
    end
    thresholdLabel:SetText(settings.manaThreshold .. "%")
    thresholdMinus:SetEnabled(settings.manaWarning and settings.manaThreshold > 0)
    thresholdPlus:SetEnabled(settings.manaWarning and settings.manaThreshold < 100)
    for index, check in ipairs(spellChecks) do
        local name = profile.spells[index]
        check:SetShown(name ~= nil)
        if name then
            check.label:SetText(name)
            check:SetChecked(not settings.hiddenSpells[name])
        else
            check.label:SetText("")
        end
    end
    for index, check in ipairs(preparationChecks) do
        local item = profile.preparation[index]
        check:SetShown(item ~= nil)
        if item then
            check.label:SetText(item)
            check:SetChecked(not settings.hiddenPreparation[item])
        end
    end
end

local function Check(parent, x, y, callback)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x, -y)
    check.label = Text(check, "GameFontHighlightSmall", 28, -6, 164)
    check:SetScript("OnClick", callback)
    return check
end

local function CreateSettings()
    local spellY = 322
    local prepY = spellY + math.ceil(addon.maxSpells / 2) * 24 + 12
    local footerY = prepY + 20 + math.ceil(addon.maxPreparation / 2) * 24 + 18
    settingsPanel = CreateFrame("Frame", "MyPalladinSettings", UIParent, "BackdropTemplate")
    settingsPanel:Hide()
    settingsPanel:SetSize(420, footerY + 36)
    settingsPanel:SetPoint("CENTER")
    settingsPanel:SetClampedToScreen(true)
    settingsPanel:EnableMouse(true)
    settingsPanel:SetFrameStrata("DIALOG")
    settingsPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    settingsPanel:SetBackdropColor(0.06, 0.06, 0.07, 0.98)
    settingsPanel:SetBackdropBorderColor(0.65, 0.48, 0.22, 1)
    Text(settingsPanel, "GameFontNormalLarge", 16, -14, 350):SetText("My Paladin Settings")
    local close = CreateFrame("Button", nil, settingsPanel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    for index, id in ipairs(addon.profileOrder) do
        local button = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
        button:SetSize(122, 26)
        button:SetPoint("TOPLEFT", 16 + (index - 1) * 132, -42)
        button:SetText(addon.profiles[id].name)
        button:SetScript("OnClick", function() ChooseProfile(id) end)
        settingsButtons[id] = button
    end
    settingsHeading = Text(settingsPanel, "GameFontNormal", 16, -80, 388)
    local options = {
        { "compact", "Compact panel" },
        { "buffWarnings", "Highlight missing buffs" },
        { "manaWarning", "Warn low mana below" },
        { "showPreparation", "Show preparation when expanded" },
        { "crusaderOpener", "Crusader opener (long fights)" },
        { "echoGuidance", "Unsealed Wrath echoes" },
    }
    for index, option in ipairs(options) do
        local key = option[1]
        local check = Check(settingsPanel, 16, 104 + (index - 1) * 26, function(self)
            addon.GetSettings()[key] = self:GetChecked()
            RefreshProfile()
        end)
        check.label:SetWidth(360)
        check.label:SetText(option[2])
        settingsChecks[key] = check
    end
    thresholdLabel = Text(settingsPanel, "GameFontHighlightSmall", 292, -163, 50)
    for _, delta in ipairs({ -5, 5 }) do
        local button = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
        button:SetSize(28, 22)
        button:SetPoint("TOPLEFT", delta < 0 and 252 or 350, -156)
        button:SetText(delta < 0 and "-" or "+")
        button:SetScript("OnClick", function()
            local settings = addon.GetSettings()
            settings.manaThreshold = math.max(0, math.min(100, settings.manaThreshold + delta))
            RefreshProfile()
        end)
        if delta < 0 then thresholdMinus = button else thresholdPlus = button end
    end
    for index, group in ipairs(addon.buffGroups) do
        if group.setting then
            local button = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
            button:SetSize(190, 22)
            button:SetPoint("TOPLEFT", 16 + (index - 2) * 200, -268)
            button:SetScript("OnClick", function()
                local settings = addon.GetSettings()
                local selected = settings[group.setting]
                local nextName = group.spells[1]
                for position, name in ipairs(group.spells) do
                    if name == selected then nextName = group.spells[position + 1] or "any" end
                end
                settings[group.setting] = nextName
                RefreshProfile()
            end)
            assignmentButtons[group.setting] = button
        end
    end
    Text(settingsPanel, "GameFontNormal", 16, -spellY + 22, 388):SetText("Cooldowns (learned abilities only)")
    for index = 1, addon.maxSpells do
        spellChecks[index] = Check(settingsPanel, 16 + ((index - 1) % 2) * 200, spellY + math.floor((index - 1) / 2) * 24, function(self)
            addon.GetSettings().hiddenSpells[addon.GetProfile().spells[index]] = not self:GetChecked()
            RefreshProfile()
        end)
    end
    Text(settingsPanel, "GameFontNormal", 16, -prepY, 388):SetText("Preparation reminders")
    for index = 1, addon.maxPreparation do
        preparationChecks[index] = Check(settingsPanel, 16 + ((index - 1) % 2) * 200, prepY + 20 + math.floor((index - 1) / 2) * 24, function(self)
            addon.GetSettings().hiddenPreparation[addon.GetProfile().preparation[index]] = not self:GetChecked()
            RefreshProfile()
        end)
    end
    Text(settingsPanel, "GameFontDisableSmall", 16, -footerY, 388):SetText("Saved automatically for this character and profile.")
    settingsPanel:SetScript("OnShow", RefreshSettings)
end

local function CreatePanel()
    panel = CreateFrame("Frame", "MyPalladinPanel", UIParent, "BackdropTemplate")
    panel:SetPoint("CENTER")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(true)
    end)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    panel:SetBackdropColor(0.06, 0.06, 0.07, 0.95)
    panel:SetBackdropBorderColor(0.65, 0.48, 0.22, 1)
    Text(panel, "GameFontNormalLarge", 16, -14, 350):SetText("My Paladin")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    mode = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    mode:SetSize(76, 22)
    mode:SetPoint("TOPRIGHT", -38, -10)
    mode:SetScript("OnClick", ToggleCompact)
    local settingsButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    settingsButton:SetSize(76, 22)
    settingsButton:SetPoint("TOPRIGHT", -122, -10)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function() settingsPanel:SetShown(not settingsPanel:IsShown()) end)

    for index, id in ipairs(addon.profileOrder) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(122, 26)
        button:SetPoint("TOPLEFT", 16 + (index - 1) * 132, -42)
        button:SetText(addon.profiles[id].name)
        button:SetScript("OnClick", function() ChooseProfile(id) end)
        buttons[id] = button
    end
    heading = Text(panel, "GameFontNormal", 16, -80, 388)
    focus = Text(panel, "GameFontHighlight", 16, -104, 388)
    focus:SetHeight(42)
    focus:SetJustifyV("TOP")
    for index = 1, #addon.buffGroups do
        buffLabels[index] = Text(panel, "GameFontHighlightSmall", 16, -152, 124)
        buffLabels[index]:SetHeight(30)
        buffLabels[index]:SetJustifyV("TOP")
    end
    sealAlert = CreateFrame("Frame", "MyPalladinSealAlert", UIParent)
    sealAlert:Hide()
    sealAlert:SetSize(300, 64)
    sealAlert:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    sealAlert:SetFrameStrata("HIGH")
    sealAlert:SetClampedToScreen(true)
    sealAlert:SetMovable(true)
    sealAlert:RegisterForDrag("LeftButton")
    sealAlert:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    sealAlert:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(true)
    end)
    sealAlert.icon = sealAlert:CreateTexture(nil, "ARTWORK")
    sealAlert.icon:SetPoint("TOPLEFT", 0, -4)
    sealAlert.icon:SetSize(48, 48)
    sealTitle = Text(sealAlert, "GameFontNormalLarge", 60, 0, 240)
    sealName = Text(sealAlert, "GameFontHighlight", 60, -22, 240)
    sealHelp = Text(sealAlert, "GameFontHighlightSmall", 60, -42, 240)
    mana = CreateFrame("StatusBar", nil, panel)
    mana:SetPoint("TOPLEFT", 16, -152)
    mana:SetSize(388, 18)
    mana:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    mana:SetStatusBarColor(0.12, 0.4, 0.9)
    local background = mana:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.1, 0.1, 0.15, 1)
    manaLabel = mana:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    manaLabel:SetPoint("CENTER")
    manaLabel:SetText("Mana")

    for index = 1, addon.maxSpells do
        local card = CreateFrame("Frame", nil, panel)
        card:SetSize(190, 44)
        card:SetPoint("TOPLEFT", 16 + ((index - 1) % 2) * 200, -186 - math.floor((index - 1) / 2) * 50)
        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetPoint("TOPLEFT")
        card.icon:SetSize(32, 32)
        card.cooldown = CreateFrame("Cooldown", nil, card, "CooldownFrameTemplate")
        card.cooldown:SetAllPoints(card.icon)
        card.label = Text(card, "GameFontHighlightSmall", 38, 0, 150)
        card.label:SetHeight(26)
        card.label:SetJustifyV("TOP")
        card.status = Text(card, "GameFontDisableSmall", 38, -28, 150)
        card:EnableMouse(true)
        card:SetScript("OnEnter", function(self)
            if self.spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self.spellID)
                GameTooltip:Show()
            end
        end)
        card:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cards[index] = card
    end
    preparation = Text(panel, "GameFontHighlightSmall", 16, -394, 388)
    preparation:SetHeight(44)
    preparation:SetJustifyV("TOP")
    empty = Text(panel, "GameFontHighlightSmall", 16, -186, 388)
    empty:SetText("No cooldowns shown. Check Settings or train abilities.")
    footer = Text(panel, "GameFontDisableSmall", 16, -450, 388)
    reference = Text(panel, "GameFontDisableSmall", 16, -482, 388)
    reference:SetText("Guide reviewed: " .. addon.guideInfo.reviewedOn .. " | Patch " .. addon.guideInfo.patch)
    CreateSettings()
    panel:SetScript("OnShow", RefreshProfile)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, unit)
    if event == "ADDON_LOADED" then
        if unit ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        local _, class = UnitClass("player")
        if class ~= "PALADIN" then return end
        if select(4, GetBuildInfo()) ~= 16001 or not GetLocale():match("^en") then
            Say("This version targets WoW Forever 1.60.1 with an English client.")
            return
        end
        if not C_Spell or not C_SpellBook or not C_SpellBook.FindSpellBookSlotForSpell
            or not C_SpellBook.GetSpellBookItemInfo then
            Say("Required spellbook APIs are unavailable on this client.")
            return
        end
        MyPalladinDB = addon.Initialize(MyPalladinDB)
        CreatePanel()
        SLASH_MYPALLADIN1 = "/mp"
        SlashCmdList.MYPALLADIN = function(message)
            message = message:match("^%s*(.-)%s*$"):lower()
            if message == "" then
                panel:SetShown(not panel:IsShown())
            elseif message == "compact" then
                ToggleCompact()
                panel:Show()
            elseif message == "settings" then
                settingsPanel:SetShown(not settingsPanel:IsShown())
            elseif message == "opener" then
                local settings = addon.GetSettings()
                settings.crusaderOpener = not settings.crusaderOpener
                RefreshProfile()
                Say("Crusader opener: " .. (settings.crusaderOpener and "enabled" or "disabled") .. " for " .. addon.GetProfile().name)
            elseif message == "echoes" then
                local settings = addon.GetSettings()
                settings.echoGuidance = not settings.echoGuidance
                RefreshProfile()
                Say("Echo guidance: " .. (settings.echoGuidance and "enabled" or "disabled") .. " for " .. addon.GetProfile().name)
            else
                ChooseProfile(message)
            end
        end
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("SPELLS_CHANGED")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterUnitEvent("UNIT_AURA", "player", "target")
        self:RegisterUnitEvent("UNIT_HEALTH", "target")
        self:RegisterUnitEvent("UNIT_FLAGS", "target")
        self:RegisterUnitEvent("UNIT_FACTION", "target")
        self:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        RefreshProfile()
        Say("Active profile: " .. addon.GetProfile().name .. ". Use /mp to open or close.")
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        if panel:IsShown() then UpdateMana() end
    elseif event == "UNIT_AURA" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_HEALTH"
        or event == "UNIT_FLAGS" or event == "UNIT_FACTION" then
        UpdateBuffs()
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if panel:IsShown() then UpdateCooldowns() end
    else
        RefreshProfile()
    end
end)
