local _, addon = ...

local function Check(name, state, detail)
    if addon.TraceState then addon.TraceState("api_" .. name, state, { detail = detail }) end
end

function addon.GetLearnedSpell(name)
    local slot, bank = C_SpellBook.FindSpellBookSlotForSpell(name)
    local info = slot and C_SpellBook.GetSpellBookItemInfo(slot, bank)
    return info and info.spellID and info or nil
end

local function WeaponInfo()
    if not GetInventoryItemID or not C_Item or not C_Item.GetItemInfoInstant or not issecretvalue then
        Check("weapon", "api_missing", "GetInventoryItemID/C_Item.GetItemInfoInstant/issecretvalue")
        return nil
    end
    local itemID = GetInventoryItemID("player", 16)
    if issecretvalue(itemID) then Check("weapon", "restricted", "GetInventoryItemID returned a secret"); return nil end
    if not itemID then return "UNARMED" end
    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
    if issecretvalue(equipLoc) then Check("weapon", "restricted", "C_Item.GetItemInfoInstant equipLoc is secret"); return nil end
    Check("weapon", "public", "Equipment metadata accessible; checked outside combat")
    if equipLoc ~= "INVTYPE_2HWEAPON" then return equipLoc end
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then
        Check("weapon_speed", "api_missing", "C_TooltipInfo.GetInventoryItem")
        return equipLoc
    end
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
    Check("weapon_speed", ok and speed and "public" or (ok and "unavailable" or "call_failed"),
        "C_TooltipInfo.GetInventoryItem; English base-speed extraction")
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
        Check("weapon", "not_checked", "Equipment check deferred until after combat by addon policy")
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
        Check("auras", "api_missing", "C_UnitAuras.GetAuraDataBySpellName/C_Secrets.ShouldSpellAuraBeSecret/issecretvalue")
        return "unavailable"
    end
    local restricted, unavailable = false, false
    for _, name in ipairs(group.spells) do
        local probe = "aura_" .. name:gsub("%W", "_")
        local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, name)
        if not ok or issecretvalue(secret) or type(secret) ~= "boolean" then
            Check(probe, not ok and "call_failed" or (issecretvalue(secret) and "restricted" or "invalid"),
                "C_Secrets.ShouldSpellAuraBeSecret; aura query skipped")
            unavailable = true
        elseif secret then
            Check(probe, "restricted", "C_Secrets.ShouldSpellAuraBeSecret=true; aura query skipped")
            restricted = true
        else
            local success, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit or "player", name, filter or "HELPFUL")
            if not success then
                Check(probe, "call_failed", "C_UnitAuras.GetAuraDataBySpellName")
                unavailable = true
            elseif issecretvalue(aura) then
                Check(probe, "restricted", "C_UnitAuras.GetAuraDataBySpellName returned a secret")
                restricted = true
            elseif aura ~= nil and type(aura) ~= "table" then
                Check(probe, "invalid", "C_UnitAuras.GetAuraDataBySpellName unexpected return type")
                unavailable = true
            elseif aura then
                Check(probe, "present", "Aura presence public; fields not inspected")
                -- Presence is sufficient; never inspect the returned aura's fields.
                local displayName = name:gsub("^Seal of ", ""):gsub("^Blessing of ", ""):gsub(" Aura$", "")
                return "active", displayName, name, aura
            else
                Check(probe, "missing", "Public aura query returned nil; aura absent")
            end
        end
    end
    if restricted then return "restricted" end
    if unavailable then return "unavailable" end
    return "missing"
end

function addon.GetProfileBuffStatus(group)
    local selected = group.setting and addon.GetSettings()[group.setting]
    if not selected or selected == "any" then return addon.GetBuffStatus(group) end
    local status, name, spellName, aura = addon.GetBuffStatus({ spells = { selected } })
    if status == "missing" then
        name = selected:gsub("^Blessing of ", ""):gsub(" Aura$", "")
        if not addon.GetLearnedSpell(selected) then status = "unlearned" end
    end
    return status, name, spellName, aura
end

function addon.GetPreparationReminder()
    if InCombatLockdown() then return nil end
    for _, group in ipairs(addon.buffGroups) do
        if group.setting then
            local selected = addon.GetSettings()[group.setting]
            if selected ~= "any" and addon.GetProfileBuffStatus(group) == "missing" then
                return addon.GetLearnedSpell(selected), selected, group.label
            end
        end
    end
