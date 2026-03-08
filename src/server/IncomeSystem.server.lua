--[[
    IncomeSystem.server.lua
    Runs a per-second loop that calculates and awards passive income to every
    online player based on the brainrots they own and any rebirth multipliers.

    Depends on:
        _G.PlayerDataManager  (set by PlayerDataManager.server.lua)
        Shared/BrainrotData
        Shared/GameConfig
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared", 10)
local BrainrotData = require(Shared:WaitForChild("BrainrotData", 10))
local GameConfig   = require(Shared:WaitForChild("GameConfig",   10))

-- Wait for PlayerDataManager to be ready
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

-- ── Income calculation ────────────────────────────────────────────────────

-- Returns the total income-per-second for the given player data snapshot
local function CalculateIncome(data)
    local total = 0
    for _, brainrotId in ipairs(data.brainrots) do
        local brainrot = BrainrotData.ById[brainrotId]
        if brainrot then
            total = total + brainrot.income
        end
    end

    -- Apply rebirth multiplier: each rebirth multiplies income by the config factor
    if data.rebirths > 0 then
        total = total * (GameConfig.RebirthIncomeMultiplier ^ data.rebirths)
    end

    return total
end

-- ── Main income loop ──────────────────────────────────────────────────────

task.spawn(function()
    local pdm = GetPDM()
    if not pdm then
        warn("[IncomeSystem] PlayerDataManager not available – income loop will not run.")
        return
    end

    while true do
        task.wait(1)

        for _, player in ipairs(Players:GetPlayers()) do
            local data = pdm.GetData(player)
            if data then
                local income = CalculateIncome(data)
                if income > 0 then
                    data.cash = data.cash + income
                    pdm.UpdateLeaderstats(player)
                    -- Throttle client syncs to avoid spamming every second;
                    -- the HUD client script reads leaderstats directly.
                end
            end
        end
    end
end)
