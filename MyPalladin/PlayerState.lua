local _, addon = ...

addon.buffGroups = {
    { label = "Seal", spells = {
        "Seal of Righteousness", "Seal of Command", "Seal of the Crusader", "Seal of Fury",
        "Seal of Light", "Seal of Wisdom", "Seal of Justice",
    } },
    { label = "Blessing", spells = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings" } },
    { label = "Aura", spells = {
        "Devotion Aura", "Retribution Aura", "Concentration Aura",
        "Shadow Resistance Aura", "Frost Resistance Aura", "Fire Resistance Aura",
    } },
}

function addon.GetLearnedSpell(name)
    local slot, bank = C_SpellBook.FindSpellBookSlotForSpell(name)
    local info = slot and C_SpellBook.GetSpellBookItemInfo(slot, bank)
    return info and info.spellID and info or nil
end

local function WeaponInfo()
    if not GetInventoryItemID or not C_Item or not C_Item.GetItemInfoInstant or not issecretvalue then
        return nil
    end
    local itemID = GetInventoryItemID("player", 16)
    if issecretvalue(itemID) then return nil end
    if not itemID then return "UNARMED" end
    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
    if issecretvalue(equipLoc) then return nil end
    if equipLoc ~= "INVTYPE_2HWEAPON" then return equipLoc end
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then return equipLoc end
    local ok, speed = pcall(function()
        local data = C_TooltipInfo.GetInventoryItem("player", 16)
        if issecretvalue(data) or not data or issecretvalue(data.lines) or not data.lines then return nil end
        for _, line in ipairs(data.lines) do
            if not issecretvalue(line) then
                local text = line.rightText
                if not issecretvalue(text) and type(text) == "string" then
                    -- shortcut: parse the English base-speed tooltip; use item metadata if Blizzard exposes it.
                    local value = tonumber(text:match("Speed%s+(%d+%.?%d*)"))
                    if value and value > 0 then return value end
                end
            end
        end
    end)
    return equipLoc, ok and speed or nil
end

function addon.GetRecommendedSeal()
    local righteousness = addon.GetLearnedSpell("Seal of Righteousness")
    local command = addon.GetLearnedSpell("Seal of Command")
    if not righteousness and not command then return nil, nil, "Learn a damage seal at your class trainer." end
    if not command then return righteousness, "Seal of Righteousness", "Command not learned" end
    if not righteousness then return command, "Seal of Command", "Only learned damage seal" end
    if addon.GetLearnedSpell("Holy Shock") then
        return righteousness, "Seal of Righteousness", "Holy Shock learned"
    end
    if InCombatLockdown() then
        return righteousness, "Seal of Righteousness", "Weapon check after combat"
    end
    local equipLoc, speed = WeaponInfo()
    if equipLoc == "INVTYPE_2HWEAPON" and speed then
        if speed >= 2.8 then
            return command, "Seal of Command", string.format("Slow two-handed weapon (%.2fs)", speed)
        end
        return righteousness, "Seal of Righteousness", string.format("Fast two-handed weapon (%.2fs)", speed)
    end
    if equipLoc == "UNARMED" then return righteousness, "Seal of Righteousness", "No weapon equipped" end
    if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" then
        return righteousness, "Seal of Righteousness", "One-handed weapon"
    end
    return righteousness, "Seal of Righteousness", "Weapon speed unavailable; Righteousness fallback"
end

function addon.GetBuffStatus(group, unit, filter)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataBySpellName or not C_Secrets
        or not C_Secrets.ShouldSpellAuraBeSecret or not issecretvalue then
        return "unavailable"
    end
    local restricted, unavailable = false, false
    for _, name in ipairs(group.spells) do
        local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, name)
        if not ok or issecretvalue(secret) or type(secret) ~= "boolean" then
            unavailable = true
        elseif secret then
            restricted = true
        else
            local success, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit or "player", name, filter or "HELPFUL")
            if not success then
                unavailable = true
            elseif issecretvalue(aura) then
                restricted = true
            elseif aura then
                -- Presence is sufficient; never inspect the returned aura's fields.
                local displayName = name:gsub("^Seal of ", ""):gsub("^Blessing of ", ""):gsub(" Aura$", "")
                return "active", displayName, name
            end
        end
    end
    if restricted then return "restricted" end
    if unavailable then return "unavailable" end
    return "missing"
end

function addon.GetCrusaderStep(sealStatus, activeSeal)
    if not addon.GetSettings().crusaderOpener then return nil end
    local crusader = addon.GetLearnedSpell("Seal of the Crusader")
    local judgement = addon.GetLearnedSpell("Judgement")
    if not crusader or not judgement or addon.GetLearnedSpell("Holy Shock") then return nil end
    if not UnitExists or not UnitCanAttack or not UnitIsDeadOrGhost or not UnitIsVisible or not issecretvalue then
        return "unavailable", crusader
    end
    local ok, exists, hostile, dead, visible = pcall(function()
        return UnitExists("target"), UnitCanAttack("player", "target"), UnitIsDeadOrGhost("target"), UnitIsVisible("target")
    end)
    if not ok then return "unavailable", crusader end
    local flags = { exists, hostile, dead, visible }
    for index = 1, 4 do
        if issecretvalue(flags[index]) then return "restricted", crusader end
        if type(flags[index]) ~= "boolean" then return "unavailable", crusader end
    end
    if not exists or not hostile or dead or not visible then return nil end
    if sealStatus ~= "active" and sealStatus ~= "missing" then return sealStatus, crusader end
    local debuff = addon.GetBuffStatus({ spells = { "Judgement of the Crusader" } }, "target", "HARMFUL|PLAYER")
    if debuff == "restricted" or debuff == "unavailable" then return debuff, crusader end
    local crusaderActive = sealStatus == "active" and activeSeal == "Seal of the Crusader"
    if debuff == "missing" then
        return crusaderActive and "judge" or "apply", crusaderActive and judgement or crusader
    end
    if crusaderActive then return "damage" end
end

function addon.GetManaText(current, maximum, settings)
    if not issecretvalue or issecretvalue(current) or issecretvalue(maximum) then
        return "Mana", false
    end
    if type(current) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return "Mana unavailable", false
    end
    local percent = math.floor(current / maximum * 100 + 0.5)
    local low = settings.manaWarning and current / maximum < settings.manaThreshold / 100
    return (low and "Low mana: " or "Mana: ") .. percent .. "%", low
end
