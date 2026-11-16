local addon = {buffGroups = {{spells = {"Seal of Righteousness"}}}, profiles = {leveling = {spells = {"Judgement", "Holy Strike"}}}}
local combat, macro = false, "#showtooltip Holy Strike\n/targetenemy [noharm][dead]\n/startattack\n/cast Judgement\n/cast Holy Strike"
local secret = setmetatable({}, {__tostring = function() error("Secret formatted") end})
function issecretvalue(value) return rawequal(value, secret) end
function InCombatLockdown() return combat end
function addon.GetLearnedSpell(name) return {spellID = name == "Judgement" and 1 or name == "Holy Strike" and 2 or 3} end
local edges = {}
local button = {action = 2}
function button:IsShown() return true end
function button:CreateTexture()
    assert(not combat, "Never create glow regions during combat")
    local edge = {}
    function edge:SetPoint() end
    function edge:SetHeight() end
    function edge:SetWidth() end
    function edge:SetColorTexture(...) self.color = {...} end
    function edge:Show() self.shown = true end
    function edge:Hide() self.shown = false end
    edges[#edges + 1] = edge
    return edge
end
ActionButton2 = button
function GetActionInfo(slot) assert(not combat and slot == 2); return "macro", 2, "spell" end
function GetActionText() return "Holy Strike Macro" end
function GetMacroBody(name) assert(name == "Holy Strike Macro"); return macro end
function GetBindingKey(command) assert(command == "ACTIONBUTTON2"); return "2" end
assert(loadfile("MyPaladin/ActionHints.lua"))("MyPaladin", addon)
addon.RebuildActionHints()
assert(#edges == 4, "One macro button needs only one border, even with two spells")
combat = true
assert(addon.ShowActionHint(1, "ready") == "2")
for _, edge in ipairs(edges) do assert(edge.shown and edge.color[1] == 0.4) end
assert(addon.ShowActionHint(2, "estimated") == "2")
for _, edge in ipairs(edges) do assert(edge.shown and edge.color[1] == 1) end
addon.ShowActionHint(2, "wait")
for _, edge in ipairs(edges) do assert(not edge.shown) end
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == nil, "Action bar changes in combat must discard stale bindings")
combat = false
macro = "/cast [mod:shift] Judgement; Holy Strike"
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == nil, "Never guess which conditional macro branch the player will trigger")
assert(addon.ShowActionHint(2, "ready") == "2", "The displayed spell still maps to its native button")
C_Spell = {GetSpellName = function(id) assert(id == 22); return "Holy Strike" end}
GetActionInfo = function() return "spell", 22 end
addon.RebuildActionHints()
assert(addon.ShowActionHint(2, "ready") == "2", "An action's base/rank ID must map to the learned spell by public name")
GetActionInfo = function() return "spell", secret end
addon.RebuildActionHints()
assert(addon.ShowActionHint(2, "ready") == nil)
print("OK: native action keybinds, simple multi-cast macro, non-casting glow and combat cache invalidation")
