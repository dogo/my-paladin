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

function addon.GetBuffStatus(group)
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
            local success, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
            if not success then
                unavailable = true
            elseif issecretvalue(aura) then
                restricted = true
            elseif aura then
                -- Presence is sufficient; never inspect the returned aura's fields.
                local displayName = name:gsub("^Seal of ", ""):gsub("^Blessing of ", ""):gsub(" Aura$", "")
                return "active", displayName
            end
        end
    end
    if restricted then return "restricted" end
    if unavailable then return "unavailable" end
    return "missing"
end

function addon.GetManaText(current, maximum)
    if not issecretvalue or issecretvalue(current) or issecretvalue(maximum) then
        return "Mana", false
    end
    if type(current) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return "Mana unavailable", false
    end
    local percent = math.floor(current / maximum * 100 + 0.5)
    -- shortcut: low mana is fixed at 20%; make it per profile when configurable profiles ship.
    local low = current / maximum < 0.2
    return (low and "Low mana: " or "Mana: ") .. percent .. "%", low
end
