# KinkdomClicker Game Mechanics
This file serves as a global reference for the mechanics of the KinkdomClicker project. It ensures that the AI assistant remembers the project's logic and architecture across new chats.

## 1. Core Architecture
- The game uses the Godot Engine (`.gd` scripts and `.tscn` scenes).
- **BigNum**: All major currencies and costs use a custom `BigNum` class to handle large incremental numbers beyond standard float/int limits.
- **Game Loop (`Game.gd`)**: Central hub managing updates, income recalculation (`currentGoldPerSecond`, `currentBaseNetIncome`, `currentPrayerIncome`), offline progress simulation, and global state (Developer Mode with x1000 speed/power).

## 2. Economy & Buildings
- **Currencies**: Gold (main currency) and Prayers (prestige currency).
- **Buildings (`BuildingManager.gd`, `BuildingData.gd`)**:
  - Cost scales exponentially based on the formula: `base_cost * cost_multiplier * 1.2^count`.
  - Generates gold (income) and prayers (`prayer_income`).
  - Has a gold upkeep that subtracts from net income.
  - Can provide synergy bonuses to other buildings.
- **Income Multipliers**: Affected by global multipliers, achievements (10% per achievement), prestige multipliers, and artifact/captive bonuses.

## 3. Upgrades System (`UpgradeManager.gd`, `EffectSystem.gd`)
- Upgrades cost gold and require "crafting time".
- **Forge Speed**: Reduces the time it takes to complete an upgrade. Boosted by the "Кузница" (Forge) building and ascension skills.
- **Effects (`EffectSystem.gd`)**: Includes click power bonuses, click from income, building income multipliers, global income multipliers, building synergies, and building discounts.

## 4. War & Troops (`WarManager.gd`, `TroopData.gd`, `CommanderData.gd`)
- **Troop Types**: Militia, Pikeman, Swordsman, Archer, Cavalry, Knight, Paladin, Griffon Rider.
- Troops have base power, base cost, training time, and upkeep.
- Training speed is boosted by the building that unlocks the troop (+5% speed per building count).
- **Commanders**: Each troop type has a unique Commander.
  - Commanders have HP, take damage during lost battles, and slowly heal.
  - They give massive power multipliers to their troop type, have a chance for critical hits, and increase loot.
  - Commanders level up via XP gained from Expeditions.

## 5. Expeditions & Combat (`ExpeditionManager.gd`)
- **Map & Nodes**: A progressive Barbarian Campaign with stages and Map Tiers. Boss camps have massively boosted stats.
- **Missions**:
  - **Scouting**: Sends units to discover enemy counts; small skirmishes occur, calculating intel gained.
  - **Attack**: Turn-based auto-combat using an `ArmyGroup`.
- **Combat Mechanics**:
  - Rounds of combat where both sides deal damage based on total power.
  - **Mob Effect**: Outnumbering the enemy grants a power multiplier (up to 1.5x for 10:1 ratio).
  - Player casualties are calculated, with 3-5% of lost troops "fleeing" back to the kingdom, and the rest dying. Commander HP is reduced based on troop casualty percentage.
- **Rewards**: Gold, Captives (provide global income bonus via Ascension skills), Commander XP, and a chance to drop Artifacts.

## 6. Archeology (`ArcheologyManager.gd`)
- **Archeologists**: Trained using gold (base 50k) and time. Max capacity depends on the Archeology Guild building count and Ascension skills.
- **Expeditions**: Archeologists can be sent on timed missions with varying difficulties (Easy, Medium, Hard, Impossible, Legendary).
- **Danger Mechanics**: Each minute of an expedition carries a risk of death (`death_chance_per_min`). Surviving archeologists have a chance to find Artifacts and gather gold.
- **Artifacts**:
  - Have levels (1-10+). Can be merged in inventory (two identical levels = one higher level).
  - **Kingdom Equip**: Grants global buffs (gold multiplier, building cost reduction, army power, army upkeep reduction).
  - **Commander Equip**: Boosts specific troop power and reduces their upkeep.

## 7. Ascension / Prestige (`AscensionManager.gd`)
- Resets the game state (gold, buildings, troops, map) but retains Prayers, Lifetime statistics, and (if upgraded) Commanders.
- **Skills Shop**: Prayers are spent to buy/upgrade permanent skills in categories:
  - **General**: Gold multipliers, forge speed, upkeep reduction.
  - **Commanders**: Keeping commanders on reset, +XP%, +Power%, +Regen%, Captives bonus.
  - **Troops**: Global power, discount, speed, and specific troop upkeep reductions.
  - **Archeology**: Max expeditions, artifact drop chances, guild capacity, lower danger, higher max duration, unlocking new difficulties.

## 8. Achievements (`AchievementManager.gd`)
- Tracks progression across gold, buildings, upgrades, troop counts, expedition map tiers, archeologists, and artifacts.
- Each unlocked achievement gives a cumulative +10% bonus to global income (`get_income_multiplier`).
