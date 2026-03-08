--[[
    BaseGui.client.lua
    Base management UI.

    Features:
        • Owned brainrots list (scrollable, with sell buttons)
        • Base lock button with countdown timer
        • Trap placement buttons (one per trap type)
        • Income per second display
        • Rebirth button with cost display
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared", 10)
local BrainrotData = require(Shared:WaitForChild("BrainrotData", 10))
local GameConfig   = require(Shared:WaitForChild("GameConfig",   10))
local Remotes      = require(Shared:WaitForChild("Remotes",      10))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Cached player state ───────────────────────────────────────────────────

local playerState = {
    cash       = 0,
    brainrots  = {},
    rebirths   = 0,
    lockExpiry = 0,
}

local function GetRebirthCost()
    return math.floor(
        GameConfig.RebirthBaseCost
        * (GameConfig.RebirthCostMultiplier ^ playerState.rebirths)
    )
end

local function CalcIncome()
    local total = 0
    for _, id in ipairs(playerState.brainrots) do
        local b = BrainrotData.ById[id]
        if b then total = total + b.income end
    end
    if playerState.rebirths > 0 then
        total = total * (GameConfig.RebirthIncomeMultiplier ^ playerState.rebirths)
    end
    return total
end

-- ── Build ScreenGui ───────────────────────────────────────────────────────

local screenGui              = Instance.new("ScreenGui")
screenGui.Name               = "BaseGui"
screenGui.ResetOnSpawn       = false
screenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
screenGui.Parent             = playerGui

-- Toggle button (left side)
local toggleBtn              = Instance.new("TextButton")
toggleBtn.Name               = "BaseToggle"
toggleBtn.Size               = UDim2.new(0, 110, 0, 40)
toggleBtn.Position           = UDim2.new(0, 10, 1, -110)
toggleBtn.BackgroundColor3   = Color3.fromRGB(60, 40, 120)
toggleBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
toggleBtn.Font               = Enum.Font.GothamBold
toggleBtn.TextScaled         = true
toggleBtn.Text               = "🏠 Base"
toggleBtn.BorderSizePixel    = 0
toggleBtn.Parent             = screenGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 8)
tCorner.Parent = toggleBtn

-- Main panel
local panel                  = Instance.new("Frame")
panel.Name                   = "BasePanel"
panel.Size                   = UDim2.new(0, 340, 0, 520)
panel.Position               = UDim2.new(0, 10, 0.5, -260)
panel.BackgroundColor3       = Color3.fromRGB(15, 10, 30)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.Parent                 = screenGui

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent = panel

-- Title
local title                  = Instance.new("TextLabel")
title.Size                   = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3       = Color3.fromRGB(40, 25, 80)
title.BackgroundTransparency = 0
title.Text                   = "🏠 My Base"
title.TextColor3             = Color3.fromRGB(255, 255, 255)
title.Font                   = Enum.Font.GothamBold
title.TextScaled             = true
title.BorderSizePixel        = 0
title.Parent                 = panel

local tcorn = Instance.new("UICorner")
tcorn.CornerRadius = UDim.new(0, 12)
tcorn.Parent = title

-- Close button
local closeBtn               = Instance.new("TextButton")
closeBtn.Size                = UDim2.new(0, 36, 0, 36)
closeBtn.Position            = UDim2.new(1, -40, 0, 2)
closeBtn.BackgroundColor3    = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
closeBtn.Font                = Enum.Font.GothamBold
closeBtn.TextScaled          = true
closeBtn.Text                = "✕"
closeBtn.BorderSizePixel     = 0
closeBtn.Parent              = panel

local ccorn = Instance.new("UICorner")
ccorn.CornerRadius = UDim.new(0, 6)
ccorn.Parent = closeBtn

-- Stats bar
local statsFrame             = Instance.new("Frame")
statsFrame.Size              = UDim2.new(1, -16, 0, 50)
statsFrame.Position          = UDim2.new(0, 8, 0, 46)
statsFrame.BackgroundColor3  = Color3.fromRGB(25, 15, 50)
statsFrame.BorderSizePixel   = 0
statsFrame.Parent            = panel

local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 8)
sCorner.Parent = statsFrame

local incomeStatLabel        = Instance.new("TextLabel")
incomeStatLabel.Name         = "IncomeStat"
incomeStatLabel.Size         = UDim2.new(1, -8, 1, 0)
incomeStatLabel.Position     = UDim2.new(0, 8, 0, 0)
incomeStatLabel.BackgroundTransparency = 1
incomeStatLabel.Text         = "📈 Income: $0/s  |  🧠 Brainrots: 0/20"
incomeStatLabel.TextColor3   = Color3.fromRGB(200, 255, 200)
incomeStatLabel.Font         = Enum.Font.Gotham
incomeStatLabel.TextScaled   = true
incomeStatLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeStatLabel.Parent       = statsFrame