end

local function TargetStatus()
    if not UnitExists or not UnitCanAttack or not UnitIsDeadOrGhost or not UnitIsVisible or not issecretvalue then
        Check("target", "api_missing", "UnitExists/UnitCanAttack/UnitIsDeadOrGhost/UnitIsVisible/issecretvalue")
        return "unavailable"
    end
    local ok, exists, hostile, dead, visible = pcall(function()
        return UnitExists("target"), UnitCanAttack("player", "target"), UnitIsDeadOrGhost("target"), UnitIsVisible("target")
    end)
    if not ok then Check("target", "call_failed", "Target existence/hostility/death/visibility query"); return "unavailable" end
    local flags = { exists, hostile, dead, visible }
    local names = { "UnitExists", "UnitCanAttack", "UnitIsDeadOrGhost", "UnitIsVisible" }
    for index = 1, 4 do
        if issecretvalue(flags[index]) then Check("target", "restricted", names[index] .. " returned a secret"); return "restricted" end
        if type(flags[index]) ~= "boolean" then Check("target", "invalid", names[index] .. " unexpected return type"); return "unavailable" end
    end
    Check("target", "public", "Target existence/hostility/death/visibility flags accessible")
    if not exists or not hostile or dead or not visible then return "none" end
    return "valid"
end

function addon.GetCrusaderStep(sealStatus, activeSeal)
    if not addon.GetSettings().crusaderOpener then return nil end
    local crusader = addon.GetLearnedSpell("Seal of the Crusader")
    local judgement = addon.GetLearnedSpell("Judgement")
    if not crusader or not judgement or addon.GetLearnedSpell("Holy Shock") then return nil end
    local target = TargetStatus()
    if target == "none" then return nil end
    if target ~= "valid" then return target, crusader end
    if sealStatus ~= "active" and sealStatus ~= "missing" then return sealStatus, crusader end
    local debuff = addon.GetBuffStatus({ spells = { "Judgement of the Crusader" } }, "target", "HARMFUL|PLAYER")
    if debuff == "restricted" or debuff == "unavailable" then return debuff, crusader end
    local crusaderActive = sealStatus == "active" and activeSeal == "Seal of the Crusader"
    if debuff == "missing" then
        return crusaderActive and "judge" or "apply", crusaderActive and judgement or crusader
    end
    if crusaderActive then return "damage" end
end

function addon.GetEchoCount()
    local status, _, _, aura = addon.GetBuffStatus({ spells = { "Echo of Command" } })
    if status == "missing" then
        Check("echo_fields", "not_checked", "Echo aura absent; no fields to read")
        return "known", 0
    end
    if status ~= "active" then
        Check("echo_fields", "not_checked", "Echo aura inaccessible; fields not queried")
        return status
    end
    if type(aura) ~= "table" then Check("echo_fields", "invalid", "Echo aura is not a table"); return "unavailable" end
    local ok, spellID, count = pcall(function() return aura.spellId, aura.applications end)
    if not ok then Check("echo_fields", "call_failed", "Reading Echo of Command spellId/applications"); return "unavailable" end
    if issecretvalue(spellID) or issecretvalue(count) then
        Check("echo_fields", "restricted", issecretvalue(spellID) and "Echo of Command spellId is secret" or "Echo of Command applications is secret")
        return "restricted"
    end
    if spellID ~= 1311703 or type(count) ~= "number" or not (count >= 1 and count <= 3 and count % 1 == 0) then
        Check("echo_fields", "invalid", "Echo of Command spellId/applications do not match expected metadata")
        return "unavailable"
    end
    Check("echo_fields", "public", "Echo of Command spellId/applications accessible and valid")
    return "known", count
end

