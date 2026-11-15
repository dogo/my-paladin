local addon = { db = { activeProfile = "leveling" } }
local settings = { combatMode = "single" }
function addon.GetSettings() return settings end
local secret = setmetatable({}, { __tostring = function() error("Secret formatted") end,
    __index = function() error("Secret inspected") end })
function issecretvalue(value) return value == secret end
function GetTime() return 12.34 end
function time() return 123456 end
function InCombatLockdown() return true end
function GetBuildInfo() return "1.60.1", "70938" end
local output, hook = {}, nil
C_Log = { LogMessage = function(line) output[#output + 1] = line end, LogErrorMessage = function() end }
function hooksecurefunc(_, _, callback) hook = callback end
assert(loadfile("MyPaladin/Diagnostics.lua"))("MyPaladin", addon)
local saved = addon.StartDiagnostics(nil)
assert(saved.enabled and #output == 1)
addon.TraceState("seal_hud", "echo_swap", { count = 2, spell = 100 })
local before = saved.serial
addon.TraceState("seal_hud", "echo_swap", { count = 2, spell = 100 })
assert(saved.serial == before, "Repeated state must not spam the buffer")
settings.combatMode = "aoe"
addon.TraceState("seal_hud", "echo_swap", { count = 2, spell = 100 })
assert(saved.serial == before + 1, "Context changes must be retained")
addon.Trace("test", "protected", { count = secret, spell = secret, detail = secret, guid = "private" })
assert(not output[#output]:find('"spell"') and not output[#output]:find("private"))
addon.Trace("marker", "user", { detail = 'quote" back\\ line\n\t' })
assert(output[#output]:find("\\u0022", 1, true) and output[#output]:find("\\u000a", 1, true))
hook(secret)
local serial = saved.serial
hook("AnotherAddon: error")
assert(saved.serial == serial)
hook("Interface/AddOns/MyPaladin/MyPaladin.lua:10: error\nprivate locals")
assert(saved.serial == serial + 1 and not output[#output]:find("private locals"))
for index = 1, 1100 do addon.Trace("test", "bounded", { count = index }) end
local entries = 0
for _ in pairs(saved.entries) do entries = entries + 1 end
assert(entries == 1000, "Ring must remain bounded")
addon.TraceCommand("off", function() end)
serial = saved.serial
addon.Trace("test", "off")
assert(saved.serial == serial and not saved.enabled)
addon.StartDiagnostics(saved)
assert(not saved.enabled and saved.serial == serial, "Disabled preference must survive reload")
addon.TraceCommand("on", function() end)
addon.TraceCommand("mark boss start", function() end)
assert(output[#output]:find("boss start", 1, true))
local oldSink = C_Log.LogMessage
C_Log.LogMessage = function() error("Native logger unavailable") end
serial = saved.serial
addon.Trace("test", "sink_failure")
assert(saved.serial == serial + 1, "Native sink failures must preserve SavedVariables recording")
C_Log.LogMessage = oldSink
addon.Trace("test", "after_failure")
assert(saved.serial == serial + 2, "Sink failures must not leave the recorder locked")
addon.StartDiagnostics({ schema = 1, serial = 0/0, sessions = math.huge, entries = { bad = true, [2000] = "bad" } })
assert(saved.serial == serial + 2)
print("diagnostics tests passed")
