--!nocheck
-- DOORS structural dumper. Run this via Macsploit while in a DOORS server
-- (lobby or in-game — coverage differs).
--
-- Use: copy this file into your Macsploit Workspace (or paste it into
-- Macsploit's editor) and execute.
--
-- Output: ~/Documents/Macsploit Workspace/mspaint-t-dumps/*.txt
-- Each file is an indented tree of instance names + ClassNames so you can
-- diff against what Src/Places/{Loaders,Utils}/Doors/Doors/*.luau expects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local DUMP_FOLDER = "mspaint-t-dumps"
local MAX_CHILDREN_PER_NODE = 200 -- prevent runaway dumps on huge models

if typeof(isfolder) == "function" and not isfolder(DUMP_FOLDER) then
    if typeof(makefolder) == "function" then makefolder(DUMP_FOLDER) end
end

local function safeClass(inst)
    local ok, cls = pcall(function() return inst.ClassName end)
    return ok and cls or "?"
end

local function safeName(inst)
    local ok, n = pcall(function() return inst.Name end)
    return ok and n or "?"
end

local function dumpTree(root, maxDepth)
    if root == nil then return "(target not found)\n" end

    local lines = {}
    local function visit(inst, depth)
        local indent = string.rep("  ", depth)
        local cls = safeClass(inst)
        local name = safeName(inst)
        local extra = ""

        if inst:IsA("StringValue") or inst:IsA("IntValue") or inst:IsA("NumberValue") or inst:IsA("BoolValue") then
            local ok, v = pcall(function() return inst.Value end)
            if ok then extra = " = " .. tostring(v) end
        elseif inst:IsA("ObjectValue") then
            local ok, v = pcall(function() return inst.Value end)
            if ok and v then extra = " -> " .. v:GetFullName() end
        end

        table.insert(lines, string.format("%s- [%s] %s%s", indent, cls, name, extra))

        if depth >= maxDepth then
            local children = inst:GetChildren()
            if #children > 0 then
                table.insert(lines, indent .. "  (… " .. #children .. " more children, max depth reached)")
            end
            return
        end

        local children = inst:GetChildren()
        for i, child in ipairs(children) do
            if i > MAX_CHILDREN_PER_NODE then
                table.insert(lines, indent .. "  (… " .. (#children - MAX_CHILDREN_PER_NODE) .. " more, truncated)")
                break
            end
            visit(child, depth + 1)
        end
    end

    visit(root, 0)
    return table.concat(lines, "\n") .. "\n"
end

local function writeReport(name, content)
    if typeof(writefile) ~= "function" then
        warn("[dump-doors] no writefile — skipping " .. name)
        return
    end
    writefile(DUMP_FOLDER .. "/" .. name, content)
    print("[dump-doors] wrote " .. DUMP_FOLDER .. "/" .. name)
end

local function gameDataDump()
    local gd = ReplicatedStorage:FindFirstChild("GameData")
    if not gd then return "(GameData missing)" end
    local out = { "Floor = " .. tostring(gd:FindFirstChild("Floor") and gd.Floor.Value) }
    if gd:FindFirstChild("LatestRoom") then
        table.insert(out, "LatestRoom = " .. tostring(gd.LatestRoom.Value))
    end
    table.insert(out, "")
    table.insert(out, "Full tree:")
    table.insert(out, dumpTree(gd, 3))
    return table.concat(out, "\n")
end

local function attributesOf(inst)
    if not inst then return "(missing)" end
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if not ok or not attrs then return "(no attributes)" end
    local out = {}
    for k, v in pairs(attrs) do
        table.insert(out, string.format("%s = %s (%s)", k, tostring(v), typeof(v)))
    end
    table.sort(out)
    return table.concat(out, "\n")
end

local function summary()
    local game = game
    return string.format(
        "PlaceId: %d\nGameId: %d\nLocalPlayer: %s\nFloor: %s\nLatestRoom: %s\nCurrentRoom: %s\nAlive: %s\nServer: %s\n",
        game.PlaceId,
        game.GameId,
        LocalPlayer.Name,
        tostring(ReplicatedStorage:FindFirstChild("GameData") and ReplicatedStorage.GameData:FindFirstChild("Floor") and ReplicatedStorage.GameData.Floor.Value),
        tostring(ReplicatedStorage:FindFirstChild("GameData") and ReplicatedStorage.GameData:FindFirstChild("LatestRoom") and ReplicatedStorage.GameData.LatestRoom.Value),
        tostring(LocalPlayer:GetAttribute("CurrentRoom")),
        tostring(LocalPlayer:GetAttribute("Alive")),
        tostring(game.JobId)
    )
end

-- --- Targets ---
local mainUI = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainUI")
local initiator = mainUI and mainUI:FindFirstChild("Initiator")
local mainGame = initiator and initiator:FindFirstChild("Main_Game")
local mainLobby = initiator and initiator:FindFirstChild("Main_Lobby")
local currentRooms = Workspace:FindFirstChild("CurrentRooms")
local firstRoom = currentRooms and (currentRooms:FindFirstChild("0") or currentRooms:GetChildren()[1])

local reports = {
    { name = "00_summary.txt", content = summary() },

    -- ReplicatedStorage
    { name = "rs_top.txt", content = dumpTree(ReplicatedStorage, 1) },
    { name = "rs_ModulesClient.txt", content = dumpTree(ReplicatedStorage:FindFirstChild("ModulesClient"), 3) },
    { name = "rs_GameData.txt", content = gameDataDump() },
    { name = "rs_RemotesFolder.txt", content = dumpTree(ReplicatedStorage:FindFirstChild("RemotesFolder"), 2) },
    { name = "rs_FloorReplicated.txt", content = dumpTree(ReplicatedStorage:FindFirstChild("FloorReplicated"), 2) },
    { name = "rs_LiveModifiers.txt", content = dumpTree(ReplicatedStorage:FindFirstChild("LiveModifiers"), 2) },
    { name = "rs_VoiceActing.txt", content = dumpTree(ReplicatedStorage:FindFirstChild("VoiceActing"), 2) },
    { name = "rs_EntityInfo.txt", content = dumpTree(ReplicatedStorage:FindFirstChild("EntityInfo"), 2) },

    -- Player UI
    { name = "ui_MainUI.txt", content = dumpTree(mainUI, 3) },
    { name = "ui_Initiator.txt", content = dumpTree(initiator, 4) },
    { name = "ui_Main_Game.txt", content = dumpTree(mainGame, 4) },
    { name = "ui_Main_Lobby.txt", content = dumpTree(mainLobby, 4) },

    -- Workspace
    { name = "ws_top.txt", content = dumpTree(Workspace, 1) },
    { name = "ws_first_room.txt", content = dumpTree(firstRoom, 4) },
    { name = "ws_first_room_attrs.txt", content = attributesOf(firstRoom) },
    { name = "ws_drops.txt", content = dumpTree(Workspace:FindFirstChild("Drops"), 2) },
}

for _, r in ipairs(reports) do
    pcall(writeReport, r.name, r.content)
end

print(string.format("[dump-doors] done. %d reports under %s/", #reports, DUMP_FOLDER))
