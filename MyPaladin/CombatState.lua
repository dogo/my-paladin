local _, addon = ...
local seal, casting, judged
local readyAt = {}
local targetEpoch, spells, learnedNames = 0, {}, {}
local sealNames = {}
for _, name in ipairs(addon.buffGroups[1].spells) do sealNames[name] = true end
-- The game's Cooldown Manager keeps showing the player's auras in combat when addons can't read them.
-- Its buff viewers' items hold a cooldownID and, while the aura is up, an auraInstanceID (Blizzard_CooldownViewer).
local AURA_VIEWERS = { "BuffIconCooldownViewer", "BuffBarCooldownViewer" }
-- cooldownID -> {sealName = true}; Forever groups every seal in one "Seals" item, so a set, not a name.
local viewerSeals = {}
local MapViewerSeals, ViewerSeal

local function Public(value)
    return issecretvalue and not issecretvalue(value)
end

function addon.ResetCombatEvidence()
    seal, casting, judged = nil, nil, nil
    readyAt = {}
    targetEpoch = targetEpoch + 1
end

function addon.RebuildCombatSpells()
    spells = {}
    learnedNames = {}
    for _, profile in pairs(addon.profiles) do
        for _, name in ipairs(profile.spells) do
            local info = addon.GetLearnedSpell(name)
            if info then spells[info.spellID], learnedNames[name] = name, true end
        end
    end
    for name in pairs(sealNames) do
        local info = addon.GetLearnedSpell(name)
        if info then spells[info.spellID], learnedNames[name] = name, true end
    end
    local mapped = MapViewerSeals()
    if addon.TraceState then
        addon.TraceState("seal_viewer_map", mapped > 0 and "mapped" or "none", { count = mapped, detail = "Cooldown Manager seal items" })
    end
end

function MapViewerSeals()
    viewerSeals = {}
    local api = C_CooldownViewer
    if not api or not api.GetCooldownViewerCategorySet or not api.GetCooldownViewerCooldownInfo
        or not C_Spell or not C_Spell.GetSpellName then return 0 end
    local count = 0
    local function Note(cooldownID, spellID)
        if not Public(spellID) or type(spellID) ~= "number" then return end
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and Public(name) and sealNames[name] then
            if not viewerSeals[cooldownID] then viewerSeals[cooldownID], count = {}, count + 1 end
            viewerSeals[cooldownID][name] = true
        end
    end
    -- Every category: the player may move a seal to any bar, and the layout lives outside this API.
    for category = 0, 8 do
        local ok, ids = pcall(api.GetCooldownViewerCategorySet, category, false)
        if ok and Public(ids) and type(ids) == "table" then
            for _, cooldownID in ipairs(ids) do
                local okInfo, info = pcall(api.GetCooldownViewerCooldownInfo, cooldownID)
                if Public(cooldownID) and okInfo and Public(info) and type(info) == "table" then
                    Note(cooldownID, info.spellID)
                    Note(cooldownID, info.overrideSpellID)
                    if type(info.linkedSpellIDs) == "table" then
                        for _, linked in ipairs(info.linkedSpellIDs) do Note(cooldownID, linked) end
                    end
                end
            end
        end
    end
    return count
end

local function OnlyMember(members)
    local only
    for name in pairs(members) do
        if only then return nil end
        only = name
    end
    return only
end

