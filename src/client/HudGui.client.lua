--[[
    HudGui.client.lua
    Always-visible heads-up display showing:
        • Cash
        • Income per second
        • Brainrot count
        • Rebirth count

    Reads leaderstats for real-time updates and also listens for
    UpdatePlayerData events for detailed information like income rate.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared", 10)
local BrainrotData = require(Shared:WaitForChild("BrainrotData", 10))
local GameConfig   = require(Shared:WaitForChild("GameConfig",   10))
local Remotes      = require(Shared:WaitForChild("Remotes",      10))

local player      = Players.LocalPlayer
local playerGui   = player:WaitForChild("PlayerGui")

-- ── Build ScreenGui ───────────────────────────────────────────────────────

local screenGui       = Instance.new("ScreenGui")
screenGui.Name        = "HudGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent      = playerGui

-- Background frame (top-left corner)
local frame           = Instance.new("Frame")
frame.Name            = "HudFrame"
frame.Size            = UDim2.new(0, 220, 0, 130)
frame.Position        = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel  = 0
frame.Parent           = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop    = UDim.new(0, 8)
padding.PaddingLeft   = UDim.new(0, 10)
padding.PaddingRight  = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder   = Enum.SortOrder.LayoutOrder
layout.Padding     = UDim.new(0, 4)
layout.Parent      = frame

-- Helper to create a label row
local function MakeRow(name, icon, layoutOrder)
    local lbl           = Instance.new("TextLabel")
    lbl.Name            = name
    lbl.Size            = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3      = Color3.fromRGB(255, 255, 255)
    lbl.TextScaled      = true
    lbl.Font            = Enum.Font.GothamBold
    lbl.TextXAlignment  = Enum.TextXAlignment.Left
    lbl.Text            = icon .. " Loading..."
    lbl.LayoutOrder     = layoutOrder
    lbl.Parent          = frame
    return lbl
end

local cashLabel    = MakeRow("CashLabel",    "💰", 1)
local incomeLabel  = MakeRow("IncomeLabel",  "📈", 2)
local brainrotLabel = MakeRow("BrainrotLabel", "🧠", 3)
local rebirthLabel = MakeRow("RebirthLabel", "♻️", 4)

-- ── State ─────────────────────────────────────────────────────────────────

local cachedData = {
    cash      = 0,
    brainrots = {},
    rebirths  = 0,
}

local function CalculateIncome(brainrots, rebirths)
    local total = 0
    for _, id in ipairs(brainrots) do
        local b = BrainrotData.ById[id]
        if b then total = total + b.income end
    end
    if rebirths > 0 then
        total = total * (GameConfig.RebirthIncomeMultiplier ^ rebirths)
    end
    return total
end

-- ── Update display ────────────────────────────────────────────────────────

local function UpdateHud()
    local cash      = cachedData.cash
    local brainrots = cachedData.brainrots
    local rebirths  = cachedData.rebirths
    local income    = CalculateIncome(brainrots, rebirths)

    -- Format large numbers with commas
    local function FormatNumber(n)
        n = math.floor(n)
        local s   = tostring(n)
        local out = ""
        for i = 1, #s do
            -- Insert comma before every group of 3 digits from the right
            if i > 1 and (#s - i + 1) % 3 == 0 then out = out .. "," end
            out = out .. s:sub(i, i)
        end
        return out
    end

    cashLabel.Text      = "💰 Cash: $" .. FormatNumber(cash)
    incomeLabel.Text    = "📈 Income: $" .. string.format("%.1f", income) .. "/s"
    brainrotLabel.Text  = "🧠 Brainrots: " .. #brainrots .. "/" .. GameConfig.MaxBrainrotsPerBase
    rebirthLabel.Text   = "♻️ Rebirths: " .. rebirths
end

-- ── Listen for server updates ─────────────────────────────────────────────

Remotes.UpdatePlayerData.OnClientEvent:Connect(function(data)
    if data.cash      ~= nil then cachedData.cash      = data.cash      end
    if data.brainrots ~= nil then cachedData.brainrots = data.brainrots end
    if data.rebirths  ~= nil then cachedData.rebirths  = data.rebirths  end
    UpdateHud()
end)

-- Poll leaderstats every second as a fallback
task.spawn(function()
    while true do
        task.wait(1)
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cash = leaderstats:FindFirstChild("Cash")
            if cash then
                cachedData.cash = cash.Value
            end
        end
        UpdateHud()
    end
end)

-- Initial display
UpdateHud()
