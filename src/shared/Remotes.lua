--[[
    Remotes.lua
    Shared module that creates (on the server) or retrieves (on the client)
    all RemoteEvents and RemoteFunctions used for client-server communication.

    Usage:
        local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
        Remotes.BuyBrainrot:FireServer(brainrotId)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local isServer = RunService:IsServer()

-- Folder that holds all remote objects inside ReplicatedStorage
local FOLDER_NAME = "GameRemotes"

local Remotes = {}

-- ── Remote definitions ────────────────────────────────────────────────────
-- Each entry:  [name] = "RemoteEvent" | "RemoteFunction"

local remoteDefs = {
    -- Shop
    BuyBrainrot       = "RemoteEvent",    -- client → server: purchase a brainrot
    SellBrainrot      = "RemoteEvent",    -- client → server: sell a brainrot
    ShopUpdate        = "RemoteEvent",    -- server → client: push new shop listing

    -- Stealing
    StartSteal        = "RemoteEvent",    -- client → server: begin a steal attempt
    CancelSteal       = "RemoteEvent",    -- client → server: cancel ongoing steal

    -- Base Defense
    LockBase          = "RemoteEvent",    -- client → server: activate base lock
    PlaceTrap         = "RemoteEvent",    -- client → server: place a trap in base

    -- Progression
    Rebirth           = "RemoteEvent",    -- client → server: trigger rebirth

    -- Notifications / sync
    StealAlert        = "RemoteEvent",    -- server → client: alert base owner of raid
    UpdatePlayerData  = "RemoteEvent",    -- server → client: push updated player state

    -- Remote Functions (two-way)
    GetPlayerData     = "RemoteFunction", -- client → server: request own data snapshot
}

-- ── Setup / retrieval ─────────────────────────────────────────────────────

local function GetOrCreateFolder()
    if isServer then
        local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name   = FOLDER_NAME
            folder.Parent = ReplicatedStorage
        end
        return folder
    else
        -- On the client, wait for the folder to be replicated
        return ReplicatedStorage:WaitForChild(FOLDER_NAME, 10)
    end
end

local function Setup()
    local folder = GetOrCreateFolder()
    if not folder then
        warn("[Remotes] Could not find GameRemotes folder in ReplicatedStorage.")
        return
    end

    for name, kind in pairs(remoteDefs) do
        if isServer then
            -- Create the remote if it doesn't exist yet
            if not folder:FindFirstChild(name) then
                local remote = Instance.new(kind)
                remote.Name   = name
                remote.Parent = folder
            end
            Remotes[name] = folder:FindFirstChild(name)
        else
            -- Wait for the server to create it
            Remotes[name] = folder:WaitForChild(name, 10)
            if not Remotes[name] then
                warn("[Remotes] Timed out waiting for remote: " .. name)
            end
        end
    end
end

Setup()

return Remotes
