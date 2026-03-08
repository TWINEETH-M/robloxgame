--[[
    StealingSystem.server.lua
    Implements the core PvP stealing mechanic.

    Flow:
        1. Client fires StartSteal(targetPlayerId) when near a target base.
        2. Server validates: proximity, target base not locked, thief not on cooldown.
        3. Server slows the thief and starts a StealTime countdown.
        4. If thief stays in the base for the full duration → transfer one brainrot.
        5. StealAlert is fired to the base owner.
        6. If thief leaves early → steal is cancelled.
        7. CancelSteal remote lets the client signal an early exit.

    Anti-cheat notes:
        • All proximity and lock checks are server-authoritative.
        • The client is never trusted for position or ownership data.
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

-- active steal coroutines keyed by player
local activeSteals = {}

-- ── Helpers ───────────────────────────────────────────────────────────────

local function GetCharacterRoot(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Find the base boundary Part for a given player (placed by BaseTemplate.lua)
local function GetBaseBoundary(targetPlayer)
    local baseFolder = workspace:FindFirstChild("PlayerBases")
    if not baseFolder then return nil end
    local base = baseFolder:FindFirstChild("Base_" .. targetPlayer.UserId)
    if not base then return nil end
    return base:FindFirstChild("Boundary")
end

-- Returns true if `character` is inside the bounding box of `part`
local function IsInsidePart(character, part)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not part then return false end
    local rel = part.CFrame:ToObjectSpace(CFrame.new(root.Position))
    local size = part.Size / 2
    return math.abs(rel.X) <= size.X
        and math.abs(rel.Y) <= size.Y + 5  -- small vertical tolerance
        and math.abs(rel.Z) <= size.Z
end

-- Reduce a humanoid's walk speed
local function SetSpeedPenalty(player, apply)
    local char      = player.Character
    if not char then return end
    local humanoid  = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if apply then
        humanoid.WalkSpeed = 16 * (1 - GameConfig.StealSpeedPenalty)
    else
        humanoid.WalkSpeed = 16
    end
end

-- ── Steal logic ───────────────────────────────────────────────────────────

local function CancelSteal(thief, reason)
    if activeSteals[thief] then
        activeSteals[thief] = false  -- signal the coroutine to abort
    end
    SetSpeedPenalty(thief, false)
    -- Inform the thief client
    Remotes.UpdatePlayerData:FireClient(thief, { stealCancelled = reason or "Steal cancelled." })
end

local function OnStartSteal(thief, targetUserId)
    -- Input validation
    if type(targetUserId) ~= "number" then return end

    local pdm = GetPDM()
    if not pdm then return end

    local thiefData = pdm.GetData(thief)
    if not thiefData then return end

    -- Cooldown check (server clock)
    if os.time() < thiefData.stealCooldown then
        Remotes.UpdatePlayerData:FireClient(thief, {
            error = "Steal on cooldown for " .. math.ceil(thiefData.stealCooldown - os.time()) .. "s."
        })
        return
    end

    -- Find target player
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target or target == thief then return end

    local targetData = pdm.GetData(target)
    if not targetData then return end

    -- Target base must have at least one brainrot to steal
    if #targetData.brainrots == 0 then
        Remotes.UpdatePlayerData:FireClient(thief, { error = "Target has no brainrots to steal!" })
        return
    end

    -- Base lock check
    if os.time() < targetData.lockExpiry then
        Remotes.UpdatePlayerData:FireClient(thief, {
            error = "Target base is locked for another " .. math.ceil(targetData.lockExpiry - os.time()) .. "s."
        })
        return
    end

    -- Proximity check (server-side)
    local boundary = GetBaseBoundary(target)
    if boundary then
        local thiefRoot = GetCharacterRoot(thief)
        if thiefRoot then
            local dist = (thiefRoot.Position - boundary.Position).Magnitude
            if dist > GameConfig.StealProximity + boundary.Size.Magnitude / 2 then
                Remotes.UpdatePlayerData:FireClient(thief, { error = "You are not close enough to the base!" })
                return
            end
        end
    end

    -- Prevent concurrent steals
    if activeSteals[thief] ~= nil then return end

    activeSteals[thief] = true  -- flag as active (false = cancel requested)
    SetSpeedPenalty(thief, true)

    -- Alert the base owner
    Remotes.StealAlert:FireClient(target, {
        thiefName = thief.DisplayName,
        message   = thief.DisplayName .. " is raiding your base!",
    })

    -- Notify thief that steal has started
    Remotes.UpdatePlayerData:FireClient(thief, { stealStarted = true, stealTime = GameConfig.StealTime })

    -- Countdown coroutine
    task.spawn(function()
        local elapsed = 0
        local interval = 0.5
        while elapsed < GameConfig.StealTime do
            task.wait(interval)
            elapsed = elapsed + interval

            -- Abort if cancelled
            if activeSteals[thief] == false then
                activeSteals[thief] = nil
                SetSpeedPenalty(thief, false)
                return
            end

            -- Abort if thief left the game
            if not thief.Parent then
                activeSteals[thief] = nil
                return
            end

            -- Abort if thief has left the base boundary
            if boundary and thief.Character then
                if not IsInsidePart(thief.Character, boundary) then
                    CancelSteal(thief, "You left the base!")
                    activeSteals[thief] = nil
                    return
                end
            end
        end

        -- ── Steal success ──────────────────────────────────────────────
        activeSteals[thief] = nil
        SetSpeedPenalty(thief, false)

        -- Re-validate in case state changed during the wait
        local freshTargetData = pdm.GetData(target)
        local freshThiefData  = pdm.GetData(thief)
        if not freshTargetData or not freshThiefData then return end

        if #freshTargetData.brainrots == 0 then
            Remotes.UpdatePlayerData:FireClient(thief, { error = "Nothing left to steal!" })
            return
        end

        if #freshThiefData.brainrots >= GameConfig.MaxBrainrotsPerBase then
            Remotes.UpdatePlayerData:FireClient(thief, { error = "Your base is full!" })
            return
        end

        -- Transfer a random brainrot
        local idx       = math.random(1, #freshTargetData.brainrots)
        local stolenId  = freshTargetData.brainrots[idx]
        table.remove(freshTargetData.brainrots, idx)
        table.insert(freshThiefData.brainrots, stolenId)

        -- Apply steal cooldown to thief
        freshThiefData.stealCooldown = os.time() + GameConfig.StealCooldown

        -- Update leaderstats & sync both players
        pdm.UpdateLeaderstats(thief)
        pdm.UpdateLeaderstats(target)
        pdm.SyncToClient(thief)
        pdm.SyncToClient(target)

        -- Notify both players
        Remotes.UpdatePlayerData:FireClient(thief, {
            stealSuccess = true,
            stolenId     = stolenId,
            message      = "You stole " .. stolenId .. " from " .. target.DisplayName .. "!",
        })
        Remotes.StealAlert:FireClient(target, {
            stolen  = true,
            message = thief.DisplayName .. " stole one of your brainrots!",
        })
    end)
end

local function OnCancelSteal(thief)
    CancelSteal(thief, "Steal cancelled by player.")
end

-- ── Connect remotes ───────────────────────────────────────────────────────

Remotes.StartSteal:Connect(OnStartSteal)
Remotes.CancelSteal:Connect(OnCancelSteal)

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
    activeSteals[player] = nil
end)
