# Steal a Brainrot — Roblox Game

A fully-featured Roblox replica of **"Steal a Brainrot"** — a meme-themed tycoon/PvP hybrid.  
Built with [Rojo](https://rojo.space/) for easy sync into Roblox Studio.

---

## 🎮 Game Overview

Players collect **brainrots** (meme-inspired characters) that generate passive income, defend their base with traps, and raid other players' bases to steal their brainrots.

### Core Loop
1. **Collect** — Buy brainrots from the rotating shop to earn passive cash
2. **Defend** — Lock your base and place traps to repel raiders
3. **Raid** — Sneak into another player's base and steal their brainrots
4. **Progress** — Rebirth for a permanent income multiplier and start again stronger

---

## 🚀 Setup with Rojo

### Prerequisites
- [Rojo](https://rojo.space/) (v7+)
- Roblox Studio

### Steps

```bash
# 1. Install Rojo (if not already)
aftman install   # or follow https://rojo.space/docs/installation/

# 2. Start the Rojo server in this directory
rojo serve default.project.json

# 3. In Roblox Studio, connect the Rojo plugin to localhost:34872
```

All source files will be synced into the correct Roblox services automatically.

---

## 📁 Project Structure

```
StealABrainrot/
├── default.project.json          Rojo project config
├── README.md
└── src/
    ├── server/                   → ServerScriptService
    │   ├── PlayerDataManager.server.lua   Data save/load, leaderstats
    │   ├── IncomeSystem.server.lua        Passive income loop
    │   ├── BrainrotShop.server.lua        Shop rotations & purchases
    │   ├── StealingSystem.server.lua      PvP steal mechanic (anti-cheat)
    │   ├── BaseDefenseSystem.server.lua   Base lock, traps, intruder detection
    │   └── RebirthSystem.server.lua       Rebirth progression
    │
    ├── client/                   → StarterPlayerScripts
    │   ├── HudGui.client.lua              Always-visible HUD
    │   ├── ShopGui.client.lua             Brainrot marketplace UI
    │   ├── BaseGui.client.lua             Base management & inventory UI
    │   └── StealGui.client.lua            Raid UI, progress bar, alarm alerts
    │
    ├── shared/                   → ReplicatedStorage/Shared
    │   ├── BrainrotData.lua               All brainrot definitions
    │   ├── GameConfig.lua                 Central game constants / tuning
    │   └── Remotes.lua                    RemoteEvent/Function definitions
    │
    └── workspace/                → Workspace/Scripts
        ├── BaseTemplate.lua               Generates per-player bases
        └── MapSetup.lua                   Central map layout & lighting
```

---

## 🧠 Brainrot Roster

| Name | Rarity | Income/s | Cost |
|------|--------|----------|------|
| Noobini Pizzanini | Common | $1/s | $50 |
| Skibidi Sigma | Common | $2/s | $100 |
| Ohio Rizz Cat | Uncommon | $5/s | $300 |
| Grimace Gyatt | Uncommon | $8/s | $500 |
| Baby Gronk | Rare | $15/s | $1,200 |
| Fanum Tax Collector | Rare | $20/s | $2,000 |
| Icy Spice | Epic | $40/s | $5,000 |
| Livvy Dunne Bot | Epic | $55/s | $7,500 |
| Duke Dennis Clone | Legendary | $100/s | $20,000 |
| Kai Cenat AI | Mythic | $250/s | $75,000 |

Rarity colours: **Common** (grey) · **Uncommon** (green) · **Rare** (blue) · **Epic** (purple) · **Legendary** (orange) · **Mythic** (red)

---

## ⚙️ Game Mechanics

### Shop
- 6 rotating slots refreshed every **60 seconds**
- Weighted random selection by rarity
- Sell brainrots for **50%** of their purchase price

### Base Lock
- Activate a **30-second** invulnerability window
- **120-second** cooldown before you can lock again
- Lock indicator glows green (locked) or red (unlocked)

### Stealing
- Must be within **20 studs** of the target base boundary
- Stay inside for **5 seconds** to complete the steal
- Thief's movement speed is reduced **50%** during the attempt
- **60-second** cooldown after each steal attempt
- Server validates all proximity and ownership — no client trust

### Traps
| Trap | Cost | Effect |
|------|------|--------|
| Slowdown Trap | $500 | Reduces intruder speed to 30% for 5s |
| Stun Trap | $1,000 | Freezes intruder for 3s |
| Eject Trap | $1,500 | Launches intruder out of the base |

Maximum **5 traps** per base.

### Rebirths
- Cost starts at **$100,000** and multiplies by **2.5×** each time
- Resets cash (back to starting $500) and clears all brainrots/traps
- Grants a permanent **1.5× income multiplier** (stacks multiplicatively)

---

## 🔧 Game Configuration

All tunable constants live in `src/shared/GameConfig.lua`:

| Constant | Default | Description |
|----------|---------|-------------|
| `StartingCash` | 500 | Cash for new players |
| `MaxBrainrotsPerBase` | 20 | Base inventory cap |
| `BaseLockDuration` | 30s | Lock invulnerability window |
| `BaseLockCooldown` | 120s | Minimum time between locks |
| `StealTime` | 5s | Time to complete a steal |
| `StealCooldown` | 60s | Cooldown between steal attempts |
| `ShopSlots` | 6 | Visible shop items at once |
| `ShopRefreshInterval` | 60s | Shop rotation interval |
| `RebirthBaseCost` | 100,000 | First rebirth cost |
| `RebirthCostMultiplier` | 2.5× | Exponential cost scaling |
| `RebirthIncomeMultiplier` | 1.5× | Permanent income boost per rebirth |

---

## 🤝 Contributing

1. Fork the repo and create a feature branch
2. Follow the existing Luau style: PascalCase functions, camelCase variables
3. Keep server logic server-authoritative — never trust the client
4. Test locally with Rojo + Roblox Studio before opening a PR
5. Document new functions and modules with header comments

---

## 📜 License

MIT — feel free to learn from and build upon this project.
