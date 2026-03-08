--[[
    ShopGui.client.lua
    Brainrot marketplace UI.

    Features:
        • Toggle button to open/close the shop panel
        • Displays current shop rotation (up to ShopSlots entries)
        • Each card shows: name, rarity badge (colour-coded), income/s, cost
        • Buy button fires BuyBrainrot remote; confirmation feedback shown in-card
        • Auto-refreshes display when ShopUpdate event is received from server
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared", 10)
local BrainrotData = require(Shared:WaitForChild("BrainrotData", 10))
local GameConfig   = require(Shared:WaitForChild("GameConfig",   10))
local Remotes      = require(Shared:WaitForChild("Remotes",      10))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Screen GUI ────────────────────────────────────────────────────────────

local screenGui             = Instance.new("ScreenGui")
screenGui.Name              = "ShopGui"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Parent            = playerGui

-- Toggle button (bottom centre)
local toggleBtn             = Instance.new("TextButton")
toggleBtn.Name              = "ShopToggle"
toggleBtn.Size              = UDim2.new(0, 120, 0, 40)
toggleBtn.Position          = UDim2.new(0.5, -60, 1, -60)
toggleBtn.BackgroundColor3  = Color3.fromRGB(30, 120, 220)
toggleBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
toggleBtn.Font              = Enum.Font.GothamBold
toggleBtn.TextScaled        = true
toggleBtn.Text              = "🛒 Shop"
toggleBtn.BorderSizePixel   = 0
toggleBtn.Parent            = screenGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 8)
tCorner.Parent = toggleBtn

-- Main shop panel
local panel                 = Instance.new("Frame")
panel.Name                  = "ShopPanel"
panel.Size                  = UDim2.new(0, 400, 0, 480)
panel.Position              = UDim2.new(0.5, -200, 0.5, -240)
panel.BackgroundColor3      = Color3.fromRGB(15, 15, 25)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel       = 0
panel.Visible               = false
panel.Parent                = screenGui

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent = panel

-- Title bar
local titleBar              = Instance.new("Frame")
titleBar.Size               = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3   = Color3.fromRGB(30, 30, 50)
titleBar.BorderSizePixel    = 0
titleBar.Parent             = panel

local tcorn = Instance.new("UICorner")
tcorn.CornerRadius = UDim.new(0, 12)
tcorn.Parent = titleBar

local titleLabel            = Instance.new("TextLabel")
titleLabel.Size             = UDim2.new(1, -50, 1, 0)
titleLabel.Position         = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text             = "🧠 Brainrot Shop"
titleLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
titleLabel.Font             = Enum.Font.GothamBold
titleLabel.TextScaled       = true
titleLabel.TextXAlignment   = Enum.TextXAlignment.Left
titleLabel.Parent           = titleBar

local closeBtn              = Instance.new("TextButton")
closeBtn.Size               = UDim2.new(0, 40, 0, 40)
closeBtn.Position           = UDim2.new(1, -44, 0, 2)
closeBtn.BackgroundColor3   = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.TextScaled         = true
closeBtn.Text               = "✕"
closeBtn.BorderSizePixel    = 0
closeBtn.Parent             = titleBar

local ccorn = Instance.new("UICorner")
ccorn.CornerRadius = UDim.new(0, 8)
ccorn.Parent = closeBtn

-- Scrolling frame for cards
local scroll                = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -16, 1, -56)
scroll.Position             = UDim2.new(0, 8, 0, 48)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness   = 6
scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.BorderSizePixel      = 0
scroll.Parent               = panel

local listLayout            = Instance.new("UIListLayout")
listLayout.SortOrder        = Enum.SortOrder.LayoutOrder
listLayout.Padding          = UDim.new(0, 8)
listLayout.Parent           = scroll

local listPad               = Instance.new("UIPadding")
listPad.PaddingTop          = UDim.new(0, 4)
listPad.PaddingBottom       = UDim.new(0, 4)
listPad.Parent              = scroll

-- ── Card builder ──────────────────────────────────────────────────────────