-- Lock Base button
local lockBtn                = Instance.new("TextButton")
lockBtn.Name                 = "LockBase"
lockBtn.Size                 = UDim2.new(0.48, -4, 0, 36)
lockBtn.Position             = UDim2.new(0, 8, 0, 104)
lockBtn.BackgroundColor3     = Color3.fromRGB(30, 160, 80)
lockBtn.TextColor3           = Color3.fromRGB(255, 255, 255)
lockBtn.Font                 = Enum.Font.GothamBold
lockBtn.TextScaled           = true
lockBtn.Text                 = "🔒 Lock Base"
lockBtn.BorderSizePixel      = 0
lockBtn.Parent               = panel

local lbCorner = Instance.new("UICorner")
lbCorner.CornerRadius = UDim.new(0, 8)
lbCorner.Parent = lockBtn

-- Rebirth button
local rebirthBtn             = Instance.new("TextButton")
rebirthBtn.Name              = "RebirthBtn"
rebirthBtn.Size              = UDim2.new(0.48, -4, 0, 36)
rebirthBtn.Position          = UDim2.new(0.52, 0, 0, 104)
rebirthBtn.BackgroundColor3  = Color3.fromRGB(180, 80, 30)
rebirthBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
rebirthBtn.Font              = Enum.Font.GothamBold
rebirthBtn.TextScaled        = true
rebirthBtn.Text              = "♻️ Rebirth"
rebirthBtn.BorderSizePixel   = 0
rebirthBtn.Parent            = panel

local rbCorner = Instance.new("UICorner")
rbCorner.CornerRadius = UDim.new(0, 8)
rbCorner.Parent = rebirthBtn

-- Traps section header
local trapHeader             = Instance.new("TextLabel")
trapHeader.Size              = UDim2.new(1, -16, 0, 24)
trapHeader.Position          = UDim2.new(0, 8, 0, 148)
trapHeader.BackgroundTransparency = 1
trapHeader.Text              = "🪤 Traps"
trapHeader.TextColor3        = Color3.fromRGB(255, 200, 100)
trapHeader.Font              = Enum.Font.GothamBold
trapHeader.TextScaled        = true
trapHeader.TextXAlignment    = Enum.TextXAlignment.Left
trapHeader.Parent            = panel

-- Trap buttons
local trapDefs = {
    { type = "SlowdownTrap", label = "🐢 Slowdown ($500)"  },
    { type = "StunTrap",     label = "⚡ Stun ($1,000)"    },
    { type = "EjectTrap",    label = "🚀 Eject ($1,500)"   },
}

for i, td in ipairs(trapDefs) do
    local btn                = Instance.new("TextButton")
    btn.Name                 = "Trap_" .. td.type
    btn.Size                 = UDim2.new(1, -16, 0, 30)
    btn.Position             = UDim2.new(0, 8, 0, 148 + i * 34)
    btn.BackgroundColor3     = Color3.fromRGB(100, 60, 150)
    btn.TextColor3           = Color3.fromRGB(255, 255, 255)
    btn.Font                 = Enum.Font.Gotham
    btn.TextScaled           = true
    btn.Text                 = td.label
    btn.BorderSizePixel      = 0
    btn.Parent               = panel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        Remotes.PlaceTrap:FireServer(td.type)
    end)
end

-- Brainrots list header
local brainrotHeader         = Instance.new("TextLabel")
brainrotHeader.Name          = "BrainrotHeader"
brainrotHeader.Size          = UDim2.new(1, -16, 0, 24)
brainrotHeader.Position      = UDim2.new(0, 8, 0, 300)
brainrotHeader.BackgroundTransparency = 1
brainrotHeader.Text          = "🧠 Owned Brainrots"
brainrotHeader.TextColor3    = Color3.fromRGB(200, 180, 255)
brainrotHeader.Font          = Enum.Font.GothamBold
brainrotHeader.TextScaled    = true
brainrotHeader.TextXAlignment = Enum.TextXAlignment.Left
brainrotHeader.Parent        = panel

-- Scrollable brainrot list
local brainrotScroll         = Instance.new("ScrollingFrame")
brainrotScroll.Name          = "BrainrotScroll"
brainrotScroll.Size          = UDim2.new(1, -16, 0, 170)
brainrotScroll.Position      = UDim2.new(0, 8, 0, 326)
brainrotScroll.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
brainrotScroll.BackgroundTransparency = 0.3
brainrotScroll.BorderSizePixel = 0
brainrotScroll.ScrollBarThickness = 5
brainrotScroll.CanvasSize    = UDim2.new(0, 0, 0, 0)
brainrotScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
brainrotScroll.Parent        = panel

local bsCorner = Instance.new("UICorner")
bsCorner.CornerRadius = UDim.new(0, 8)
bsCorner.Parent = brainrotScroll

local bsList = Instance.new("UIListLayout")
bsList.SortOrder  = Enum.SortOrder.LayoutOrder
bsList.Padding    = UDim.new(0, 4)
bsList.Parent     = brainrotScroll

