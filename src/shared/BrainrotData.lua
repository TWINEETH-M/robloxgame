--[[
    BrainrotData.lua
    Shared module defining all brainrot characters available in the game.
    Each entry includes name, rarity tier, passive income per second,
    purchase cost, and a meme-themed description.
--]]

local BrainrotData = {}

-- Rarity tiers (ordered from most to least common)
BrainrotData.Rarities = {
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
}

-- Rarity display colors (BrickColor/Color3 hex strings for UI)
BrainrotData.RarityColors = {
    Common    = Color3.fromRGB(200, 200, 200), -- White/Grey
    Uncommon  = Color3.fromRGB(0,   200,  50), -- Green
    Rare      = Color3.fromRGB(0,   112, 221), -- Blue
    Epic      = Color3.fromRGB(163,  53, 238), -- Purple
    Legendary = Color3.fromRGB(255, 140,   0), -- Orange
    Mythic    = Color3.fromRGB(220,  20,  60), -- Red
}

-- Rarity drop-weight (higher = more common in shop rotations)
BrainrotData.RarityWeights = {
    Common    = 50,
    Uncommon  = 25,
    Rare      = 15,
    Epic      = 7,
    Legendary = 2,
    Mythic    = 1,
}

--[[
    Brainrot character table.
    Fields:
        id          (string)  Unique identifier key
        name        (string)  Display name
        rarity      (string)  One of BrainrotData.Rarities
        income      (number)  Cash earned per second while owned
        cost        (number)  Buy price in cash
        description (string)  Meme-themed flavour text
--]]
BrainrotData.Brainrots = {
    {
        id          = "noobini_pizzanini",
        name        = "Noobini Pizzanini",
        rarity      = "Common",
        income      = 1,
        cost        = 50,
        description = "A noob with a pizza obsession. Will work for slices.",
    },
    {
        id          = "skibidi_sigma",
        name        = "Skibidi Sigma",
        rarity      = "Common",
        income      = 2,
        cost        = 100,
        description = "Skibidi toilet energy. Sigma grindset only.",
    },
    {
        id          = "ohio_rizz_cat",
        name        = "Ohio Rizz Cat",
        rarity      = "Uncommon",
        income      = 5,
        cost        = 300,
        description = "Only in Ohio can a cat have this much rizz.",
    },
    {
        id          = "grimace_gyatt",
        name        = "Grimace Gyatt",
        rarity      = "Uncommon",
        income      = 8,
        cost        = 500,
        description = "McDonald's never prepared us for this.",
    },
    {
        id          = "baby_gronk",
        name        = "Baby Gronk",
        rarity      = "Rare",
        income      = 15,
        cost        = 1200,
        description = "Youngest sigma grindset ever recorded. Mogged.",
    },
    {
        id          = "fanum_tax_collector",
        name        = "Fanum Tax Collector",
        rarity      = "Rare",
        income      = 20,
        cost        = 2000,
        description = "The IRS wishes they were this efficient at collecting.",
    },
    {
        id          = "icy_spice",
        name        = "Icy Spice",
        rarity      = "Epic",
        income      = 40,
        cost        = 5000,
        description = "She hit the griddy so hard the server froze.",
    },
    {
        id          = "livvy_dunne_bot",
        name        = "Livvy Dunne Bot",
        rarity      = "Epic",
        income      = 55,
        cost        = 7500,
        description = "An AI trained entirely on gym content. Scary.",
    },
    {
        id          = "duke_dennis_clone",
        name        = "Duke Dennis Clone",
        rarity      = "Legendary",
        income      = 100,
        cost        = 20000,
        description = "Does it for the AMP. Always plotting the takeover.",
    },
    {
        id          = "kai_cenat_ai",
        name        = "Kai Cenat AI",
        rarity      = "Mythic",
        income      = 250,
        cost        = 75000,
        description = "Streaming 24/7 even in your base. Chat is hyped.",
    },
}

-- Build a lookup table by id for O(1) access
BrainrotData.ById = {}
for _, brainrot in ipairs(BrainrotData.Brainrots) do
    BrainrotData.ById[brainrot.id] = brainrot
end

-- Returns a list of brainrot ids weighted by rarity for shop pool generation
function BrainrotData.GetWeightedPool()
    local pool = {}
    for _, brainrot in ipairs(BrainrotData.Brainrots) do
        local weight = BrainrotData.RarityWeights[brainrot.rarity] or 1
        for _ = 1, weight do
            table.insert(pool, brainrot.id)
        end
    end
    return pool
end

return BrainrotData
