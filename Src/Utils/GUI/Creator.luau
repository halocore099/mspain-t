local UICreator = {}

local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/"

shared.Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
shared.SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

shared.Toggles = getgenv().Linoria.Toggles
shared.Options = getgenv().Linoria.Options

getgenv()._internal_unload_mspaint = function()
    getgenv().mspaint_loading = false
    getgenv().mspaint_loaded = false
    task.spawn(shared.Library.Unload)
end

function UICreator:CreateWindow()
    local Window = shared.Library:CreateWindow({
        Title = "mspaint v2 - OUTDATED! | " .. shared.ScriptName,
        Center = true,
        AutoShow = true,
        Resizable = true,
        NotifySide = "Right",
        ShowCustomCursor = true,
        TabPadding = 2,
        MenuFadeTime = 0
    })

    --// Notificatins \\--
    shared.NotifyStyle = "Linoria"
    shared.NotifyVolume = 2
    shared.Notify = require("Notify")

    --// Checker \\--
    shared.CheckToggle = function(toggleName: string, value: boolean)
        return shared.Toggles[toggleName] and shared.Toggles[toggleName].Value == value
    end
    shared.CheckOption = function(optionName: string, value: any)
        return shared.Options[optionName] and (typeof(shared.Options[optionName].Value) == "table" and shared.Options[optionName].Value[value] or shared.Options[optionName].Value == value)
    end

    --// Unload Handler \\--
    shared.Library:OnUnload(function()
        print("Unloading...")

        shared.Fly:Stop()

        for _, connection in pairs(shared.Connections) do
            connection:Disconnect()
        end

        getgenv().mspaint_loading = false
        getgenv().mspaint_loaded = false
        shared.Library.Unloaded = true
        print("Unloaded!")
    end)

    return Window
end

function UICreator:CreateTimeoutInfoTab()
    local ErrorTab = shared.Window:AddTab("Error")
    ErrorTab:UpdateWarningBox({
        Visible = true,
        Title = "mspaint - RUNTIME ERROR",
        Text = "mspaint was unable to load in time (<b>ERROR: timeout</b>)\n\n<i>keep in mind that this is an outdated version and it is more likely that the fix is inside of the updated version.</i>"
    })

    local ResourcesGroup = ErrorTab:AddLeftGroupbox("Resources")
    local ErrorInfoGroup = ErrorTab:AddRightGroupbox("Error Info")
    ResourcesGroup:AddLabel("Discord Server: https://discord.gg/mspaint")
    ResourcesGroup:AddDivider()
    ResourcesGroup:AddButton("Join Discord", function()
        local Inviter = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Discord%20Inviter/Source.lua"))()
        Inviter.Join("https://discord.com/invite/cfyMptntHr")
        Inviter.Prompt({
            name = "mspaint",
            invite = "https://discord.com/invite/cfyMptntHr",
        })
    end):AddButton("Copy Link", function()
        if setclipboard then
            setclipboard("https://discord.com/invite/cfyMptntHr")
            shared.Library:Notify("Copied discord link to clipboard!")
        else
            shared.Library:Notify("Discord link: https://discord.com/invite/cfyMptntHr", 10)
        end
    end)

    ErrorInfoGroup:AddLabel("Timeout error usually means the game's owner has moved something to a different location which breaks the code that has already been written.\n\nDue to the fact that this open source version is discontinued, we will not be adding fixes.", true)
end

