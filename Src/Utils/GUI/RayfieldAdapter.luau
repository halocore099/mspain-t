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

local Rayfield = require("Utils/GUI/RayfieldLib")

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

function Groupbox:AddToggle(id, opts)
    opts = opts or {}
    local t = makeToggle(id, opts)
    shared.Toggles[id] = t

    local ok, rf = pcall(function()
        return self._tab:CreateToggle({
            Name = opts.Text or id,
            CurrentValue = t.Value,
            Callback = function(v)
                t.Value = v
                if opts.Callback then pcall(opts.Callback, v) end
                for _, cb in ipairs(t._changed) do task.spawn(cb, v) end
            end,
        })
    end)
    if ok then t._rayfield = rf end
    return self
end

function Groupbox:AddSlider(id, opts)
    opts = opts or {}
    local s = makeSlider(id, opts)
    shared.Options[id] = s

    local ok, rf = pcall(function()
        return self._tab:CreateSlider({
            Name = opts.Text or id,
            Range = { s.Min, s.Max },
            Increment = opts.Increment or 1,
            CurrentValue = s.Value,
            Callback = function(v)
                s.Value = v
                if opts.Callback then pcall(opts.Callback, v) end
                for _, cb in ipairs(s._changed) do task.spawn(cb, v) end
            end,
        })
    end)
    if ok then s._rayfield = rf end
    return self
end

function Groupbox:AddDropdown(id, opts)
    opts = opts or {}
    local d = makeDropdown(id, opts)
    shared.Options[id] = d

    pcall(function()
        d._rayfield = self._tab:CreateDropdown({
            Name = opts.Text or id,
            Options = opts.Values or {},
            CurrentOption = (opts.Multi and {}) or (opts.Default and { opts.Default } or {}),
            MultipleOptions = opts.Multi or false,
            Callback = function(v)
                d.Value = v
                if opts.Callback then pcall(opts.Callback, v) end
                for _, cb in ipairs(d._changed) do task.spawn(cb, v) end
            end,
        })
    end)
    return self
end

function Groupbox:AddButton(text, callback)
    -- Linoria supports both AddButton("text", fn) and AddButton({Text=..., Func=...}) overloads.
    local label, fn
    if typeof(text) == "table" then
        label, fn = text.Text or "Button", text.Func or callback
    else
        label, fn = text, callback
    end
    pcall(function()
        self._tab:CreateButton({
            Name = label,
            Callback = function() if fn then pcall(fn) end end,
        })
    end)
    return self
end

function Groupbox:AddInput(id, opts)
    opts = opts or {}
    local i = makeInput(id, opts)
    shared.Options[id] = i
    pcall(function()
        self._tab:CreateInput({
            Name = opts.Text or id,
            CurrentValue = i.Value,
            PlaceholderText = opts.Placeholder or "",
            RemoveTextAfterFocusLost = opts.ClearOnFocusLost or false,
            Callback = function(v)
                i.Value = v
                if opts.Callback then pcall(opts.Callback, v) end
                for _, cb in ipairs(i._changed) do task.spawn(cb, v) end
            end,
        })
    end)
    return self
end

function Groupbox:AddKeyPicker(id, opts)
    opts = opts or {}
    local k = makeKeyPicker(id, opts)
    shared.Options[id] = k
    -- Keybinds disabled in Rayfield mode by user choice — no Rayfield CreateKeybind call.
    return self
end

function Groupbox:AddColorPicker(id, opts)
    opts = opts or {}
    local c = makeColorPicker(id, opts)
    shared.Options[id] = c
    pcall(function()
        c._rayfield = self._tab:CreateColorPicker({
            Name = opts.Text or id,
            Color = c.Value,
            Callback = function(v)
                c.Value = v
                if opts.Callback then pcall(opts.Callback, v) end
                for _, cb in ipairs(c._changed) do task.spawn(cb, v) end
            end,
        })
    end)
    return self
end

function Groupbox:AddLabel(text, _doSizing)
    pcall(function() self._tab:CreateLabel(tostring(text or "")) end)
    return self
end

function Groupbox:AddDivider()
    pcall(function() self._tab:CreateSection("") end) -- Rayfield uses empty section as divider
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
Tab.AddLeftTabbox = Tab.AddLeftGroupbox
Tab.AddRightTabbox = Tab.AddLeftGroupbox

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
