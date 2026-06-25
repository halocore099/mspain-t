--!nocheck
-- Linoria-shaped adapter on top of Rayfield. Pretends to BE Linoria so the
-- ~700 feature-code reads of shared.Toggles[id].Value / shared.Options[id]
-- / shared.Library.X don't have to change. Only Creator.luau branches on
-- _G.UI to pick this adapter vs. the real Linoria library.
--
-- Spike scope: all widget builders defined; AddToggle / AddButton are real;
-- the rest populate shared.Toggles or shared.Options with Linoria-shaped
-- entries so feature code reading `.Value` / `:GetState()` doesn't crash.
-- Keybinds disabled in Rayfield mode (per user — :GetState() returns false).

local Rayfield = require("RayfieldLib")

local Adapter = {}

-- ---------- Linoria-shaped entry constructors ----------

local function makeToggle(id, opts)
    opts = opts or {}
    local t = {
        Value = opts.Default or false,
        Text = opts.Text or id,
        _id = id,
        _changed = {},
        _rayfield = nil,
    }
    function t:SetValue(v)
        self.Value = v
        if self._rayfield and self._rayfield.Set then
            self._rayfield:Set(v)
        end
        for _, cb in ipairs(self._changed) do task.spawn(cb, v) end
    end
    function t:OnChanged(cb)
        table.insert(self._changed, cb)
    end
    return t
end

local function makeSlider(id, opts)
    opts = opts or {}
    local s = {
        Value = opts.Default or 0,
        Min = opts.Min or 0,
        Max = opts.Max or 100,
        _id = id,
        _changed = {},
        _rayfield = nil,
    }
    function s:SetValue(v)
        self.Value = v
        if self._rayfield and self._rayfield.Set then self._rayfield:Set(v) end
        for _, cb in ipairs(self._changed) do task.spawn(cb, v) end
    end
    function s:SetMax(v) self.Max = v end
    function s:SetMin(v) self.Min = v end
    function s:OnChanged(cb) table.insert(self._changed, cb) end
    return s
end

local function makeDropdown(id, opts)
    opts = opts or {}
    local d = {
        Value = opts.Default or (opts.Multi and {} or ""),
        _id = id,
        _changed = {},
        _rayfield = nil,
    }
    function d:SetValue(v)
        self.Value = v
        if self._rayfield and self._rayfield.Set then self._rayfield:Set(v) end
        for _, cb in ipairs(self._changed) do task.spawn(cb, v) end
    end
    function d:OnChanged(cb) table.insert(self._changed, cb) end
    function d:SetValues(_) end -- Linoria API: re-set the option list; no-op here for spike
    return d
end

local function makeInput(id, opts)
    opts = opts or {}
    local i = {
        Value = opts.Default or "",
        _id = id,
        _changed = {},
    }
    function i:SetValue(v) self.Value = v; for _, cb in ipairs(self._changed) do task.spawn(cb, v) end end
    function i:OnChanged(cb) table.insert(self._changed, cb) end
    return i
end

local function makeKeyPicker(id, opts)
    opts = opts or {}
    local k = {
        Value = opts.Default or "None",
        _id = id,
        _changed = {},
    }
    function k:GetState() return false end -- Rayfield mode: keybinds disabled
    function k:SetValue(_) end
    function k:OnChanged(cb) table.insert(self._changed, cb) end
    return k
end

local function makeColorPicker(id, opts)
    opts = opts or {}
    local c = {
        Value = opts.Default or Color3.fromRGB(255, 255, 255),
        _id = id,
        _changed = {},
    }
    function c:SetValue(v) self.Value = v; for _, cb in ipairs(self._changed) do task.spawn(cb, v) end end
    function c:OnChanged(cb) table.insert(self._changed, cb) end
    return c
end

-- ---------- Groupbox (== Rayfield Tab section) ----------

local Groupbox = {}
Groupbox.__index = Groupbox

-- Spike mode: don't swallow errors with pcall around Rayfield calls — surface
-- them so we can see which API mismatch is breaking each widget.
local function safeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok and _G.DEBUG then
        warn("[mspain-t adapter] " .. (label or "?") .. ": " .. tostring(err))
    end
    return ok and err or nil
end