local function MakeCard(brainrotInfo, index)
    local rarityColor = BrainrotData.RarityColors[brainrotInfo.rarity] or Color3.fromRGB(200, 200, 200)

    local card              = Instance.new("Frame")
    card.Name               = "Card_" .. brainrotInfo.id
    card.Size               = UDim2.new(1, -8, 0, 90)
    card.BackgroundColor3   = Color3.fromRGB(25, 25, 40)
    card.BorderSizePixel    = 0
    card.LayoutOrder        = index
    card.Parent             = scroll

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    -- Left rarity stripe
    local stripe            = Instance.new("Frame")
    stripe.Size             = UDim2.new(0, 5, 1, 0)
    stripe.BackgroundColor3 = rarityColor
    stripe.BorderSizePixel  = 0
    stripe.Parent           = card

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 4)
    sCorner.Parent = stripe

    -- Name
    local nameLabel         = Instance.new("TextLabel")
    nameLabel.Size          = UDim2.new(0.6, -10, 0, 22)
    nameLabel.Position      = UDim2.new(0, 14, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text          = brainrotInfo.name
    nameLabel.TextColor3    = Color3.fromRGB(255, 255, 255)
    nameLabel.Font          = Enum.Font.GothamBold
    nameLabel.TextScaled    = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent        = card

    -- Rarity badge
    local rarityLabel       = Instance.new("TextLabel")
    rarityLabel.Size        = UDim2.new(0, 90, 0, 20)
    rarityLabel.Position    = UDim2.new(0, 14, 0, 30)
    rarityLabel.BackgroundColor3 = rarityColor
    rarityLabel.BackgroundTransparency = 0.3
    rarityLabel.Text        = brainrotInfo.rarity
    rarityLabel.TextColor3  = Color3.fromRGB(255, 255, 255)
    rarityLabel.Font        = Enum.Font.GothamBold
    rarityLabel.TextScaled  = true
    rarityLabel.BorderSizePixel = 0
    rarityLabel.Parent      = card

    local rbCorner = Instance.new("UICorner")
    rbCorner.CornerRadius = UDim.new(0, 4)
    rbCorner.Parent = rarityLabel

    -- Income
    local incomeLabel       = Instance.new("TextLabel")
    incomeLabel.Size        = UDim2.new(0.55, -10, 0, 18)
    incomeLabel.Position    = UDim2.new(0, 14, 0, 56)
    incomeLabel.BackgroundTransparency = 1
    incomeLabel.Text        = "📈 $" .. brainrotInfo.income .. "/s"
    incomeLabel.TextColor3  = Color3.fromRGB(100, 220, 100)
    incomeLabel.Font        = Enum.Font.Gotham
    incomeLabel.TextScaled  = true
    incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    incomeLabel.Parent      = card

    -- Cost
    local costLabel         = Instance.new("TextLabel")
    costLabel.Size          = UDim2.new(0.35, 0, 0, 22)
    costLabel.Position      = UDim2.new(0.58, 0, 0, 6)
    costLabel.BackgroundTransparency = 1
    costLabel.Text          = "💰 $" .. brainrotInfo.cost
    costLabel.TextColor3    = Color3.fromRGB(255, 215, 0)
    costLabel.Font          = Enum.Font.GothamBold
    costLabel.TextScaled    = true
    costLabel.TextXAlignment = Enum.TextXAlignment.Right
    costLabel.Parent        = card

    -- Buy button
    local buyBtn            = Instance.new("TextButton")
    buyBtn.Size             = UDim2.new(0.35, 0, 0, 36)
    buyBtn.Position         = UDim2.new(0.63, 0, 0, 34)
    buyBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 70)
    buyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    buyBtn.Font             = Enum.Font.GothamBold
    buyBtn.TextScaled       = true
    buyBtn.Text             = "BUY"
    buyBtn.BorderSizePixel  = 0
    buyBtn.Parent           = card

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = buyBtn

    -- Buy click handler
    buyBtn.MouseButton1Click:Connect(function()
        buyBtn.Text = "..."
        buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        Remotes.BuyBrainrot:FireServer(brainrotInfo.id)
        task.delay(1, function()
            buyBtn.Text = "BUY"
            buyBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 70)
        end)
    end)

    return card
end

-- ── Shop state ────────────────────────────────────────────────────────────

local currentListing = {}

local function RebuildShopDisplay()
    -- Clear existing cards
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    -- Rebuild
    for i, info in ipairs(currentListing) do
        MakeCard(info, i)
    end
end

-- ── Remote handlers ───────────────────────────────────────────────────────

Remotes.ShopUpdate.OnClientEvent:Connect(function(listing)
    if type(listing) == "table" then
        currentListing = listing
        RebuildShopDisplay()
    end
end)

-- Show error feedback in the panel
Remotes.UpdatePlayerData.OnClientEvent:Connect(function(data)
    if data.error then
        -- Brief error message at the bottom of the panel
        local existing = panel:FindFirstChild("ErrorLabel")
        if existing then existing:Destroy() end

        local errLbl            = Instance.new("TextLabel")
        errLbl.Name             = "ErrorLabel"
        errLbl.Size             = UDim2.new(1, -16, 0, 28)
        errLbl.Position         = UDim2.new(0, 8, 1, -34)
        errLbl.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        errLbl.BackgroundTransparency = 0.2
        errLbl.Text             = "⚠ " .. data.error
        errLbl.TextColor3       = Color3.fromRGB(255, 255, 255)
        errLbl.Font             = Enum.Font.Gotham
        errLbl.TextScaled       = true
        errLbl.BorderSizePixel  = 0
        errLbl.ZIndex           = 10
        errLbl.Parent           = panel

        local eCorner = Instance.new("UICorner")
        eCorner.CornerRadius = UDim.new(0, 6)
        eCorner.Parent = errLbl

        task.delay(3, function()
            if errLbl and errLbl.Parent then
                errLbl:Destroy()
            end
        end)
    end
end)

-- ── Toggle logic ──────────────────────────────────────────────────────────

toggleBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)