function addon.GetEchoStep(sealStatus, activeSeal, primarySeal)
    if not addon.GetSettings().echoGuidance or not InCombatLockdown() or primarySeal ~= "Seal of Command" then return nil end
    local learned = addon.GetLearnedSpell("Unsealed Wrath")
    if not learned and C_SpellBook.IsSpellKnown and issecretvalue then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, 1310735)
        Check("talent", not ok and "call_failed" or (issecretvalue(known) and "restricted"
            or type(known) == "boolean" and "public" or "invalid"), "C_SpellBook.IsSpellKnown(Unsealed Wrath)")
        learned = ok and not issecretvalue(known) and known == true
    end
    if not learned or addon.GetLearnedSpell("Holy Shock") then return nil end
    local command = addon.GetLearnedSpell("Seal of Command")
    local righteousness = addon.GetLearnedSpell("Seal of Righteousness")
    if not command or not righteousness or sealStatus == "missing" then return nil end
    if sealStatus == "active" and activeSeal ~= "Seal of Command" and activeSeal ~= "Seal of Righteousness" then return nil end
    local target = TargetStatus()
    if target == "none" then return nil end
    if target ~= "valid" then return target, command end
    if sealStatus ~= "active" then return sealStatus, command end
    local status, count = addon.GetEchoCount()
    if status ~= "known" then return status, command end
    if activeSeal == "Seal of Command" then
        if count >= 2 then return "swap", righteousness, count end
        return "build", command, count
    end
    if count > 0 then return "wait", righteousness, count end
    return "return", command, count
end

function addon.GetCombatHint(only)
    local settings = addon.GetSettings()
    if not settings.combatHints or not InCombatLockdown() then return nil end
    local coreName = "Judgement"
    local core = addon.GetLearnedSpell(coreName)
    if not core then coreName, core = "Holy Strike", addon.GetLearnedSpell("Holy Strike") end
    local target = TargetStatus()
    if target == "none" then return nil end
    if target ~= "valid" then return core, coreName, "Target status " .. target, true end
    local uncertain = false
    local hammer = (not only or only == "Hammer of Wrath") and addon.GetLearnedSpell("Hammer of Wrath")
    if hammer then
        local ok, current, maximum = pcall(function() return UnitHealth("target"), UnitHealthMax("target") end)
        if ok and not issecretvalue(current) and not issecretvalue(maximum)
            and type(current) == "number" and type(maximum) == "number"
            and current >= 0 and maximum > 0 and current <= maximum and maximum < math.huge then
            Check("target_health", "public", "UnitHealth/UnitHealthMax accessible and valid")
            if current == 0 then return nil end
            if current / maximum < 0.2 then return hammer, "Hammer of Wrath", "Target below 20% | Use when ready", false end
        else
            if not UnitHealth or not UnitHealthMax then
                Check("target_health", "api_missing", "UnitHealth/UnitHealthMax")
            elseif not ok then Check("target_health", "call_failed", "UnitHealth/UnitHealthMax")
            elseif issecretvalue(current) or issecretvalue(maximum) then
                Check("target_health", "restricted", issecretvalue(current) and "UnitHealth returned a secret" or "UnitHealthMax returned a secret")
            else
                Check("target_health", "invalid", "UnitHealth/UnitHealthMax unexpected numeric values")
            end
            uncertain = true
        end
    elseif not only or only == "Hammer of Wrath" then
        Check("target_health", "not_checked", "Hammer of Wrath not learned; no health query needed")
    end
    local consecration = (not only or only == "Consecration") and settings.combatMode == "aoe" and addon.GetLearnedSpell("Consecration")
    if consecration then
        local ok, current, maximum = pcall(function() return UnitPower("player", 0), UnitPowerMax("player", 0) end)
        if not ok then
            Check("mana", UnitPower and UnitPowerMax and "call_failed" or "api_missing", "UnitPower/UnitPowerMax")
            return consecration, "Consecration", "Check mana before area damage", true
        end
        local _, low, readable = addon.GetManaText(current, maximum, settings)
        if not readable then return consecration, "Consecration", "Check mana before area damage", true end
        if low then return consecration, "Consecration", "Low mana | Limit Consecration", false end
        return consecration, "Consecration", "Area damage when mana permits", false
    end
    local exorcism = (not only or only == "Exorcism") and addon.GetLearnedSpell("Exorcism")
    if exorcism then
        local ok, creature = pcall(function() return UnitCreatureType("target") end)
        if ok and not issecretvalue(creature) and type(creature) == "string" then
            Check("target_type", "public", "UnitCreatureType accessible")
            if creature == "Undead" or creature == "Demon" then
                return exorcism, "Exorcism", "Undead/Demon target | Use when ready", false
            end
        else
            Check("target_type", not UnitCreatureType and "api_missing" or (not ok and "call_failed"
                or issecretvalue(creature) and "restricted" or "invalid"), "UnitCreatureType")
            uncertain = true
        end
    elseif not only or only == "Exorcism" then
        Check("target_type", "not_checked", "Exorcism not learned; no creature-type query needed")
    end
    if not only then
        return core, coreName, uncertain and "Check target conditions | Core damage macro" or "Core damage: Judgement / Holy Strike", uncertain
    end
