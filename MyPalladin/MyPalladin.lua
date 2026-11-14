local addonName, addon = ...
local panel, heading, focus, preparation, mana
local cards, buttons = {}, {}

local function Say(message)
    print("|cffffca65My Palladin:|r " .. message)
end

local function UpdateMana()
    -- Forward combat values to native widgets without calculating or comparing them.
    mana:SetMinMaxValues(0, UnitPowerMax("player", 0))
    mana:SetValue(UnitPower("player", 0))
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
    local profile = addon.GetProfile()
    heading:SetText("Active profile: " .. profile.name .. "  |  Level " .. UnitLevel("player"))
    focus:SetText(profile.focus)
    preparation:SetText(profile.preparation)
    for id, button in pairs(buttons) do
        if id == addon.db.activeProfile then
            button:Disable()
        else
            button:Enable()
        end
    end
    for index, name in ipairs(profile.spells) do
        local card = cards[index]
        local slot, bank = C_SpellBook.FindSpellBookSlotForSpell(name)
        local info = slot and C_SpellBook.GetSpellBookItemInfo(slot, bank)
        card.spellID = info and info.spellID
        card.label:SetText(name)
        card.icon:SetTexture(info and info.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
        card.icon:SetDesaturated(not card.spellID)
        card.cooldown:Clear()
        card.status:SetText(card.spellID and "" or "Not learned")
    end
    UpdateCooldowns()
    UpdateMana()
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

local function CreatePanel()
    panel = CreateFrame("Frame", "MyPalladinPanel", UIParent, "BackdropTemplate")
    panel:SetSize(420, 510)
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
    mana = CreateFrame("StatusBar", nil, panel)
    mana:SetPoint("TOPLEFT", 16, -152)
    mana:SetSize(388, 18)
    mana:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    mana:SetStatusBarColor(0.12, 0.4, 0.9)
    local background = mana:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.1, 0.1, 0.15, 1)
    local manaLabel = mana:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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
    Text(panel, "GameFontDisableSmall", 16, -450, 388):SetText("Cooldowns only; choose your actions. Drag to move. /mp to toggle.")
    Text(panel, "GameFontDisableSmall", 16, -482, 388):SetText("Guide reviewed: " .. addon.guideInfo.reviewedOn .. " | Patch " .. addon.guideInfo.patch)
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
            else
                ChooseProfile(message)
            end
        end
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("SPELLS_CHANGED")
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        self:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        RefreshProfile()
        Say("Active profile: " .. addon.GetProfile().name .. ". Use /mp to open or close.")
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        if panel:IsShown() then UpdateMana() end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if panel:IsShown() then UpdateCooldowns() end
    else
        RefreshProfile()
    end
end)