function UICreator:CreateSettingsTab()
    local SettingsTab = shared.Window:AddTab("UI Settings")
    SettingsTab:UpdateWarningBox({
        Visible = true,
        Title = "WARNING",
        Text = "You are using a deprecated version of mspaint, to get the new version please join our discord server via .gg/mspaint"
    })

    local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")
    local CreditsGroup = SettingsTab:AddRightGroupbox("Credits")

    MenuGroup:AddToggle("ExecuteOnTeleport", { Default = false, Text = "Execute On Teleport" })
    MenuGroup:AddToggle("KeybindMenuOpen", { Default = false, Text = "Open Keybind Menu", Callback = function(value) shared.Library.KeybindFrame.Visible = value end})
    MenuGroup:AddToggle("ShowCustomCursor", {Text = "Custom Cursor", Default = true, Callback = function(Value) shared.Library.ShowCustomCursor = Value end})
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
    MenuGroup:AddButton("Join Discord", function()
        local Inviter = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Discord%20Inviter/Source.lua"))()
        Inviter.Join("https://discord.com/invite/cfyMptntHr")
        Inviter.Prompt({
            name = "mspaint",
            invite = "https://discord.com/invite/cfyMptntHr",
        })
    end):AddButton("Copy Link", function()
        if setclipboard then
            setclipboard("https://discord.com/invite/cfyMptntHr")
            shared.Library:Notify("Copied discord link to clipboard!")
        else
            shared.Library:Notify("Discord link: https://discord.com/invite/cfyMptntHr", 10)
        end
    end)
    MenuGroup:AddButton("Unload", function() shared.Library:Unload() end)

    CreditsGroup:AddLabel("Developers:")
    CreditsGroup:AddLabel("upio - owner")
    CreditsGroup:AddLabel("deividcomsono - main script dev")
    CreditsGroup:AddLabel("mstudio45")
    CreditsGroup:AddLabel("bacalhauz")

    shared.Library.ToggleKeybind = shared.Options.MenuKeybind

    ThemeManager:SetLibrary(shared.Library)
    shared.SaveManager:SetLibrary(shared.Library)

    shared.SaveManager:IgnoreThemeSettings()

    shared.SaveManager:SetFolder("mspaint/" .. string.lower(shared.ScriptLoader))
    if shared.SubFolder then
        shared.SaveManager:SetSubFolder(shared.SubFolder)
    end

    shared.SaveManager:BuildConfigSection(SettingsTab)
    ThemeManager:ApplyToTab(SettingsTab)

    shared.SaveManager:LoadAutoloadConfig()

    shared.Connect:GiveSignal(shared.LocalPlayer.OnTeleport:Connect(function()
        if not shared.Toggles.ExecuteOnTeleport.Value or getgenv().queued_to_teleport then return end

        getgenv().queued_to_teleport = true
        queue_on_teleport([[ loadstring(game:HttpGet("https://github.com/notpoiu/mspaint/releases/latest/download/Script.luau"))() ]])
    end))

    return SettingsTab
end

--// Self-Test Tab (debug builds only) \\--
local LogService = game:GetService("LogService")

-- Toggles whose effect can't be observed inside the sweep's wait window —
-- they fire on external events (teleport, death, jumpscare). Enabling them
-- briefly proves nothing AND can cause side effects later (e.g. queueing a
-- dead loadstring URL on next teleport). Skip outright.
local SWEEP_SKIP = {
    ExecuteOnTeleport = "fires only on actual game-to-game teleport",
    KeybindMenuOpen = "controls keybind UI visibility, not a feature",
    ShowCustomCursor = "cosmetic, no testable behavior",
    MenuKeybind = "keybind config",
}

