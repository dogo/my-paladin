local _, addon = ...
local LIMIT, PREFIX = 1000, "MPALADIN1|"
local log, session, sequence, writing
local last = {}
local fields = { "feature", "state", "spell", "count", "detail", "profile", "mode", "combat" }

local function Public(value)
    if not issecretvalue or issecretvalue(value) then return nil end
    local kind = type(value)
    if kind == "string" then return value:sub(1, 300) end
    if kind == "boolean" then return value end
    if kind == "number" and value == value and value > -math.huge and value < math.huge then return value end
end

local function Encode(value)
    if type(value) ~= "string" then return tostring(value) end
    return '"' .. value:gsub('[%z\1-\31\\"]', function(char)
        return string.format("\\u%04x", string.byte(char))
    end) .. '"'
end

function addon.Trace(feature, state, values, transition)
    if not log or not log.enabled or writing then return end
    writing = true
    local data = { feature = feature, state = state, profile = addon.db.activeProfile,
        mode = addon.GetSettings().combatMode, combat = InCombatLockdown() }
    for _, key in ipairs({ "spell", "count", "detail" }) do data[key] = values and values[key] end
    local parts = {}
    for _, key in ipairs(fields) do
        local value = Public(data[key])
        if value ~= nil then parts[#parts + 1] = Encode(key) .. ":" .. Encode(value) end
    end
    local signature = table.concat(parts, ",")
    if transition and last[feature] == signature then writing = false; return end
    last[feature] = signature
    sequence = sequence + 1
    log.serial = log.serial + 1
    local record = PREFIX .. '{"schema":1,"session":' .. Encode(session) .. ',"seq":' .. sequence
        .. ',"uptime":' .. Encode(math.floor(GetTime())) .. ',' .. signature .. '}'
    log.entries[(log.serial - 1) % LIMIT + 1] = record
    -- shortcut: C_Log delivery/flush is client-dependent; SavedVariables is the fallback.
    local sinkAvailable = C_Log and type(C_Log.LogMessage) == "function"
    local sinkOK = sinkAvailable and pcall(C_Log.LogMessage, record)
    writing = false
    if feature ~= "api_log" then
        addon.TraceState("api_log", not sinkAvailable and "api_missing" or (sinkOK and "call_accepted" or "call_failed"),
            { detail = "C_Log.LogMessage; call result only, disk delivery unverified" })
    end
end

function addon.TraceState(feature, state, values)
    addon.Trace(feature, state, values, true)
end

function addon.StartDiagnostics(saved)
    log = type(saved) == "table" and saved.schema == 1 and saved or {}
    log.schema = 1
    log.entries = type(log.entries) == "table" and log.entries or {}
    for key, value in pairs(log.entries) do
        if type(key) ~= "number" or key < 1 or key > LIMIT or key % 1 ~= 0 or type(value) ~= "string" then
            log.entries[key] = nil
        end
    end
    log.serial = type(log.serial) == "number" and log.serial >= 0 and log.serial < 1e12
        and log.serial % 1 == 0 and log.serial or 0
    log.sessions = type(log.sessions) == "number" and log.sessions >= 0 and log.sessions < 1e9
        and log.sessions % 1 == 0 and log.sessions or 0
    log.sessions = log.sessions + 1
    if type(log.enabled) ~= "boolean" then log.enabled = true end
    session = tostring(time()) .. "-" .. log.sessions
    sequence, last = 0, {}
    local version, build = GetBuildInfo()
    addon.Trace("session", "start", { detail = "addon=0.11.2 client=" .. version .. " build=" .. build
        .. " C_Log=" .. tostring(C_Log and type(C_Log.LogMessage) == "function" or false) })
    -- Observe the native error sink without replacing the client's error handler.
    if hooksecurefunc and C_Log and C_Log.LogErrorMessage and not addon.errorHooked then
        local ok = pcall(hooksecurefunc, C_Log, "LogErrorMessage", function(message)
            local public = Public(message)
            if type(public) == "string" and public:find("MyPaladin", 1, true) then
                addon.Trace("error", "lua", { detail = public:match("[^\r\n]+") })
            end
        end)
        addon.errorHooked = ok
    end
    return log
end

function addon.TraceCommand(command, say)
    if command == "on" then log.enabled = true; last = {}; addon.Trace("session", "enabled")
    elseif command == "off" then addon.Trace("session", "disabled"); log.enabled = false
    elseif command:match("^mark%s+") then addon.Trace("marker", "user", { detail = command:sub(6) })
    elseif command ~= "" then say("Use /mp trace [on|off|mark text]"); return end
    say("Trace " .. (log.enabled and "on" or "off") .. "; " .. math.min(log.serial, LIMIT)
        .. "/" .. LIMIT .. " records. /reload saves to disk; live C_Log delivery is unverified.")
end
