--[[
    GameConfig.lua
    Shared module containing global game constants used by both the server
    and client.  Centralising values here makes tuning easy without hunting
    through multiple scripts.
--]]

local GameConfig = {}

-- ── Economy ────────────────────────────────────────────────────────────────

-- Cash given to a brand-new player
GameConfig.StartingCash = 500

-- Maximum number of brainrots a player can own at once
GameConfig.MaxBrainrotsPerBase = 20

-- ── Base Defense ───────────────────────────────────────────────────────────

-- How long (seconds) a base is invulnerable after the lock is activated
GameConfig.BaseLockDuration = 30

-- Minimum seconds a player must wait before locking their base again
GameConfig.BaseLockCooldown = 120

-- ── Stealing ──────────────────────────────────────────────────────────────

-- Seconds a thief must stay inside the target base to complete a steal
GameConfig.StealTime = 5

-- Cooldown (seconds) before the same player can attempt another steal
GameConfig.StealCooldown = 60

-- How far (studs) from a base boundary a player must be to initiate a raid
GameConfig.StealProximity = 20

-- Percentage of the thief's walk-speed reduction while stealing (0‒1)
GameConfig.StealSpeedPenalty = 0.5

-- ── Rebirths ──────────────────────────────────────────────────────────────

-- Base cost (cash) for a first rebirth
GameConfig.RebirthBaseCost = 100000

-- Each subsequent rebirth costs this multiplier times the previous cost
GameConfig.RebirthCostMultiplier = 2.5

-- Permanent income multiplier granted per rebirth (stacks multiplicatively)
GameConfig.RebirthIncomeMultiplier = 1.5

-- ── Shop ──────────────────────────────────────────────────────────────────

-- How many brainrot slots appear in the shop at once
GameConfig.ShopSlots = 6

-- Seconds between automatic shop rotations
GameConfig.ShopRefreshInterval = 60

-- ── Traps ─────────────────────────────────────────────────────────────────

-- Trap definitions: cost and effect duration (seconds)
GameConfig.Traps = {
    SlowdownTrap = {
        cost            = 500,
        speedMultiplier = 0.3,   -- reduces intruder speed to 30 %
        duration        = 5,
        description     = "Slows invaders to a crawl.",
    },
    StunTrap = {
        cost            = 1000,
        duration        = 3,
        description     = "Briefly anchors an intruder in place.",
    },
    EjectTrap = {
        cost            = 1500,
        ejectForce      = 150,   -- studs/s launch velocity
        description     = "Launches intruders out of the base.",
    },
}

-- Maximum traps a player can place at once
GameConfig.MaxTrapsPerBase = 5

-- ── DataStore ─────────────────────────────────────────────────────────────

-- DataStore key prefix (player UserId appended at runtime)
GameConfig.DataStoreKey = "PlayerData_v1_"

-- How often (seconds) the server auto-saves player data
GameConfig.AutoSaveInterval = 60

return GameConfig