end

function addon.GetSpellReadiness(info, name, area, selfCast)
    local probe = "readiness_" .. name:gsub("%W", "_")
    local readyDetail = selfCast and "Usability and self-cast cooldown checked" or "Usability, range and cooldown checked"
    local function Result(state, detail, remaining)
        Check(probe, state, detail)
        return state, detail, remaining
    end
    if not issecretvalue or not C_Spell or not C_Spell.IsSpellUsable or not C_Spell.GetSpellCooldown
        or (not selfCast and not C_Spell.IsSpellInRange) then
        return Result("api_missing", "Spell usability/cooldown/range API unavailable")
    end
    local ok, usable, noMana = pcall(C_Spell.IsSpellUsable, info.spellID)
    if not ok then return Result("call_failed", "C_Spell.IsSpellUsable") end
    if issecretvalue(usable) then return Result("restricted", "Spell usability protected") end
    if type(usable) ~= "boolean" then return Result("invalid", "Invalid spell usability") end
    if not usable then
        if issecretvalue(noMana) then return Result("restricted", "Spell resource condition protected") end
        if noMana == true then return Result("no_mana", "Not enough mana") end
        return Result("unusable", "Spell currently unusable")
    end
    if not selfCast then
        local rangeSpell = area and addon.GetLearnedSpell("Holy Strike") or info
        if not rangeSpell then return Result("unavailable", "Melee range check unavailable") end
        local success, inRange = pcall(C_Spell.IsSpellInRange, rangeSpell.spellID, "target")
        if not success then return Result("call_failed", "C_Spell.IsSpellInRange") end
        if issecretvalue(inRange) then return Result("restricted", "Spell range protected") end
        if inRange == false then return Result("out_of_range", "Move into range") end
        if inRange ~= true then return Result("unavailable", "Spell range unavailable") end
    end
    local success, cooldown = pcall(C_Spell.GetSpellCooldown, info.spellID)
    if not success then return Result("call_failed", "C_Spell.GetSpellCooldown") end
    if issecretvalue(cooldown) then return Result("restricted", "Cooldown table protected") end
    if type(cooldown) ~= "table" then return Result("unavailable", "Cooldown unavailable") end
    local flagsOK, enabled, active = pcall(function() return cooldown.isEnabled, cooldown.isActive end)
    if not flagsOK then return Result("call_failed", "Reading cooldown flags") end
    if issecretvalue(enabled) then return Result("restricted", "Cooldown isEnabled protected") end
    if type(enabled) ~= "boolean" then return Result("invalid", "Invalid cooldown isEnabled") end
    if not enabled then return Result("unusable", "Cooldown on hold") end
    local activityKnown = not issecretvalue(active) and type(active) == "boolean"
    Check("cooldown_activity_" .. name:gsub("%W", "_"), activityKnown and "public"
        or (issecretvalue(active) and "restricted" or "unavailable"), "C_Spell.GetSpellCooldown isActive flag")
    if activityKnown and not active then return Result("ready", readyDetail) end
    local function TimingUnavailable(state, detail)
        Check("cooldown_timing_" .. name:gsub("%W", "_"), state, detail)
        if activityKnown then return Result("cooldown", "Cooldown active; timing unavailable") end
        return Result(state, detail)
    end
    local fieldsOK, start, duration, rate = pcall(function()
        return cooldown.startTime, cooldown.duration, cooldown.modRate
    end)
    if not fieldsOK then return TimingUnavailable("call_failed", "Reading cooldown timing fields") end
    local fields = {startTime = start, duration = duration, modRate = rate}
    for _, field in ipairs({"startTime", "duration", "modRate"}) do
        if issecretvalue(fields[field]) then return TimingUnavailable("restricted", "Cooldown " .. field .. " protected") end
    end
    if type(start) ~= "number" or not (start >= 0 and start < math.huge)
        or type(duration) ~= "number" or not (duration >= 0 and duration < math.huge)
        or type(rate) ~= "number" or not (rate > 0 and rate < math.huge) then
        return TimingUnavailable("invalid", "Invalid cooldown fields")
    end
    local remaining = start == 0 and 0 or math.max(0, start + duration / rate - GetTime())
    if remaining == math.huge then return TimingUnavailable("invalid", "Cooldown calculation out of range") end
    if remaining > 0 then return Result("cooldown", "Wait for cooldown", remaining) end
    if activityKnown then return Result("cooldown", "Cooldown active; native flag not cleared") end
    return Result("ready", readyDetail)