local bsPad = Instance.new("UIPadding")
bsPad.PaddingTop    = UDim.new(0, 4)
bsPad.PaddingBottom = UDim.new(0, 4)
bsPad.PaddingLeft   = UDim.new(0, 4)
bsPad.PaddingRight  = UDim.new(0, 4)
bsPad.Parent = brainrotScroll

-- ── Brainrot list rendering ───────────────────────────────────────────────

local function RebuildBrainrotList()
    for _, c in ipairs(brainrotScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    if #playerState.brainrots == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size  = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text  = "No brainrots yet. Visit the shop!"
        empty.TextColor3 = Color3.fromRGB(150, 150, 150)
        empty.Font  = Enum.Font.Gotham
        empty.TextScaled = true
        empty.Parent = brainrotScroll
        return
    end

    -- Count duplicates for display
    local counts = {}
    for _, id in ipairs(playerState.brainrots) do
        counts[id] = (counts[id] or 0) + 1
    end

    local seen = {}
    for _, id in ipairs(playerState.brainrots) do
        if seen[id] then continue end
        seen[id] = true

        local b = BrainrotData.ById[id]
        if not b then continue end

        local row              = Instance.new("Frame")
        row.Size               = UDim2.new(1, -4, 0, 34)
        row.BackgroundColor3   = Color3.fromRGB(30, 20, 55)
        row.BorderSizePixel    = 0
        row.Parent             = brainrotScroll

        local rCorner = Instance.new("UICorner")
        rCorner.CornerRadius = UDim.new(0, 6)
        rCorner.Parent = row

        local nameL            = Instance.new("TextLabel")
        nameL.Size             = UDim2.new(0.65, 0, 1, 0)
        nameL.Position         = UDim2.new(0, 6, 0, 0)
        nameL.BackgroundTransparency = 1
        nameL.Text             = b.name .. (counts[id] > 1 and " x" .. counts[id] or "")
        nameL.TextColor3       = BrainrotData.RarityColors[b.rarity] or Color3.fromRGB(255,255,255)
        nameL.Font             = Enum.Font.Gotham
        nameL.TextScaled       = true
        nameL.TextXAlignment   = Enum.TextXAlignment.Left
        nameL.Parent           = row

        local sellBtn          = Instance.new("TextButton")
        sellBtn.Size           = UDim2.new(0.3, 0, 0.8, 0)
        sellBtn.Position       = UDim2.new(0.68, 0, 0.1, 0)
        sellBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        sellBtn.TextColor3     = Color3.fromRGB(255, 255, 255)
        sellBtn.Font           = Enum.Font.GothamBold
        sellBtn.TextScaled     = true
        sellBtn.Text           = "Sell"
        sellBtn.BorderSizePixel = 0
        sellBtn.Parent         = row

        local sbCorner = Instance.new("UICorner")
        sbCorner.CornerRadius = UDim.new(0, 4)
        sbCorner.Parent = sellBtn

        sellBtn.MouseButton1Click:Connect(function()
            Remotes.SellBrainrot:FireServer(id)
        end)
    end
end

-- ── Update stats display ──────────────────────────────────────────────────

local function UpdateDisplay()
    local income = CalcIncome()
    incomeStatLabel.Text = "📈 $" .. string.format("%.1f", income) .. "/s  |  🧠 "
        .. #playerState.brainrots .. "/" .. GameConfig.MaxBrainrotsPerBase

    local cost = GetRebirthCost()
    rebirthBtn.Text = "♻️ Rebirth ($" .. cost .. ")"

    -- Lock button countdown
    local remaining = math.ceil(playerState.lockExpiry - os.time())
    if remaining > 0 then
        lockBtn.Text = "🔒 Locked (" .. remaining .. "s)"
        lockBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    else
        lockBtn.Text = "🔒 Lock Base"
        lockBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 80)
    end

    RebuildBrainrotList()
end

-- ── Remote handler ────────────────────────────────────────────────────────

Remotes.UpdatePlayerData.OnClientEvent:Connect(function(data)
    if data.cash       ~= nil then playerState.cash       = data.cash       end
    if data.brainrots  ~= nil then playerState.brainrots  = data.brainrots  end
    if data.rebirths   ~= nil then playerState.rebirths   = data.rebirths   end
    if data.lockExpiry ~= nil then playerState.lockExpiry = data.lockExpiry end
    UpdateDisplay()
end)

-- ── Button handlers ───────────────────────────────────────────────────────

lockBtn.MouseButton1Click:Connect(function()
    if os.time() >= playerState.lockExpiry then
        Remotes.LockBase:FireServer()
    end
end)

rebirthBtn.MouseButton1Click:Connect(function()
    Remotes.Rebirth:FireServer()
end)

toggleBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then UpdateDisplay() end
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- Periodic lock countdown refresh
task.spawn(function()
    while true do
        task.wait(1)
        if panel.Visible then
            UpdateDisplay()
        end
    end
end)

UpdateDisplay()
