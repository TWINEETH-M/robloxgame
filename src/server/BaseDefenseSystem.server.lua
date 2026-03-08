--[[
    BaseDefenseSystem.server.lua
    Manages base protection mechanics: lock activation, trap placement,
    intruder detection, and trap effects.

    Responsibilities:
        • LockBase remote → validate cooldown, set lockExpiry in player data
        • PlaceTrap remote → validate funds/capacity, store trap, update base model
        • Per-second intruder scan → detect players inside a foreign base
        • Apply trap effects to detected intruders (slow, stun, eject)
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

-- Track trap-effect cooldowns per player so effects aren't re-applied instantly
-- [victim] = os.clock() when effect expires
local trapEffectExpiry = {}

-- ── Helpers ───────────────────────────────────────────────────────────────

local function GetBaseBoundary(ownerPlayer)
    local baseFolder = workspace:FindFirstChild("PlayerBases")
    if not baseFolder then return nil end
    local base = baseFolder:FindFirstChild("Base_" .. ownerPlayer.UserId)
    if not base then return nil end
    return base:FindFirstChild("Boundary")
end

local function GetLockIndicator(ownerPlayer)
    local baseFolder = workspace:FindFirstChild("PlayerBases")
    if not baseFolder then return nil end
    local base = baseFolder:FindFirstChild("Base_" .. ownerPlayer.UserId)
    if not base then return nil end
    return base:FindFirstChild("LockIndicator")
end

local function IsInsidePart(character, part)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not part then return false end
    local rel  = part.CFrame:ToObjectSpace(CFrame.new(root.Position))
    local size = part.Size / 2
    return math.abs(rel.X) <= size.X
        and math.abs(rel.Y) <= size.Y + 5
        and math.abs(rel.Z) <= size.Z
end

-- ── Base Lock ─────────────────────────────────────────────────────────────

local lockCooldowns = {}  -- [player] = os.time() when cooldown expires

local function OnLockBase(player)
    local pdm  = GetPDM()
    if not pdm then return end
    local data = pdm.GetData(player)
    if not data then return end

    local now = os.time()

    -- Check if on cooldown (player can't spam lock)
    if lockCooldowns[player] and now < lockCooldowns[player] then
        local remaining = math.ceil(lockCooldowns[player] - now)
        Remotes.UpdatePlayerData:FireClient(player, {
            error = "Lock is on cooldown for " .. remaining .. "s."
        })
        return
    end

    -- Activate lock
    data.lockExpiry     = now + GameConfig.BaseLockDuration
    lockCooldowns[player] = now + GameConfig.BaseLockCooldown

    pdm.SyncToClient(player)

    -- Update lock indicator color on the base model
    local indicator = GetLockIndicator(player)
    if indicator then
        indicator.BrickColor = BrickColor.new("Bright green")
    end

    -- Automatically remove lock when it expires
    task.delay(GameConfig.BaseLockDuration, function()
        local indicator2 = GetLockIndicator(player)
        if indicator2 then
            indicator2.BrickColor = BrickColor.new("Bright red")
        end
        pdm.SyncToClient(player)
    end)
end

-- ── Trap Placement ────────────────────────────────────────────────────────

local function OnPlaceTrap(player, trapType)
    if type(trapType) ~= "string" then return end

    local trapConfig = GameConfig.Traps[trapType]
    if not trapConfig then
        warn("[BaseDefenseSystem] Unknown trap type: " .. trapType)
        return
    end

    local pdm  = GetPDM()
    if not pdm then return end
    local data = pdm.GetData(player)
    if not data then return end

    -- Capacity check
    if #data.traps >= GameConfig.MaxTrapsPerBase then
        Remotes.UpdatePlayerData:FireClient(player, { error = "Maximum traps reached!" })
        return
    end

    -- Funds check
    if data.cash < trapConfig.cost then
        Remotes.UpdatePlayerData:FireClient(player, { error = "Not enough cash for trap!" })
        return
    end

    data.cash = data.cash - trapConfig.cost
    table.insert(data.traps, trapType)

    pdm.UpdateLeaderstats(player)
    pdm.SyncToClient(player)
end

-- ── Trap Effect Application ───────────────────────────────────────────────

local function ApplyTrapEffect(victim, trapType)
    local char     = victim.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local cfg = GameConfig.Traps[trapType]
    if not cfg then return end

    -- Prevent re-applying until the effect expires
    if trapEffectExpiry[victim] and os.clock() < trapEffectExpiry[victim] then return end

    if trapType == "SlowdownTrap" then
        trapEffectExpiry[victim] = os.clock() + cfg.duration
        humanoid.WalkSpeed = 16 * cfg.speedMultiplier
        task.delay(cfg.duration, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = 16
            end
            trapEffectExpiry[victim] = nil
        end)

    elseif trapType == "StunTrap" then
        trapEffectExpiry[victim] = os.clock() + cfg.duration
        humanoid.WalkSpeed = 0
        task.delay(cfg.duration, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = 16
            end
            trapEffectExpiry[victim] = nil
        end)

    elseif trapType == "EjectTrap" then
        trapEffectExpiry[victim] = os.clock() + 2
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Launch upward and outward
            local vel = Instance.new("LinearVelocity")
            vel.MaxForce = math.huge
            vel.VectorVelocity = Vector3.new(0, cfg.ejectForce, 0)
            vel.RelativeTo = Enum.ActuatorRelativeTo.World
            local att = Instance.new("Attachment")
            att.Parent = root
            vel.Attachment0 = att
            vel.Parent = root
            task.delay(0.3, function()
                vel:Destroy()
                att:Destroy()
                trapEffectExpiry[victim] = nil
            end)
        end
    end
end

-- ── Intruder Detection Loop ───────────────────────────────────────────────

task.spawn(function()
    local pdm = GetPDM()
    if not pdm then
        warn("[BaseDefenseSystem] PlayerDataManager unavailable.")
        return
    end

    while true do
        task.wait(0.5)
        local allPlayers = Players:GetPlayers()

        for _, owner in ipairs(allPlayers) do
            local ownerData = pdm.GetData(owner)
            if ownerData and #ownerData.traps > 0 then
                local boundary = GetBaseBoundary(owner)
                if boundary then
                    for _, intruder in ipairs(allPlayers) do
                        if intruder ~= owner and intruder.Character then
                            if IsInsidePart(intruder.Character, boundary) then
                                -- Apply a random trap from the owner's set
                                local trapType = ownerData.traps[math.random(1, #ownerData.traps)]
                                ApplyTrapEffect(intruder, trapType)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── Connect remotes ───────────────────────────────────────────────────────

Remotes.LockBase:Connect(OnLockBase)
Remotes.PlaceTrap:Connect(OnPlaceTrap)

-- Clean up on leave
Players.PlayerRemoving:Connect(function(player)
    lockCooldowns[player]  = nil
    trapEffectExpiry[player] = nil
end)