local function runToggleSweep(waitTime: number, onProgress: ((done: number, total: number, last: any) -> ())?)
    local toggles = {}
    for id, toggle in pairs(shared.Toggles) do
        if typeof(toggle) == "table"
            and typeof(toggle.SetValue) == "function"
            and typeof(toggle.Value) == "boolean"
        then
            table.insert(toggles, { id = id, toggle = toggle })
        end
    end
    table.sort(toggles, function(a, b) return a.id < b.id end)

    local results = {}
    local startTick = tick()

    for i, entry in ipairs(toggles) do
        local id, toggle = entry.id, entry.toggle
        local label = toggle.Text or id
        local originalValue = toggle.Value

        local entryResult = { id = id, label = label }

        if SWEEP_SKIP[id] then
            entryResult.status = "skipped"
            entryResult.note = SWEEP_SKIP[id]
        elseif originalValue == true then
            entryResult.status = "skipped"
            entryResult.note = "already on at sweep start"
        else
            local captured = {}
            local conn = LogService.MessageOut:Connect(function(msg, msgType)
                if msgType == Enum.MessageType.MessageError
                    or msgType == Enum.MessageType.MessageWarning
                then
                    table.insert(captured, string.format("[%s] %s", tostring(msgType):gsub("Enum.MessageType.Message", ""), msg))
                end
            end)

            local setOk, setErr = pcall(function() toggle:SetValue(true) end)
            task.wait(waitTime)
            pcall(function() toggle:SetValue(originalValue) end)
            conn:Disconnect()

            if not setOk then
                entryResult.status = "error"
                entryResult.errors = { "SetValue threw: " .. tostring(setErr) }
            elseif #captured > 0 then
                entryResult.status = "error"
                entryResult.errors = captured
            else
                entryResult.status = "ok"
            end
        end

        table.insert(results, entryResult)

        if onProgress then
            pcall(onProgress, i, #toggles, entryResult)
        end
    end

    return results, tick() - startTick
end

local function formatResults(results: { any }, elapsed: number): string
    local lines = {}
    local ok, err, skipped = 0, 0, 0
    for _, r in ipairs(results) do
        if r.status == "ok" then ok += 1
        elseif r.status == "skipped" then skipped += 1
        else err += 1
        end
    end

    table.insert(lines, "=== mspaint-t self-test ===")
    table.insert(lines, string.format("Game: %s   PlaceId: %d", shared.ScriptName or "?", game.PlaceId))
    table.insert(lines, string.format("Elapsed: %.1fs   Total: %d   OK: %d   ERROR: %d   SKIPPED: %d", elapsed, #results, ok, err, skipped))
    table.insert(lines, "")

    table.insert(lines, "--- ERRORS ---")
    for _, r in ipairs(results) do
        if r.status == "error" then
            table.insert(lines, string.format("[%s]  id=%s", r.label, r.id))
            for _, e in ipairs(r.errors or {}) do
                table.insert(lines, "    " .. e)
            end
        end
    end

    table.insert(lines, "")
    table.insert(lines, "--- SKIPPED ---")
    for _, r in ipairs(results) do
        if r.status == "skipped" then
            table.insert(lines, string.format("[%s]  id=%s  (%s)", r.label, r.id, r.note or ""))
        end
    end

    table.insert(lines, "")
    table.insert(lines, "--- OK ---")
    for _, r in ipairs(results) do
        if r.status == "ok" then
            table.insert(lines, string.format("[%s]  id=%s", r.label, r.id))
        end
    end

    return table.concat(lines, "\n")
end

function UICreator:CreateSelfTestTab()
    local Tab = shared.Window:AddTab("Self-Test")

    local ControlsGroup = Tab:AddLeftGroupbox("Controls")
    local StatusGroup = Tab:AddRightGroupbox("Status")

    ControlsGroup:AddSlider("SelfTestWait", {
        Text = "Wait per toggle (s)",
        Default = 0.4,
        Min = 0.1,
        Max = 3,
        Rounding = 1,
        Compact = true
    })

    local statusLabel = StatusGroup:AddLabel("Idle. Press 'Run Sweep' to test every toggle.", true)
    local lastErrorLabel = StatusGroup:AddLabel("", true)

    ControlsGroup:AddButton("Run Sweep", function()
        statusLabel:SetText("Sweep starting...")
        lastErrorLabel:SetText("")

        task.spawn(function()
            local waitTime = shared.Options.SelfTestWait and shared.Options.SelfTestWait.Value or 0.4

            local results, elapsed = runToggleSweep(waitTime, function(done, total, last)
                local mark = last.status == "ok" and "ok" or last.status == "skipped" and "skip" or "ERR"
                statusLabel:SetText(string.format("%d / %d   %s: %s", done, total, mark, last.label))
                if last.status == "error" then
                    lastErrorLabel:SetText("Last error: " .. last.label)
                end
            end)

            local report = formatResults(results, elapsed)
            local filename = string.format("mspaint-t-selftest-%s.txt", os.date("%Y%m%d-%H%M%S"))

            if typeof(writefile) == "function" then
                pcall(writefile, filename, report)
            end

            local errCount = 0
            for _, r in ipairs(results) do
                if r.status == "error" then errCount += 1 end
            end

            statusLabel:SetText(string.format("Done. %d/%d errors. Report: %s", errCount, #results, filename))

            shared.Library:Notify(string.format("Self-test done: %d errors in %d toggles. Wrote %s", errCount, #results, filename), 10)
        end)
    end)

    ControlsGroup:AddButton("Print Toggle List", function()
        local count = 0
        for id, toggle in pairs(shared.Toggles) do
            if typeof(toggle) == "table" and typeof(toggle.Value) == "boolean" then
                count += 1
                print(string.format("[Toggle] %s = %s   text=%q", id, tostring(toggle.Value), toggle.Text or ""))
            end
        end
        shared.Library:Notify(string.format("Printed %d toggles to console", count), 5)
    end)

    return Tab
end

return UICreator
