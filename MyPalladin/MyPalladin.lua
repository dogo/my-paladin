local addonName, addon = ...
local panel, heading, focus, preparation, mana, manaLabel, mode, footer, reference, empty
local cards, buttons, buffLabels = {}, {}, {}
local learnedCount = 0
local Layout
local sealAction, sealName, sealHelp, recommendedSeal, sealReason
local settingsPanel, settingsHeading, thresholdLabel, thresholdMinus, thresholdPlus
local settingsChecks, spellChecks, preparationChecks, settingsButtons = {}, {}, {}, {}
local RefreshSettings

local function Say(message)
    print("|cffffca65My Palladin:|r " .. message)
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

local function UpdateBuffs()
    local warn = addon.GetSettings().buffWarnings
    for index, group in ipairs(addon.buffGroups) do
        local status, name = addon.GetBuffStatus(group)
        local label = buffLabels[index]
        if status == "active" then
            label:SetText(group.label .. ": " .. name)
            label:SetTextColor(0.4, 1, 0.4)
        elseif status == "missing" then
            label:SetText(group.label .. ": Missing")
            if warn then label:SetTextColor(1, 0.5, 0.2) else label:SetTextColor(0.7, 0.7, 0.7) end
        else
            label:SetText(group.label .. (status == "restricted" and ": Restricted" or ": Unavailable"))
            label:SetTextColor(0.7, 0.7, 0.7)
        end
        if index == 1 and recommendedSeal then
            sealName:SetText((status == "missing" and warn and "Apply: " or "Base seal: ") .. recommendedSeal)
        end
    end
    if sealReason then
        sealHelp:SetText(sealReason .. "\n" .. (InCombatLockdown() and "Use your action bar during combat." or "Click the icon to apply."))
    end
end

local function UpdateSealAction()
    if InCombatLockdown() then return end
    local info, name, reason = addon.GetRecommendedSeal()
    recommendedSeal, sealReason = name, info and reason or nil
    sealAction:SetAttribute("useOnKeyDown", false)
    sealAction:SetAttribute("unit", "player")
    sealAction.spellID = info and info.spellID
    sealAction:SetAttribute("type1", info and "spell" or nil)
    sealAction:SetAttribute("spell", info and info.spellID or nil)
    sealAction.icon:SetTexture(info and info.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    sealName:SetText(name and "Base seal: " .. name or "No damage seal learned")
    sealHelp:SetText(reason or "Choose your seal after combat.")
    if info then sealAction:Enable() else sealAction:Disable() end
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
    UpdateSealAction()
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
    local sealY = buffY + 36
    local manaY = sealY + 54
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
    sealAction:ClearAllPoints()
    sealAction:SetPoint("TOPLEFT", 16, -sealY)
    sealName:ClearAllPoints()
    sealName:SetPoint("TOPLEFT", 60, -sealY)
    sealHelp:ClearAllPoints()
    sealHelp:SetPoint("TOPLEFT", 60, -sealY - 18)
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
    footer:SetText(compact and "Drag to move | /mp to toggle" or "Cooldowns and seal prep. Drag to move. /mp to toggle.")
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
    thresholdLabel:SetText(settings.manaThreshold .. "%")
    thresholdMinus:SetEnabled(settings.manaWarning and settings.manaThreshold > 0)
    thresholdPlus:SetEnabled(settings.manaWarning and settings.manaThreshold < 100)
    for index, check in ipairs(spellChecks) do
        local name = profile.spells[index]
        check.label:SetText(name)
        check:SetChecked(not settings.hiddenSpells[name])
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
    settingsPanel = CreateFrame("Frame", "MyPalladinSettings", UIParent, "BackdropTemplate")
    settingsPanel:Hide()
    settingsPanel:SetSize(420, 508)
    settingsPanel:SetPoint("CENTER")
    settingsPanel:SetClampedToScreen(true)
    settingsPanel:EnableMouse(true)
    settingsPanel:SetFrameStrata("DIALOG")
    settingsPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    settingsPanel:SetBackdropColor(0.06, 0.06, 0.07, 0.98)
    settingsPanel:SetBackdropBorderColor(0.65, 0.48, 0.22, 1)
    Text(settingsPanel, "GameFontNormalLarge", 16, -14, 350):SetText("My Palladin Settings")
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
    Text(settingsPanel, "GameFontNormal", 16, -216, 388):SetText("Cooldowns (learned abilities only)")
    for index = 1, 8 do
        spellChecks[index] = Check(settingsPanel, 16 + ((index - 1) % 2) * 200, 238 + math.floor((index - 1) / 2) * 24, function(self)
            addon.GetSettings().hiddenSpells[addon.GetProfile().spells[index]] = not self:GetChecked()
            RefreshProfile()
        end)
    end
    Text(settingsPanel, "GameFontNormal", 16, -346, 388):SetText("Preparation reminders")
    for index = 1, 5 do
        preparationChecks[index] = Check(settingsPanel, 16 + ((index - 1) % 2) * 200, 366 + math.floor((index - 1) / 2) * 24, function(self)
            addon.GetSettings().hiddenPreparation[addon.GetProfile().preparation[index]] = not self:GetChecked()
            RefreshProfile()
        end)
    end
    Text(settingsPanel, "GameFontDisableSmall", 16, -466, 388):SetText("Saved automatically for this character and profile.")
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
    Text(panel, "GameFontNormalLarge", 16, -14, 350):SetText("My Palladin")
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
    sealAction = CreateFrame("Button", "MyPalladinSealButton", panel, "InsecureActionButtonTemplate")
    sealAction:SetSize(36, 36)
    sealAction:RegisterForClicks("LeftButtonUp")
    sealAction:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    sealAction.icon = sealAction:CreateTexture(nil, "ARTWORK")
    sealAction.icon:SetAllPoints()
    sealAction.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    sealAction:Disable()
    sealAction:SetScript("OnEnter", function(self)
        if self.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:AddLine("Click to apply before combat. Use your action bar during combat.", 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    sealAction:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sealAction:SetScript("PostClick", function()
        if InCombatLockdown() then Say("Use the seal on your action bar during combat.") end
    end)
    sealName = Text(panel, "GameFontHighlight", 60, -188, 344)
    sealName:SetText("Seal recommendation after combat")
    sealHelp = Text(panel, "GameFontHighlightSmall", 60, -206, 344)
    sealHelp:SetText("Use your action bar during combat.")
    sealHelp:SetHeight(32)
    sealHelp:SetJustifyV("TOP")
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

    for index = 1, 8 do
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
        self:RegisterUnitEvent("UNIT_AURA", "player")
        self:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        RefreshProfile()
        Say("Active profile: " .. addon.GetProfile().name .. ". Use /mp to open or close.")
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        if panel:IsShown() then UpdateMana() end
    elseif event == "UNIT_AURA" then
        if panel:IsShown() then UpdateBuffs() end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if panel:IsShown() then UpdateCooldowns() end
    else
        RefreshProfile()
    end
end)