end

function addon.GetCombatAction(exclude)
    local settings = addon.GetSettings()
    if not settings.combatHints or addon.combatPlayerDead or not InCombatLockdown() or TargetStatus() ~= "valid" then return nil end
    if addon.GetCombatCast then
        local busy, info, name = addon.GetCombatCast()
        if busy then return info, name, "Finish your current cast", true, "casting" end
    end
    -- Forever guide priority; seal/echo decisions remain in their separate HUD.
    local priority = { "Judgement", "Consecration", "Hammer of Wrath", "Holy Strike", "Exorcism" }
    local unknown, waiting, blocked
    if addon.GetSealAction then
        local info, name, reason, confidence, selfCast = addon.GetSealAction()
        if info and info.spellID ~= exclude then
            local state, detail = addon.GetSpellReadiness(info, name, false, selfCast)
            if state == "ready" then
                return info, name, reason, confidence == "estimated", confidence == "estimated" and "estimated" or "ready"
            end
            blocked = {info, name, detail, true, "check"}
        end
    end
    for _, name in ipairs(priority) do
        local info = addon.GetLearnedSpell(name)
        local eligible = name == "Judgement" or name == "Holy Strike"
        if info and name == "Consecration" and settings.combatMode == "aoe" then
            -- The client's usability flag checks the cast cost even when raw mana is secret.
            local ok, current, maximum = pcall(function() return UnitPower("player", 0), UnitPowerMax("player", 0) end)
            local _, low
            if ok then _, low = addon.GetManaText(current, maximum, settings) end
            eligible = not low
        elseif info and not eligible then
            local candidate, _, _, uncertain = addon.GetCombatHint(name)
            eligible = candidate ~= nil and not uncertain
        end
        if info and info.spellID ~= exclude and eligible then
            local state, detail, remaining = addon.GetSpellReadiness(info, name, name == "Consecration")
            if state == "ready" then return info, name, "Use now | " .. detail, false, "ready" end
            local candidate = { info, name, detail, true, "check" }
            if state == "cooldown" and remaining then
                candidate[3], candidate[4], candidate[5], candidate[6] = string.format("Ready in %.1fs", remaining), false, "wait", remaining
                if not waiting or not waiting[6] or remaining < waiting[6] then waiting = candidate end
            elseif state == "cooldown" then
                candidate[4], candidate[5] = false, "wait"
                waiting = waiting or candidate
            elseif state == "restricted" or state == "api_missing" or state == "unavailable" or state == "invalid" or state == "call_failed" then
                unknown = unknown or candidate
            else
                blocked = blocked or candidate
            end
        end
    end
    local candidate = unknown or blocked or waiting
    if candidate then return unpack(candidate, 1, 5) end
end

function addon.GetManaText(current, maximum, settings)
    if not issecretvalue or issecretvalue(current) or issecretvalue(maximum) then
        Check("mana", not issecretvalue and "api_missing" or "restricted", "UnitPower/UnitPowerMax; native bar still receives opaque values")
        return "Mana", false
    end
    if type(current) ~= "number" or type(maximum) ~= "number"
        or not (current >= 0 and maximum > 0 and current <= maximum and maximum < math.huge) then
        Check("mana", "invalid", "UnitPower/UnitPowerMax unexpected numeric values")
        return "Mana unavailable", false
    end
    Check("mana", "public", "UnitPower/UnitPowerMax accessible and valid")
    local percent = math.floor(current / maximum * 100 + 0.5)
    local low = settings.manaWarning and current / maximum < settings.manaThreshold / 100
    return (low and "Low mana: " or "Mana: ") .. percent .. "%", low, true
end
