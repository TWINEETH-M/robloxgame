--[[
    StealGui.client.lua
    UI for the raiding / stealing mechanic.

    Features:
        • "Raid" button appears when the player is near another player's base
        • Steal progress bar (StealTime-second countdown)
        • Cancel button during an active steal
        • Alarm notification overlay when YOUR base is being raided
        • Steal cooldown display
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared     = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(Shared:WaitForChild("GameConfig", 10))
local Remotes    = require(Shared:WaitForChild("Remotes",   10))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Screen GUI ────────────────────────────────────────────────────────────

local screenGui           = Instance.new("ScreenGui")
screenGui.Name            = "StealGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = playerGui

-- ── Raid button (bottom right) ────────────────────────────────────────────

local raidBtn             = Instance.new("TextButton")
raidBtn.Name              = "RaidButton"
raidBtn.Size              = UDim2.new(0, 120, 0, 48)
raidBtn.Position          = UDim2.new(1, -138, 1, -70)
raidBtn.BackgroundColor3  = Color3.fromRGB(200, 40, 40)
raidBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
raidBtn.Font              = Enum.Font.GothamBold
raidBtn.TextScaled        = true
raidBtn.Text              = "⚔️ Raid"
raidBtn.BorderSizePixel   = 0
raidBtn.Visible           = false     -- shown only when near a valid target
raidBtn.Parent            = screenGui

local rdCorner = Instance.new("UICorner")
rdCorner.CornerRadius = UDim.new(0, 8)
rdCorner.Parent = raidBtn

-- ── Steal progress overlay (centre screen) ────────────────────────────────

local progressFrame       = Instance.new("Frame")
progressFrame.Name        = "StealProgress"
progressFrame.Size        = UDim2.new(0, 320, 0, 90)
progressFrame.Position    = UDim2.new(0.5, -160, 0.5, 80)
progressFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
progressFrame.BackgroundTransparency = 0.1
progressFrame.BorderSizePixel = 0
progressFrame.Visible     = false
progressFrame.Parent      = screenGui

local pfCorner = Instance.new("UICorner")
pfCorner.CornerRadius = UDim.new(0, 10)
pfCorner.Parent = progressFrame

local stealLabel          = Instance.new("TextLabel")
stealLabel.Size           = UDim2.new(1, 0, 0, 30)
stealLabel.Position       = UDim2.new(0, 0, 0, 6)
stealLabel.BackgroundTransparency = 1
stealLabel.Text           = "⚔️ Stealing... stay inside!"
stealLabel.TextColor3     = Color3.fromRGB(255, 100, 100)
stealLabel.Font           = Enum.Font.GothamBold
stealLabel.TextScaled     = true
stealLabel.Parent         = progressFrame

-- Progress bar background
local barBg               = Instance.new("Frame")
barBg.Size                = UDim2.new(1, -20, 0, 18)
barBg.Position            = UDim2.new(0, 10, 0, 40)
barBg.BackgroundColor3    = Color3.fromRGB(50, 50, 60)
barBg.BorderSizePixel     = 0
barBg.Parent              = progressFrame

local bbCorner = Instance.new("UICorner")
bbCorner.CornerRadius = UDim.new(0, 6)
bbCorner.Parent = barBg

-- Progress bar fill
local barFill             = Instance.new("Frame")
barFill.Name              = "Fill"
barFill.Size              = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3  = Color3.fromRGB(220, 60, 60)
barFill.BorderSizePixel   = 0
barFill.Parent            = barBg

local bfCorner = Instance.new("UICorner")
bfCorner.CornerRadius = UDim.new(0, 6)
bfCorner.Parent = barFill

-- Cancel button
local cancelBtn           = Instance.new("TextButton")
cancelBtn.Size            = UDim2.new(0, 100, 0, 26)
cancelBtn.Position        = UDim2.new(0.5, -50, 0, 62)
cancelBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
cancelBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
cancelBtn.Font            = Enum.Font.Gotham
cancelBtn.TextScaled      = true
cancelBtn.Text            = "Cancel"
cancelBtn.BorderSizePixel = 0
cancelBtn.Parent          = progressFrame

local caCorner = Instance.new("UICorner")
caCorner.CornerRadius = UDim.new(0, 6)
caCorner.Parent = cancelBtn

-- ── Alarm notification (top centre) ──────────────────────────────────────

local alarmFrame          = Instance.new("Frame")
alarmFrame.Name           = "AlarmFrame"
alarmFrame.Size           = UDim2.new(0, 380, 0, 60)
alarmFrame.Position       = UDim2.new(0.5, -190, 0, 20)
alarmFrame.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
alarmFrame.BackgroundTransparency = 0.15
alarmFrame.BorderSizePixel = 0
alarmFrame.Visible        = false
alarmFrame.Parent         = screenGui

local afCorner = Instance.new("UICorner")
afCorner.CornerRadius = UDim.new(0, 10)
afCorner.Parent = alarmFrame

local alarmLabel          = Instance.new("TextLabel")
alarmLabel.Size           = UDim2.new(1, -16, 1, 0)
alarmLabel.Position       = UDim2.new(0, 8, 0, 0)
alarmLabel.BackgroundTransparency = 1
alarmLabel.Text           = "🚨 RAID ALERT!"
alarmLabel.TextColor3     = Color3.fromRGB(255, 255, 255)
alarmLabel.Font           = Enum.Font.GothamBold
alarmLabel.TextScaled     = true
alarmLabel.Parent         = alarmFrame

-- ── Cooldown label ────────────────────────────────────────────────────────

local cooldownLabel       = Instance.new("TextLabel")
cooldownLabel.Name        = "StealCooldown"
cooldownLabel.Size        = UDim2.new(0, 200, 0, 28)
cooldownLabel.Position    = UDim2.new(1, -218, 1, -120)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.Text        = ""
cooldownLabel.TextColor3  = Color3.fromRGB(255, 200, 100)
cooldownLabel.Font        = Enum.Font.Gotham
cooldownLabel.TextScaled  = true
cooldownLabel.TextXAlignment = Enum.TextXAlignment.Right
cooldownLabel.Parent      = screenGui

-- ── State ─────────────────────────────────────────────────────────────────

local stealActive   = false
local stealCooldown = 0       -- os.time() when cooldown expires
local nearbyTarget  = nil     -- UserId of the nearest target base player

-- ── Proximity detection ───────────────────────────────────────────────────

-- Check if the local player is standing near another player's base boundary
local function FindNearbyTarget()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local baseFolder = workspace:FindFirstChild("PlayerBases")
    if not baseFolder then return nil end

    for _, base in ipairs(baseFolder:GetChildren()) do
        local boundary = base:FindFirstChild("Boundary")
        if boundary then
            local dist = (root.Position - boundary.Position).Magnitude
            local range = GameConfig.StealProximity + boundary.Size.Magnitude / 2
            if dist <= range then
                -- Parse UserId from base name "Base_<userId>"
                local uid = tonumber(base.Name:match("Base_(%d+)"))
                if uid and uid ~= player.UserId then
                    return uid
                end
            end
        end
    end
    return nil
end

-- ── Progress bar animation ────────────────────────────────────────────────

local stealCoroutine = nil

local function StartProgressBar(duration)
    if stealCoroutine then
        task.cancel(stealCoroutine)
    end
    progressFrame.Visible = true
    barFill.Size = UDim2.new(0, 0, 1, 0)

    stealCoroutine = task.spawn(function()
        local elapsed  = 0
        local interval = 0.05
        while elapsed < duration and stealActive do
            task.wait(interval)
            elapsed = elapsed + interval
            local pct = math.clamp(elapsed / duration, 0, 1)
            barFill.Size = UDim2.new(pct, 0, 1, 0)
        end
        progressFrame.Visible = false
        stealActive = false
    end)
end

-- ── Remote handlers ───────────────────────────────────────────────────────

Remotes.UpdatePlayerData.OnClientEvent:Connect(function(data)
    if data.stealStarted then
        stealActive = true
        StartProgressBar(data.stealTime or GameConfig.StealTime)
    end

    if data.stealCancelled or data.stealSuccess then
        stealActive = false
        progressFrame.Visible = false
        if stealCoroutine then
            task.cancel(stealCoroutine)
            stealCoroutine = nil
        end
    end

    if data.stealSuccess then
        -- Brief success flash
        stealLabel.Text = "✅ Steal successful!"
        progressFrame.Visible = true
        task.delay(2, function()
            progressFrame.Visible = false
            stealLabel.Text = "⚔️ Stealing... stay inside!"
        end)
    end

    -- Update steal cooldown tracking
    if data.stealCooldown then
        stealCooldown = data.stealCooldown
    end
end)

-- Alert when YOUR base is raided
Remotes.StealAlert.OnClientEvent:Connect(function(alertData)
    if alertData.message then
        alarmLabel.Text   = "🚨 " .. alertData.message
        alarmFrame.Visible = true
        task.delay(5, function()
            alarmFrame.Visible = false
        end)
    end
end)

-- ── Raid button handler ───────────────────────────────────────────────────

raidBtn.MouseButton1Click:Connect(function()
    if stealActive then return end
    if os.time() < stealCooldown then return end
    local target = nearbyTarget
    if not target then return end
    Remotes.StartSteal:FireServer(target)
end)

cancelBtn.MouseButton1Click:Connect(function()
    stealActive = false
    Remotes.CancelSteal:FireServer()
    progressFrame.Visible = false
end)

-- ── Proximity & cooldown polling loop ─────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(0.5)

        -- Update cooldown display
        local remaining = math.ceil(stealCooldown - os.time())
        if remaining > 0 then
            cooldownLabel.Text = "⏱ Steal cooldown: " .. remaining .. "s"
            raidBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        else
            cooldownLabel.Text = ""
            raidBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        end

        -- Check proximity
        nearbyTarget = FindNearbyTarget()
        raidBtn.Visible = nearbyTarget ~= nil and not stealActive
    end
end)
