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
    function edge:SetBlendMode(mode) self.blend = mode end
    function edge:CreateAnimationGroup()
        local group = {plays = 0}
        function group:SetLooping(mode) self.looping = mode end
        function group:CreateAnimation() return {SetFromAlpha = function() end, SetToAlpha = function() end, SetDuration = function() end} end
        function group:Play() self.playing, self.plays = true, self.plays + 1 end
        function group:Stop() self.playing = false end
        function group:IsPlaying() return self.playing end
        return group
    end
    edges[#edges + 1] = edge
    return edge
end
ActionButton2 = button
function GetActionInfo(slot) assert(slot == 2); return "macro", 2, "spell" end
function GetActionText() return "Holy Strike Macro" end
function GetMacroBody(name) assert(name == "Holy Strike Macro"); return macro end
function GetBindingKey(command) assert(command == "ACTIONBUTTON2"); return "2" end
assert(loadfile("MyPaladin/ActionHints.lua"))("MyPaladin", addon)
addon.RebuildActionHints()
assert(#edges == 4, "One macro button needs only one border, even with two spells")
combat = true
assert(addon.ShowActionHint(1, "ready") == "2")
for _, edge in ipairs(edges) do assert(edge.shown and edge.color[1] == 0.4 and edge.pulse.playing) end
addon.ShowActionHint(1, "ready")
for _, edge in ipairs(edges) do assert(edge.pulse.plays == 1, "HUD refresh must not restart the pulse") end
assert(addon.ShowActionHint(2, "estimated") == "2")
for _, edge in ipairs(edges) do assert(edge.shown and edge.color[1] == 1) end
addon.ShowActionHint(2, "wait")
for _, edge in ipairs(edges) do assert(not edge.shown and not edge.pulse.playing) end
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == "2", "An unchanged macro must keep its binding after combat action-bar notifications")
local key, label = addon.ShowActionHint(1, "ready")
assert(key == "2" and label == "Holy Strike macro", "Judgement must direct the player to the existing Holy Strike macro")
local _, strikeLabel = addon.ShowActionHint(2, "ready")
assert(strikeLabel == label, "Both spells must identify the same macro action")
GetActionInfo = function() return "macro", 1, "spell" end
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == "2", "A macro's displayed spell can change without changing its body")
GetActionInfo = function() return "macro", secret, "spell" end
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == "2", "Public macro identity/body can validate the mapping without reading its displayed spell ID")
macro = "/cast Holy Strike"
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == nil, "Changed macros must discard stale bindings during combat")
combat = false
GetActionInfo = function() return "macro", 2, "spell" end
macro = "/cast [mod:shift] Judgement; Holy Strike"
addon.RebuildActionHints()
assert(addon.ShowActionHint(1, "ready") == nil, "Never guess which conditional macro branch the player will trigger")
key, label = addon.ShowActionHint(2, "ready")
assert(key == "2" and label == nil, "The displayed spell maps to its button without assuming both conditional casts")
C_Spell = {GetSpellName = function(id) assert(id == 22); return "Holy Strike" end}
GetActionInfo = function() return "spell", 22 end
addon.RebuildActionHints()
assert(addon.ShowActionHint(2, "ready") == "2", "An action's base/rank ID must map to the learned spell by public name")
combat = true
GetActionInfo = function() return "spell", secret end
addon.RebuildActionHints()
assert(addon.ShowActionHint(2, "ready") == nil, "Opaque action data must invalidate the cached binding safely")
combat = false
GetActionInfo = function() return "spell", secret end
addon.RebuildActionHints()
assert(addon.ShowActionHint(2, "ready") == nil)
-- With Blizzard's proc atlas available, the button gets the animated proc loop instead of plain edges.
local function Animation()
    local group = {plays = 0}
    function group:SetLooping(mode) self.looping = mode end
    function group:CreateAnimation(kind)
        assert(kind == "FlipBook")
        local flip = {}
        for _, name in ipairs({"SetFlipBookRows", "SetFlipBookColumns", "SetFlipBookFrames", "SetDuration"}) do
            flip[name] = function(anim, value) anim[name] = value end
        end
        self.flip = flip
        return flip
    end
    function group:Play() self.playing, self.plays = true, self.plays + 1 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    return group
end
local glow
C_Texture = {GetAtlasInfo = function(atlas) return atlas == "UI-HUD-ActionBar-Proc-Loop-Flipbook" and {} or nil end}
function CreateFrame(kind, _, parent)
    assert(kind == "Frame" and parent == button and not combat, "Glow frames are built out of combat on the button")
    glow = {}
    function glow:SetSize(width) self.size = width end
    function glow:SetPoint() end
    function glow:SetFrameLevel(level) self.level = level end
    function glow:Show() self.shown = true end
    function glow:Hide() self.shown = false end
    function glow:CreateTexture()
        local texture = {}
        function texture:SetAllPoints() end
        function texture:SetAtlas(atlas) self.atlas = atlas end
        function texture:SetVertexColor(...) self.color = {...} end
        function texture:CreateAnimationGroup() self.group = Animation(); return self.group end
        self.tex = texture
        return texture
    end
    return glow
end
function button:GetWidth() return 45 end
function button:GetFrameLevel() return secret end
GetActionInfo = function() return "spell", 2 end
assert(loadfile("MyPaladin/ActionHints.lua"))("MyPaladin", addon)
addon.RebuildActionHints()
assert(addon.ShowActionHint(2, "ready") == "2")
local group = glow.tex.group
assert(glow.shown and group.playing and group.looping == "REPEAT" and math.abs(glow.size - 63) < 1e-9 and glow.level == nil)
assert(group.flip.SetFlipBookFrames == 30 and glow.tex.color[2] == 1)
addon.ShowActionHint(2, "estimated")
assert(group.plays == 1 and glow.tex.color[2] == 0.55, "Refresh keeps the loop running and tints estimates")
addon.ShowActionHint(2, "wait")
assert(not glow.shown and not group.playing)
print("OK: native action keybinds, simple multi-cast macro, non-casting glow and combat cache invalidation")
