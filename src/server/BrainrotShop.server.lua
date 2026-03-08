--[[
    BrainrotShop.server.lua
    Manages the brainrot marketplace where players can purchase brainrots.

    Responsibilities:
        • Maintain a rotating shop listing (refreshes every ShopRefreshInterval)
        • Handle BuyBrainrot RemoteEvent (validate, deduct cash, add to inventory)
        • Broadcast updated shop listings to all clients via ShopUpdate
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared", 10)
local BrainrotData = require(Shared:WaitForChild("BrainrotData", 10))
local GameConfig   = require(Shared:WaitForChild("GameConfig",   10))
local Remotes      = require(Shared:WaitForChild("Remotes",      10))

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

-- ── Shop state ────────────────────────────────────────────────────────────

local currentShop = {}          -- array of brainrot ids currently in the shop
local nextRefresh = 0           -- os.time() timestamp of next refresh

-- Build a new random shop listing using weighted rarity pool
local function RefreshShop()
    local pool    = BrainrotData.GetWeightedPool()
    local slots   = GameConfig.ShopSlots
    local chosen  = {}
    local seen    = {}

    -- Shuffle pool then pick unique entries up to ShopSlots
    local shuffled = {}
    for _, id in ipairs(pool) do table.insert(shuffled, id) end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    for _, id in ipairs(shuffled) do
        if not seen[id] then
            seen[id] = true
            table.insert(chosen, id)
            if #chosen >= slots then break end
        end
    end

    currentShop = chosen
    nextRefresh  = os.time() + GameConfig.ShopRefreshInterval

    -- Build the payload the client needs
    local payload = {}
    for _, id in ipairs(currentShop) do
        local b = BrainrotData.ById[id]
        if b then
            table.insert(payload, {
                id          = b.id,
                name        = b.name,
                rarity      = b.rarity,
                income      = b.income,
                cost        = b.cost,
                description = b.description,
            })
        end
    end

    -- Broadcast to all clients
    Remotes.ShopUpdate:FireAllClients(payload)
    return payload
end

-- ── Purchase handler ──────────────────────────────────────────────────────

local function OnBuyBrainrot(player, brainrotId)
    -- Validate input type
    if type(brainrotId) ~= "string" then return end

    local pdm  = GetPDM()
    if not pdm then return end
    local data = pdm.GetData(player)
    if not data then return end

    -- Must be in current shop rotation
    local inShop = false
    for _, id in ipairs(currentShop) do
        if id == brainrotId then
            inShop = true
            break
        end
    end
    if not inShop then
        warn("[BrainrotShop] " .. player.Name .. " tried to buy a brainrot not in shop: " .. brainrotId)
        return
    end

    -- Validate brainrot exists in data table
    local brainrot = BrainrotData.ById[brainrotId]
    if not brainrot then return end

    -- Capacity check
    if #data.brainrots >= GameConfig.MaxBrainrotsPerBase then
        Remotes.UpdatePlayerData:FireClient(player, { error = "Base is full!" })
        return
    end

    -- Funds check
    if data.cash < brainrot.cost then
        Remotes.UpdatePlayerData:FireClient(player, { error = "Not enough cash!" })
        return
    end

    -- Deduct cash and add brainrot
    data.cash = data.cash - brainrot.cost
    table.insert(data.brainrots, brainrotId)

    pdm.UpdateLeaderstats(player)
    pdm.SyncToClient(player)
end

-- ── Sell handler ──────────────────────────────────────────────────────────

local function OnSellBrainrot(player, brainrotId)
    if type(brainrotId) ~= "string" then return end

    local pdm  = GetPDM()
    if not pdm then return end
    local data = pdm.GetData(player)
    if not data then return end

    local brainrot = BrainrotData.ById[brainrotId]
    if not brainrot then return end

    -- Find and remove the first occurrence in inventory
    for i, id in ipairs(data.brainrots) do
        if id == brainrotId then
            table.remove(data.brainrots, i)
            -- Sell for 50% of buy price
            data.cash = data.cash + math.floor(brainrot.cost * 0.5)
            pdm.UpdateLeaderstats(player)
            pdm.SyncToClient(player)
            return
        end
    end
end

-- ── Connect remotes ───────────────────────────────────────────────────────

Remotes.BuyBrainrot:Connect(OnBuyBrainrot)
Remotes.SellBrainrot:Connect(OnSellBrainrot)

-- Send current shop to newly joined players
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- allow PlayerDataManager to finish loading
    local payload = {}
    for _, id in ipairs(currentShop) do
        local b = BrainrotData.ById[id]
        if b then
            table.insert(payload, {
                id          = b.id,
                name        = b.name,
                rarity      = b.rarity,
                income      = b.income,
                cost        = b.cost,
                description = b.description,
            })
        end
    end
    Remotes.ShopUpdate:FireClient(player, payload)
end)

-- ── Shop rotation loop ────────────────────────────────────────────────────

task.spawn(function()
    -- Initial shop load
    RefreshShop()

    while true do
        task.wait(1)
        if os.time() >= nextRefresh then
            RefreshShop()
        end
    end
end)