function Groupbox:AddToggle(id, opts)
    opts = opts or {}
    local t = makeToggle(id, opts)
    shared.Toggles[id] = t

    t._rayfield = self._tab:CreateToggle({
        Name = opts.Text or id,
        CurrentValue = t.Value,
        Callback = function(v)
            t.Value = v
            if opts.Callback then safeCall(function() opts.Callback(v) end, "Toggle " .. id .. " Callback") end
            for _, cb in ipairs(t._changed) do task.spawn(cb, v) end
        end,
    })
    return self
end

function Groupbox:AddSlider(id, opts)
    opts = opts or {}
    local s = makeSlider(id, opts)
    shared.Options[id] = s

    s._rayfield = self._tab:CreateSlider({
        Name = opts.Text or id,
        Range = { s.Min, s.Max },
        Increment = opts.Increment or 1,
        CurrentValue = s.Value,
        Suffix = opts.Suffix or "",
        Callback = function(v)
            s.Value = v
            if opts.Callback then safeCall(function() opts.Callback(v) end, "Slider " .. id .. " Callback") end
            for _, cb in ipairs(s._changed) do task.spawn(cb, v) end
        end,
    })
    return self
end

function Groupbox:AddDropdown(id, opts)
    opts = opts or {}
    local d = makeDropdown(id, opts)
    shared.Options[id] = d

    local defaultOpt = opts.Default
    local currentOption
    if opts.Multi then
        currentOption = (typeof(defaultOpt) == "table") and defaultOpt or {}
    else
        currentOption = (defaultOpt ~= nil) and { tostring(defaultOpt) } or {}
    end

    d._rayfield = self._tab:CreateDropdown({
        Name = opts.Text or id,
        Options = opts.Values or {},
        CurrentOption = currentOption,
        MultipleOptions = opts.Multi or false,
        Callback = function(v)
            d.Value = v
            if opts.Callback then safeCall(function() opts.Callback(v) end, "Dropdown " .. id .. " Callback") end
            for _, cb in ipairs(d._changed) do task.spawn(cb, v) end
        end,
    })
    return self
end

function Groupbox:AddButton(text, callback)
    local label, fn
    if typeof(text) == "table" then
        label, fn = text.Text or "Button", text.Func or callback
    else
        label, fn = text, callback
    end
    self._tab:CreateButton({
        Name = label,
        Callback = function()
            if fn then safeCall(fn, "Button " .. tostring(label)) end
        end,
    })
    return self
end

function Groupbox:AddInput(id, opts)
    opts = opts or {}
    local i = makeInput(id, opts)
    shared.Options[id] = i
    i._rayfield = self._tab:CreateInput({
        Name = opts.Text or id,
        CurrentValue = i.Value,
        PlaceholderText = opts.Placeholder or "",
        RemoveTextAfterFocusLost = opts.ClearOnFocusLost or false,
        Callback = function(v)
            i.Value = v
            if opts.Callback then safeCall(function() opts.Callback(v) end, "Input " .. id .. " Callback") end
            for _, cb in ipairs(i._changed) do task.spawn(cb, v) end
        end,
    })
    return self
end

function Groupbox:AddKeyPicker(id, opts)
    opts = opts or {}
    local k = makeKeyPicker(id, opts)
    shared.Options[id] = k
    -- Keybinds disabled in Rayfield mode by user choice.
    return self
end

function Groupbox:AddColorPicker(id, opts)
    opts = opts or {}
    local c = makeColorPicker(id, opts)
    shared.Options[id] = c
    c._rayfield = self._tab:CreateColorPicker({
        Name = opts.Text or id,
        Color = c.Value,
        Callback = function(v)
            c.Value = v
            if opts.Callback then safeCall(function() opts.Callback(v) end, "ColorPicker " .. id .. " Callback") end
            for _, cb in ipairs(c._changed) do task.spawn(cb, v) end
        end,
    })
    return self
end

function Groupbox:AddLabel(text, _doSizing)
    -- Linoria's AddLabel returns a label object with :SetText. We need the same
    -- so Self-Test's live status updates work.
    local labelObj = {
        Text = tostring(text or ""),
        _rayfield = nil,
    }
    labelObj._rayfield = self._tab:CreateLabel(labelObj.Text)
    function labelObj:SetText(t)
        self.Text = tostring(t or "")
        if self._rayfield and self._rayfield.Set then
            self._rayfield:Set(self.Text)
        end
    end
    return labelObj