-- Positive evidence only: a seal missing from the bars may simply not be tracked there.
-- Returns presence and, when the item tells it, which seal.
-- The third return explains a miss for diagnostics: no_map, viewer_hidden, item_absent or item_inactive.
function ViewerSeal()
    if not next(viewerSeals) then return nil, nil, "no_map" end
    local reason = "viewer_hidden"
    for _, viewerName in ipairs(AURA_VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer.IsShown and viewer.GetChildren and viewer:IsShown() then
            if reason == "viewer_hidden" then reason = "item_absent" end
            for _, item in ipairs({ viewer:GetChildren() }) do
                local cooldownID = rawget(item, "cooldownID")
                local members = Public(cooldownID) and viewerSeals[cooldownID]
                if members then reason = "item_inactive" end
                if members and item:IsShown() then
                    local aura = rawget(item, "auraInstanceID")
                    -- A secret ID is only tested for existence, never compared or read.
                    if not Public(aura) or aura ~= nil then
                        local name = OnlyMember(members)
                        local auraSpell = rawget(item, "auraSpellID")
                        if not name and Public(auraSpell) and type(auraSpell) == "number" and C_Spell and C_Spell.GetSpellName then
                            local ok, spellName = pcall(C_Spell.GetSpellName, auraSpell)
                            if ok and Public(spellName) and members[spellName] then name = spellName end
                        end
                        return true, name
                    end
                end
            end
        end
    end
    return nil, nil, reason
end

local function CastName(spellID)
    if not Public(spellID) or type(spellID) ~= "number" or spellID <= 0 then return nil end
    if spells[spellID] then return spells[spellID] end
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and Public(name) and type(name) == "string" and learnedNames[name] then
            spells[spellID] = name
            return name
        end
    end
end

function addon.RecordCombatCast(spellID)
    local name = CastName(spellID)
    if not name then return end
    readyAt[name] = nil
    if sealNames[name] then
        seal = { name = name, expires = GetTime() + 30, castAt = GetTime() }
        addon.Trace("estimate", "seal_cast", { spell = spellID, detail = name .. "; estimated 30s duration" })
    elseif name == "Judgement" and seal and seal.name == "Seal of the Crusader" and seal.expires and seal.expires > GetTime() then
        judged = { epoch = targetEpoch, expires = GetTime() + 40 }
        addon.Trace("estimate", "crusader_judged", { detail = "Cast observed; debuff application not confirmed" })
    end
end

function addon.NoteSpellReady(name)
    readyAt[name] = GetTime()
end

-- Ready moments ago and not cast since: an active cooldown is only the GCD (max 1.5s).
-- The time cap covers a cast event we failed to observe.
function addon.IsGcdOnlyCooldown(name)
    return readyAt[name] ~= nil and GetTime() - readyAt[name] <= 1.6
end

function addon.CombatTargetChanged()
    targetEpoch = targetEpoch + 1
    judged = nil
end

function addon.SetCombatCast(spellID, active)
    casting = active and { id = Public(spellID) and spellID or nil } or nil
end

function addon.GetCombatCast()
    if not casting then return false end
    local name = casting.id and CastName(casting.id)
    return true, name and addon.GetLearnedSpell(name), name
end

-- Guide: Judgement unleashes the active seal, so its public usability tells whether any seal is up.
-- Lack of mana makes it unusable too, so that case proves nothing.
local function JudgementSealProbe()
    local info = addon.GetLearnedSpell("Judgement")
    if not info or not C_Spell or not C_Spell.IsSpellUsable then return nil end
    local ok, usable, noMana = pcall(C_Spell.IsSpellUsable, info.spellID)
    if not ok or not Public(usable) or type(usable) ~= "boolean" then return nil end
    if usable then return "active" end
    if Public(noMana) and noMana == false then return "missing" end
end

-- The server needs a moment to apply a new seal; Judgement stays unusable meanwhile (seen up to ~1s in play).
function addon.SealJustCast()
    return seal ~= nil and seal.castAt ~= nil and GetTime() - seal.castAt < 1.5
end

function addon.GetSealEvidence()
    local status, _, name, aura = addon.GetBuffStatus(addon.buffGroups[1])
    if status == "active" then
        local expires
        if aura then
            local ok, value = pcall(function() return aura.expirationTime end)
            if ok and Public(value) and type(value) == "number" and value > GetTime() and value < math.huge then expires = value end
        end
        if seal and seal.name == name and not expires then expires = seal.expires end
        seal = { name = name, expires = expires }
        return "active", name, "observed"
    end
    if status == "missing" then
        -- Cast success can precede the aura update by one frame.
        if seal and seal.castAt and GetTime() - seal.castAt < 0.25 then return "active", seal.name, "estimated" end
        seal = nil
        return "missing", nil, "observed"
    end
    local shown, shownName, miss = ViewerSeal()
    if addon.TraceState then
        addon.TraceState("seal_viewer", shown and (shownName and "active" or "active_unnamed") or miss,
            { detail = shownName or "Cooldown Manager" })
    end
    if shown then
        if shownName then
            if not (seal and seal.name == shownName) then seal = { name = shownName } end
            return "active", shownName, "observed"
        end
        -- The family item proves a seal is up; which one comes from our last observed cast.
        if seal and seal.name then return "active", seal.name, "estimated" end
        return "unknown", nil, "unknown"
    end
    local probe = JudgementSealProbe()
    if addon.TraceState then addon.TraceState("seal_probe", probe or "unknown", { detail = "Judgement usability" }) end
    if probe == "missing" and not addon.SealJustCast() then
        seal = nil
        return "missing", nil, "observed"
    end
    if seal and seal.expires then
        -- A usable Judgement means some seal outlived the estimate (a missed recast); keep the tracked name.
        if seal.expires > GetTime() or probe == "active" then return "active", seal.name, "estimated" end
        return "missing", nil, "estimated"
    end
    return "unknown", nil, "unknown"
end

function addon.GetSealAction()
    if not addon.GetSettings().buffWarnings or not addon.primarySeal then return end
    local status, active, confidence = addon.GetSealEvidence()
    if status == "unknown" then return end
    local recommended = addon.primarySeal
    local name, reason
    if status == "missing" then
        name, reason = recommended, confidence == "estimated" and "Estimated seal expired; refresh it" or "No active seal detected"
    elseif addon.GetSettings().crusaderOpener and not addon.GetLearnedSpell("Holy Shock") then
        local step = addon.GetCrusaderStep(status, active)
        if step == "apply" then name, reason = "Seal of the Crusader", "Long-fight opener"
        elseif step == "judge" then name, reason = "Judgement", "Judge Crusader before switching seal"
        elseif step == "damage" then name, reason = recommended, "Crusader debuff observed"
        elseif step == "restricted" or step == "unavailable" then
            local opened = judged and judged.epoch == targetEpoch and judged.expires > GetTime()
            confidence = "estimated"
            if active == "Seal of the Crusader" then
                name = opened and recommended or "Judgement"
                reason = opened and "Crusader judged; application estimated" or "Judge your tracked Crusader seal"
            elseif not opened then name, reason = "Seal of the Crusader", "Long-fight opener; target debuff unknown" end
        end
    end
    if not name and status == "active" and confidence == "observed" then
        local step, _, count = addon.GetEchoStep(status, active, recommended)
        if step == "swap" then name, reason = "Seal of Righteousness", "Spend " .. count .. " observed Command echoes"
        elseif step == "return" then name, reason = "Seal of Command", "Command echoes no longer detected" end
    end
    if name then
        local info = addon.GetLearnedSpell(name)
        if info then return info, name, reason, confidence, name ~= "Judgement" end
    end
end
