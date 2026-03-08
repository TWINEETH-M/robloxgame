--[[
    BaseTemplate.lua
    Generates a player's personal base when they join the game.

    Base structure per player:
        PlayerBases/
            Base_<userId>/
                SpawnPad       – where the player spawns
                BrainrotDisplay – flat platform where brainrot models appear
                Boundary        – invisible detection part for steal/trap logic
                LockIndicator   – coloured part: green = locked, red = unlocked
                TrapZone        – area marker for trap placement
                OwnerLabel      – billboard showing the owner's name

    Called by the server (this script lives in ServerScriptService or Workspace
    as a Script, not a LocalScript).
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared     = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(Shared:WaitForChild("GameConfig", 10))

-- ── Config ────────────────────────────────────────────────────────────────

local BASE_SIZE      = Vector3.new(50, 1, 50)     -- floor footprint
local BOUNDARY_SIZE  = Vector3.new(55, 20, 55)    -- slightly larger than floor
local SPAWN_OFFSET   = Vector3.new(0, 3, 0)
local INDICATOR_SIZE = Vector3.new(4, 4, 4)
local INDICATOR_POS  = Vector3.new(0, 5, -22)     -- relative to base centre

-- Bases arranged in a circle; radius grows with player count
local BASE_RADIUS    = 120
local BASE_Y         = 0.5                        -- ground level

-- Container folder in Workspace
local function GetOrCreateBasesFolder()
    local folder = workspace:FindFirstChild("PlayerBases")
    if not folder then
        folder        = Instance.new("Folder")
        folder.Name   = "PlayerBases"
        folder.Parent = workspace
    end
    return folder
end

-- ── Base creation ─────────────────────────────────────────────────────────

-- Maximum number of evenly-spaced base slots around the circle
local MAX_BASE_SLOTS = 8

local function GetBasePosition(playerIndex)
    -- Distribute bases evenly around a fixed circle of MAX_BASE_SLOTS slots
    local slotIndex = ((playerIndex - 1) % MAX_BASE_SLOTS)
    local angle     = (2 * math.pi / MAX_BASE_SLOTS) * slotIndex
    return Vector3.new(
        math.cos(angle) * BASE_RADIUS,
        BASE_Y,
        math.sin(angle) * BASE_RADIUS
    )
end

local function CreateBase(player, position)
    local folder        = GetOrCreateBasesFolder()

    -- Remove any stale base for this user (e.g. reconnect)
    local existing = folder:FindFirstChild("Base_" .. player.UserId)
    if existing then existing:Destroy() end

    local baseFolder    = Instance.new("Folder")
    baseFolder.Name     = "Base_" .. player.UserId
    baseFolder.Parent   = folder

    -- ── Floor ────────────────────────────────────────────────────────────
    local floor         = Instance.new("Part")
    floor.Name          = "Floor"
    floor.Size          = BASE_SIZE
    floor.Anchored      = true
    floor.BrickColor    = BrickColor.new("Medium stone grey")
    floor.Material      = Enum.Material.SmoothPlastic
    floor.Position      = position + Vector3.new(0, -0.5, 0)
    floor.Parent        = baseFolder

    -- ── Spawn pad ─────────────────────────────────────────────────────────
    local spawnPad      = Instance.new("SpawnLocation")
    spawnPad.Name       = "SpawnPad"
    spawnPad.Size       = Vector3.new(6, 1, 6)
    spawnPad.Anchored   = true
    spawnPad.BrickColor = BrickColor.new("Bright blue")
    spawnPad.Material   = Enum.Material.Neon
    spawnPad.Position   = position + SPAWN_OFFSET
    spawnPad.Neutral    = false
    spawnPad.AllowTeamChangeOnTouch = false
    spawnPad.Parent     = baseFolder

    -- ── Brainrot display platform ─────────────────────────────────────────
    local displayPlat   = Instance.new("Part")
    displayPlat.Name    = "BrainrotDisplay"
    displayPlat.Size    = Vector3.new(BASE_SIZE.X - 10, 0.5, BASE_SIZE.Z - 10)
    displayPlat.Anchored = true
    displayPlat.BrickColor = BrickColor.new("Pastel violet")
    displayPlat.Material   = Enum.Material.SmoothPlastic
    displayPlat.Position   = position + Vector3.new(0, 0.75, 0)
    displayPlat.Parent     = baseFolder

    -- ── Boundary (invisible, non-collidable) ─────────────────────────────
    local boundary      = Instance.new("Part")
    boundary.Name       = "Boundary"
    boundary.Size       = BOUNDARY_SIZE
    boundary.Anchored   = true
    boundary.Transparency = 1
    boundary.CanCollide = false
    boundary.Position   = position + Vector3.new(0, BOUNDARY_SIZE.Y / 2, 0)
    boundary.Parent     = baseFolder

    -- ── Lock indicator ────────────────────────────────────────────────────
    local indicator     = Instance.new("Part")
    indicator.Name      = "LockIndicator"
    indicator.Size      = INDICATOR_SIZE
    indicator.Anchored  = true
    indicator.BrickColor = BrickColor.new("Bright red")   -- unlocked by default
    indicator.Material  = Enum.Material.Neon
    indicator.Shape     = Enum.PartType.Ball
    indicator.Position  = position + INDICATOR_POS
    indicator.Parent    = baseFolder

    -- ── Trap zone marker (transparent yellow) ────────────────────────────
    local trapZone      = Instance.new("Part")
    trapZone.Name       = "TrapZone"
    trapZone.Size       = Vector3.new(BASE_SIZE.X - 6, 0.2, BASE_SIZE.Z - 6)
    trapZone.Anchored   = true
    trapZone.Transparency = 0.85
    trapZone.CanCollide = false
    trapZone.BrickColor = BrickColor.new("Bright yellow")
    trapZone.Material   = Enum.Material.Neon
    trapZone.Position   = position + Vector3.new(0, 1.1, 0)
    trapZone.Parent     = baseFolder

    -- ── Owner billboard ───────────────────────────────────────────────────
    local billboard     = Instance.new("BillboardGui")
    billboard.Size      = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent    = floor

    local nameTag       = Instance.new("TextLabel")
    nameTag.Size        = UDim2.new(1, 0, 1, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.Text        = player.DisplayName .. "'s Base"
    nameTag.TextColor3  = Color3.fromRGB(255, 255, 255)
    nameTag.Font        = Enum.Font.GothamBold
    nameTag.TextScaled  = true
    nameTag.Parent      = billboard

    return baseFolder
end

-- ── Player lifecycle ──────────────────────────────────────────────────────

local playerIndex = 0

local function OnPlayerAdded(player)
    playerIndex = playerIndex + 1
    local pos   = GetBasePosition(playerIndex)

    -- Wait for character before spawning
    player.CharacterAdded:Connect(function(character)
        -- Teleport to spawn pad
        local root = character:WaitForChild("HumanoidRootPart", 5)
        if root then
            local folder = GetOrCreateBasesFolder():FindFirstChild("Base_" .. player.UserId)
            if folder then
                local spawnPad = folder:FindFirstChild("SpawnPad")
                if spawnPad then
                    root.CFrame = spawnPad.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end)

    CreateBase(player, pos)
end

local function OnPlayerRemoving(player)
    local folder = GetOrCreateBasesFolder()
    local base   = folder:FindFirstChild("Base_" .. player.UserId)
    if base then
        base:Destroy()
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Handle existing players
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(OnPlayerAdded, p)
end
