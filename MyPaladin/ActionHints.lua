local _, addon = ...
local actions, borders = {}, {}
local bars = {
    {"ActionButton", "ACTIONBUTTON"},
    {"MultiBarBottomLeftButton", "MULTIACTIONBAR1BUTTON"},
    {"MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON"},
    {"MultiBarRightButton", "MULTIACTIONBAR3BUTTON"},
    {"MultiBarLeftButton", "MULTIACTIONBAR4BUTTON"},
    {"MultiBar5Button", "MULTIACTIONBAR5BUTTON"},
    {"MultiBar6Button", "MULTIACTIONBAR6BUTTON"},
    {"MultiBar7Button", "MULTIACTIONBAR7BUTTON"},
}
local function Public(value) return issecretvalue and not issecretvalue(value) end
local function Trace(state, count)
    if addon.TraceState then addon.TraceState("bindings", state, {count = count, detail = "Blizzard bars and simple cast macros"}) end
end
local function Border(button)
    if borders[button] then return borders[button] end
    local edges = {}
    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local edge = button:CreateTexture(nil, "OVERLAY")
        if side == "TOP" or side == "BOTTOM" then
            edge:SetPoint(side .. "LEFT", button, side .. "LEFT")
            edge:SetPoint(side .. "RIGHT", button, side .. "RIGHT")
            edge:SetHeight(3)
        else
            edge:SetPoint("TOP" .. side, button, "TOP" .. side)
            edge:SetPoint("BOTTOM" .. side, button, "BOTTOM" .. side)
            edge:SetWidth(3)
        end
        edge:SetColorTexture(0.4, 1, 0.4, 1)
        edge:Hide()
        edges[#edges + 1] = edge
    end
    borders[button] = edges
    return edges
end

function addon.ClearActionHint()
    for _, edges in pairs(borders) do for _, edge in ipairs(edges) do edge:Hide() end end
end

local function Unchanged(action)
    local ok, kind, id = pcall(GetActionInfo, action.slot)
    if not ok or not Public(kind) or kind ~= action.kind then return false end
    local bound, key = pcall(GetBindingKey, action.command)
    if not bound or not Public(key) or key ~= action.key then return false end
    if kind == "macro" then
        if not GetActionText or not GetMacroBody or type(action.macro) ~= "string" or not action.body then return false end
        local named, name = pcall(GetActionText, action.slot)
        if not named or not Public(name) or name ~= action.macro then return false end
        local read, body = pcall(GetMacroBody, name)
        return read and Public(body) and body == action.body
    end
    return kind == "spell" and Public(id) and id == action.sourceID
end

function addon.RebuildActionHints()
    addon.ClearActionHint()
    if InCombatLockdown() then
        local count = 0
        for id, action in pairs(actions) do
            -- Macro icon updates also notify the action bar; retain only mappings we can revalidate.
            if Unchanged(action) then count = count + 1 else actions[id] = nil end
        end
        Trace("validated", count)
        return
    end
    actions = {}
    if not GetActionInfo or not GetBindingKey or not issecretvalue then Trace("unavailable", 0); return end
    local names = {}
    for _, group in ipairs(addon.buffGroups) do for _, name in ipairs(group.spells) do names[name:lower()] = name end end
    for _, profile in pairs(addon.profiles) do for _, name in ipairs(profile.spells) do names[name:lower()] = name end end
    for _, bar in ipairs(bars) do
        for index = 1, 12 do
            local button = _G[bar[1] .. index]
            if button then
                local ok, slot = pcall(function() return button.action or button:GetAttribute("action") end)
                if ok and Public(slot) and type(slot) == "number" then
                    local read, kind, id, subtype = pcall(GetActionInfo, slot)
                    local command = bar[2] .. index
                    local bindOK, key = pcall(GetBindingKey, command)
                    if not bindOK or not Public(key) or type(key) ~= "string" then key = nil end
                    local macro, body, label
                    local function Store(spellID)
                        if Public(spellID) and type(spellID) == "number" and
                            (not actions[spellID] or (not actions[spellID].key and key)
                                or (label and key and not actions[spellID].label)) then
                            actions[spellID] = { key = key, edges = Border(button), button = button,
                                slot = slot, kind = kind, sourceID = id, command = command,
                                macro = macro, body = body, label = label }
                        end
                    end
                    local function Add(spellID)
                        Store(spellID)
                        if Public(spellID) and type(spellID) == "number" and C_Spell and C_Spell.GetSpellName then
                            local nameOK, name = pcall(C_Spell.GetSpellName, spellID)
                            if nameOK and Public(name) and type(name) == "string" and names[name:lower()] then
                                local learned = addon.GetLearnedSpell(names[name:lower()])
                                if learned then Store(learned.spellID) end
                            end
                        end
                    end
                    if read and Public(kind) and Public(id) and Public(subtype) then
                        if kind == "spell" then Add(id)
                        elseif kind == "macro" then
                            macro = id
                            if GetActionText then
                                local textOK, text = pcall(GetActionText, slot)
                                if textOK and Public(text) and type(text) == "string" then macro = text end
                            end
                            if GetMacroBody and Public(macro) then
                                local bodyOK, value = pcall(GetMacroBody, macro)
                                if bodyOK and Public(value) and type(value) == "string" then
                                    body = value
                                    local casts, simple = {}, true
                                    for line in body:gmatch("[^\r\n]+") do
                                        local cast = line:match("^%s*/cast%s+(.+)")
                                        if cast and not cast:find("[", 1, true) and not cast:find(";", 1, true) then
                                            local name = names[cast:match("^%s*!?(.-)%s*$"):lower()]
                                            local info = name and addon.GetLearnedSpell(name)
                                            if info then casts[#casts + 1] = {name = name, id = info.spellID} end
                                            if not info then simple = false end
                                        elseif line:match("^%s*/cast") or line:match("^%s*/click") then
                                            simple = false
                                        end
                                    end
                                    if simple and #casts == 2 and casts[1].name == "Judgement" and casts[2].name == "Holy Strike" then
                                        label = "Holy Strike macro"
                                    end
                                    if subtype == "spell" then Add(id) end
                                    for _, cast in ipairs(casts) do Add(cast.id) end
                                end
                            end
                            if not body and subtype == "spell" then Add(id) end
                        end
                    end
                end
            end
        end
    end
    local count = 0
    for _ in pairs(actions) do count = count + 1 end
    Trace("mapped", count)
end

function addon.ShowActionHint(spellID, state)
    addon.ClearActionHint()
    local action = actions[spellID]
    if not action then return nil end
    if (state == "ready" or state == "estimated") and action.button:IsShown() then
        for _, edge in ipairs(action.edges) do
            edge:SetColorTexture(state == "estimated" and 1 or 0.4, state == "estimated" and 0.7 or 1, 0.3, 1)
            edge:Show()
        end
    end
    return action.key, action.label
end
