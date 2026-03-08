--[[
    MapSetup.lua
    Generates the central map layout at game start.

    Creates:
        • Central marketplace platform with a decorative archway
        • Pathways radiating outward to player base spawn areas
        • Ambient lighting and sky adjustments
        • Spawn point indicators (the actual bases are built by BaseTemplate.lua)
--]]

local Lighting = game:GetService("Lighting")

-- ── Lighting / atmosphere ─────────────────────────────────────────────────

Lighting.Ambient           = Color3.fromRGB(100, 100, 130)
Lighting.Brightness        = 2
Lighting.OutdoorAmbient    = Color3.fromRGB(130, 130, 160)
Lighting.TimeOfDay         = "14:00:00"
Lighting.FogEnd            = 1000
Lighting.FogColor          = Color3.fromRGB(180, 180, 220)

local atmosphere           = Instance.new("Atmosphere")
atmosphere.Density         = 0.3
atmosphere.Offset          = 0.25
atmosphere.Color           = Color3.fromRGB(120, 140, 200)
atmosphere.Decay           = Color3.fromRGB(90, 100, 180)
atmosphere.Glare           = 0.2
atmosphere.Haze            = 1
atmosphere.Parent          = Lighting

-- ── Helper ────────────────────────────────────────────────────────────────

local function MakePart(name, size, position, color, material, anchored, canCollide)
    local part           = Instance.new("Part")
    part.Name            = name
    part.Size            = size
    part.Position        = position
    part.BrickColor      = BrickColor.new(color)
    part.Material        = material or Enum.Material.SmoothPlastic
    part.Anchored        = anchored == nil and true or anchored
    part.CanCollide      = canCollide == nil and true or canCollide
    part.Parent          = workspace
    return part
end

-- ── Central marketplace ───────────────────────────────────────────────────

-- Ground / floor of the marketplace
local marketFloor = MakePart(
    "MarketFloor",
    Vector3.new(60, 2, 60),
    Vector3.new(0, -1, 0),
    "Medium stone grey",
    Enum.Material.Cobblestone
)

-- Decorative archway pillars (4 corners)
local pillarPositions = {
    Vector3.new(-28, 5, -28),
    Vector3.new( 28, 5, -28),
    Vector3.new(-28, 5,  28),
    Vector3.new( 28, 5,  28),
}

for i, pos in ipairs(pillarPositions) do
    local pillar = MakePart(
        "MarketPillar_" .. i,
        Vector3.new(3, 12, 3),
        pos,
        "Dark stone grey",
        Enum.Material.SmoothPlastic
    )
    -- Pillar cap
    MakePart(
        "PillarCap_" .. i,
        Vector3.new(5, 1, 5),
        pos + Vector3.new(0, 6.5, 0),
        "Medium stone grey",
        Enum.Material.SmoothPlastic
    )
end

-- Centre market sign (BillboardGui on a part)
local signPost = MakePart(
    "MarketSignPost",
    Vector3.new(1, 8, 1),
    Vector3.new(0, 4, -26),
    "Reddish brown",
    Enum.Material.Wood
)

local signBoard = Instance.new("BillboardGui")
signBoard.Size         = UDim2.new(0, 300, 0, 80)
signBoard.StudsOffset  = Vector3.new(0, 5, 0)
signBoard.AlwaysOnTop  = false
signBoard.Parent       = signPost

local signLabel = Instance.new("TextLabel")
signLabel.Size          = UDim2.new(1, 0, 1, 0)
signLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
signLabel.BackgroundTransparency = 0
signLabel.Text          = "🧠 BRAINROT MARKET 🧠"
signLabel.TextColor3    = Color3.fromRGB(255, 220, 50)
signLabel.Font          = Enum.Font.GothamBold
signLabel.TextScaled    = true
signLabel.Parent        = signBoard

local signCorner = Instance.new("UICorner")
signCorner.CornerRadius = UDim.new(0, 8)
signCorner.Parent = signLabel

-- ── Pathways (8 directions radiating from market) ─────────────────────────

local PATH_LENGTH   = 90
local PATH_WIDTH    = 8
local PATH_Y        = -0.4

for i = 0, 7 do
    local angle   = (math.pi * 2 / 8) * i
    local midDist = 30 + PATH_LENGTH / 2
    local midX    = math.cos(angle) * midDist
    local midZ    = math.sin(angle) * midDist

    local pathPart = MakePart(
        "Path_" .. i,
        Vector3.new(PATH_WIDTH, 0.5, PATH_LENGTH),
        Vector3.new(midX, PATH_Y, midZ),
        "Light stone grey",
        Enum.Material.Cobblestone
    )
    pathPart.CFrame = CFrame.new(Vector3.new(midX, PATH_Y, midZ))
        * CFrame.Angles(0, angle + math.pi / 2, 0)
end

-- ── Base plot markers (circles on the ground) ─────────────────────────────

local BASE_RADIUS = 120
local PLOT_COUNT  = 8

for i = 1, PLOT_COUNT do
    local angle  = (math.pi * 2 / PLOT_COUNT) * (i - 1)
    local plotX  = math.cos(angle) * BASE_RADIUS
    local plotZ  = math.sin(angle) * BASE_RADIUS

    -- Placeholder disc showing where a player base will appear
    local disc = MakePart(
        "BasePlot_" .. i,
        Vector3.new(55, 0.3, 55),
        Vector3.new(plotX, -0.15, plotZ),
        "Pastel blue",
        Enum.Material.Neon,
        true,
        false
    )
    disc.Shape = Enum.PartType.Cylinder
    disc.CFrame = CFrame.new(disc.Position) * CFrame.Angles(0, 0, math.pi / 2)
end

-- ── Ambient point lights (market torches) ────────────────────────────────

local torchPositions = {
    Vector3.new(-25, 0, -25),
    Vector3.new( 25, 0, -25),
    Vector3.new(-25, 0,  25),
    Vector3.new( 25, 0,  25),
    Vector3.new(  0, 0, -25),
    Vector3.new(  0, 0,  25),
}

for i, pos in ipairs(torchPositions) do
    local base = MakePart(
        "Torch_" .. i,
        Vector3.new(1, 5, 1),
        pos + Vector3.new(0, 2.5, 0),
        "Reddish brown",
        Enum.Material.Wood
    )

    local flame = MakePart(
        "TorchFlame_" .. i,
        Vector3.new(1.2, 1.2, 1.2),
        pos + Vector3.new(0, 5.6, 0),
        "Bright orange",
        Enum.Material.Neon,
        true,
        false
    )
    flame.Shape = Enum.PartType.Ball

    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 3
    pointLight.Color      = Color3.fromRGB(255, 160, 50)
    pointLight.Range      = 20
    pointLight.Parent     = flame
end

print("[MapSetup] Map initialised successfully.")