end

function Groupbox:AddDivider()
    self._tab:CreateSection("─────")
    return self
end

-- ---------- Tab ----------

local Tab = {}
Tab.__index = Tab

local function newGroupbox(rayfieldTab)
    return setmetatable({ _tab = rayfieldTab }, Groupbox)
end

function Tab:AddLeftGroupbox(name)
    pcall(function() self._tab:CreateSection(name or "Group") end)
    return newGroupbox(self._tab)
end
Tab.AddRightGroupbox = Tab.AddLeftGroupbox

-- Tabbox: Linoria's tab-within-tab pattern. Rayfield has no analog, so each
-- AddTab(name) just creates a labeled section inside the parent Rayfield tab.
local Tabbox = {}
Tabbox.__index = Tabbox
function Tabbox:AddTab(name)
    pcall(function() self._tab:CreateSection(name or "Sub") end)
    return newGroupbox(self._tab)
end

function Tab:AddLeftTabbox()
    return setmetatable({ _tab = self._tab }, Tabbox)
end
Tab.AddRightTabbox = Tab.AddLeftTabbox

function Tab:UpdateWarningBox(_) return self end

-- ---------- Window ----------

local Window = {}
Window.__index = Window

function Window:AddTab(name)
    local rayTab
    pcall(function() rayTab = self._window:CreateTab(name) end)
    if not rayTab then
        -- Rayfield refused; return a chainable inert tab so feature code keeps running.
        rayTab = setmetatable({}, { __index = function() return function() end end })
    end
    return setmetatable({ _tab = rayTab }, Tab)
end

-- ---------- Bootstrap ----------

function Adapter.bootstrap()
    shared.Toggles = shared.Toggles or {}
    shared.Options = shared.Options or {}

    local unloadCallbacks = {}

    local Library = {
        -- non-widget surface that feature code reads directly
        MainColor = Color3.fromRGB(28, 28, 28),
        AccentColor = Color3.fromRGB(0, 100, 200),
        FontColor = Color3.fromRGB(255, 255, 255),
        IsMobile = false,
        KeybindFrame = { Visible = false },
        NotifySide = "Right",
        ShowCustomCursor = false,
        Toggled = true,
        ToggleKeybind = nil,
        Unloaded = false,
    }

    function Library:CreateWindow(opts)
        local window
        pcall(function()
            window = Rayfield:CreateWindow({
                Name = opts.Title or "mspain-t",
                LoadingTitle = opts.Title or "mspain-t",
                LoadingSubtitle = "Loading...",
                ConfigurationSaving = { Enabled = false },
                Discord = { Enabled = false },
                KeySystem = false,
            })
        end)
        return setmetatable({ _window = window }, Window)
    end

    function Library:Notify(text, time)
        pcall(function()
            Rayfield:Notify({
                Title = "mspain-t",
                Content = tostring(text or ""),
                Duration = time or 4,
            })
        end)
    end

    function Library:AddToRegistry(_, _) end -- theme-color registry; no-op (no theming)
    function Library:OnUnload(cb) table.insert(unloadCallbacks, cb) end
    function Library:Unload()
        Library.Unloaded = true
        for _, cb in ipairs(unloadCallbacks) do pcall(cb) end
        pcall(function() if Rayfield.Destroy then Rayfield:Destroy() end end)
    end

    -- SaveManager: per-user spec, persist toggle/option state but NOT theme.
    -- Spike: no-op stubs so initialization completes; wire in Phase E2.
    local SaveManager = {}
    function SaveManager:SetLibrary(_) end
    function SaveManager:SetFolder(_) end
    function SaveManager:SetSubFolder(_) end
    function SaveManager:IgnoreThemeSettings() end
    function SaveManager:BuildConfigSection(_) end
    function SaveManager:LoadAutoloadConfig() end

    -- ThemeManager: explicitly out of scope per user — no theme persistence.
    local ThemeManager = {}
    function ThemeManager:SetLibrary(_) end
    function ThemeManager:ApplyToTab(_) end

    return Library, SaveManager, ThemeManager
end

return Adapter
