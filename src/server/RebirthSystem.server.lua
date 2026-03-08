--[[
    RebirthSystem.server.lua
    Handles the rebirth progression mechanic.

    On rebirth:
        • Player must have enough cash (cost scales exponentially)
        • All owned brainrots and cash are reset
        • Rebirth count increments
        • A permanent income multiplier is applied (stacks across rebirths)
        • Traps are also cleared (fresh start)
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared     = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(Shared:WaitForChild("GameConfig", 10))
local Remotes    = require(Shared:WaitForChild("Remotes",   10))

local PDM
local function GetPDM()
    if PDM then return PDM end
    local attempts = 0
    while not _G.PlayerDataManager and attempts < 30 do
        task.wait(0.1)
        attempts = attempts + 1
    end
    PDM = _G.PlayerDataManager
    return PDM
end

-- ── Cost calculation ──────────────────────────────────────────────────────

-- Returns the cash cost for the player's next rebirth
local function GetRebirthCost(currentRebirths)
    return math.floor(
        GameConfig.RebirthBaseCost
        * (GameConfig.RebirthCostMultiplier ^ currentRebirths)
    )
end

-- ── Rebirth handler ───────────────────────────────────────────────────────

local function OnRebirth(player)
    local pdm  = GetPDM()
    if not pdm then return end
    local data = pdm.GetData(player)
    if not data then return end

    local cost = GetRebirthCost(data.rebirths)

    if data.cash < cost then
        Remotes.UpdatePlayerData:FireClient(player, {
            error = "Need " .. cost .. " cash to rebirth! You have " .. math.floor(data.cash) .. "."
        })
        return
    end

    -- Perform rebirth
    data.rebirths  = data.rebirths + 1
    data.cash      = GameConfig.StartingCash  -- reset cash to starting amount
    data.brainrots = {}                       -- clear brainrots
    data.traps     = {}                       -- clear traps
    data.lockExpiry = 0

    pdm.UpdateLeaderstats(player)
    pdm.SyncToClient(player)

    -- Notify player of success and next cost
    local nextCost = GetRebirthCost(data.rebirths)
    Remotes.UpdatePlayerData:FireClient(player, {
        rebirthSuccess = true,
        message        = "Rebirth " .. data.rebirths .. " complete! Next rebirth costs " .. nextCost .. ".",
        nextRebirthCost = nextCost,
    })
end

-- ── Connect remote ────────────────────────────────────────────────────────

Remotes.Rebirth:Connect(OnRebirth)
