--[[
    PlayerDataManager.server.lua
    Handles player data initialisation, DataStore persistence, and leaderstats.

    Responsibilities:
        • Create a fresh data template for new players
        • Load saved data from DataStoreService on join
        • Save data to DataStore on leave and at regular intervals
        • Expose an in-memory cache (PlayerData) used by other server scripts
        • Set up leaderstats (Cash, BrainrotsOwned, Rebirths)
--]]

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared     = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(Shared:WaitForChild("GameConfig", 10))
local Remotes    = require(Shared:WaitForChild("Remotes",    10))

-- DataStore instance
local playerDataStore = DataStoreService:GetDataStore("StealABrainrot_PlayerData_v1")

-- In-memory table:  [player] = dataTable
local PlayerData = {}

-- ── Data template ─────────────────────────────────────────────────────────

-- Returns a fresh data table for a brand-new player
local function NewPlayerData()
    return {
        cash          = GameConfig.StartingCash,
        brainrots     = {},     -- array of brainrot ids owned
        baseLevel     = 1,
        rebirths      = 0,
        traps         = {},     -- array of placed trap types
        lockExpiry    = 0,      -- os.time() when the base lock expires
        stealCooldown = 0,      -- os.time() when the next steal is allowed
    }
end

-- ── Persistence ───────────────────────────────────────────────────────────

-- Load data from DataStore; fall back to fresh template on failure
local function LoadData(player)
    local key  = GameConfig.DataStoreKey .. player.UserId
    local data = nil
    local success, err = pcall(function()
        data = playerDataStore:GetAsync(key)
    end)

    if success and data then
        -- Merge with template to handle newly added fields gracefully
        local template = NewPlayerData()
        for k, v in pairs(template) do
            if data[k] == nil then
                data[k] = v
            end
        end
        return data
    else
        if not success then
            warn("[PlayerDataManager] Failed to load data for " .. player.Name .. ": " .. tostring(err))
        end
        return NewPlayerData()
    end
end

-- Save data to DataStore
local function SaveData(player)
    local data = PlayerData[player]
    if not data then return end

    local key = GameConfig.DataStoreKey .. player.UserId
    local success, err = pcall(function()
        playerDataStore:SetAsync(key, data)
    end)

    if not success then
        warn("[PlayerDataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
    end
end

-- ── Leaderstats ───────────────────────────────────────────────────────────

local function SetupLeaderstats(player, data)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name   = "leaderstats"
    leaderstats.Parent = player

    local cashStat = Instance.new("IntValue")
    cashStat.Name   = "Cash"
    cashStat.Value  = data.cash
    cashStat.Parent = leaderstats

    local brainrotStat = Instance.new("IntValue")
    brainrotStat.Name   = "Brainrots"
    brainrotStat.Value  = #data.brainrots
    brainrotStat.Parent = leaderstats

    local rebirthStat = Instance.new("IntValue")
    rebirthStat.Name   = "Rebirths"
    rebirthStat.Value  = data.rebirths
    rebirthStat.Parent = leaderstats
end

-- Refresh leaderstats values to match the current in-memory data
function UpdateLeaderstats(player)
    local data        = PlayerData[player]
    local leaderstats = player:FindFirstChild("leaderstats")
    if not data or not leaderstats then return end

    leaderstats.Cash.Value      = math.floor(data.cash)
    leaderstats.Brainrots.Value = #data.brainrots
    leaderstats.Rebirths.Value  = data.rebirths
end

-- ── Public API ────────────────────────────────────────────────────────────

-- Retrieve a player's in-memory data table (returns nil if not loaded yet)
function GetPlayerData(player)
    return PlayerData[player]
end

-- Push the current in-memory state to the client
local function SyncToClient(player)
    local data = PlayerData[player]
    if not data then return end
    Remotes.UpdatePlayerData:FireClient(player, {
        cash      = data.cash,
        brainrots = data.brainrots,
        rebirths  = data.rebirths,
        baseLevel = data.baseLevel,
        lockExpiry = data.lockExpiry,
    })
end

-- ── Player lifecycle ──────────────────────────────────────────────────────

local function OnPlayerAdded(player)
    local data = LoadData(player)
    PlayerData[player] = data
    SetupLeaderstats(player, data)
    SyncToClient(player)
end

local function OnPlayerRemoving(player)
    SaveData(player)
    PlayerData[player] = nil
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Handle players who joined before this script loaded
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(OnPlayerAdded, player)
end

-- ── Auto-save loop ────────────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(GameConfig.AutoSaveInterval)
        for _, player in ipairs(Players:GetPlayers()) do
            SaveData(player)
        end
    end
end)

-- ── RemoteFunction handler ────────────────────────────────────────────────

Remotes.GetPlayerData.OnServerInvoke = function(player)
    local data = PlayerData[player]
    if not data then return nil end
    -- Return a safe copy (no direct reference to internal table)
    return {
        cash       = data.cash,
        brainrots  = data.brainrots,
        rebirths   = data.rebirths,
        baseLevel  = data.baseLevel,
        lockExpiry = data.lockExpiry,
    }
end

-- ── Expose internals for other server scripts ─────────────────────────────
-- Other server scripts can require this module via a ModuleScript approach,
-- but since Roblox ServerScriptService scripts aren't directly require-able,
-- we store the API in a shared BindableFunction / _G approach.
-- We use _G for inter-script communication on the server only.

_G.PlayerDataManager = {
    GetData        = GetPlayerData,
    UpdateLeaderstats = UpdateLeaderstats,
    SyncToClient   = SyncToClient,
    SaveData       = SaveData,
}
