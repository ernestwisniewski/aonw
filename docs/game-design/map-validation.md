# Map Validation

This document describes the map-validation contract. The goal is to quickly
detect maps with bad starts, empty economies, or contact pacing that does not
fit short game presets.

## System Goal

The validator does not generate maps and does not fix them automatically. It
should produce readable `errors` and `warnings` so bundled maps and future
editor-created maps can be checked before playtesting.

| Type | Meaning |
| --- | --- |
| `error` | The map/setup should not enter normal play |
| `warning` | The map is playable, but the setup may be poor for a specific pace |

## Lobby UX

The lobby runs `MapValidator.validate(...)` for:

| Data | Source |
| --- | --- |
| Map | `activeMapProvider(selection)` |
| Player count | Current lobby player slots |
| Game pace | `MatchRules.gameLength` from the selected preset |

`errors` block local game start and create-match because they indicate a dead
or unplayable setup. `warnings` are non-blocking: the player sees a warning
panel but can still start the game. This is intentional for 60-minute games,
where a large map may still be a deliberate choice but may have slow first
contact.

## v1 Scope

`MapValidator.validate(...)` checks:

| Area | What is measured | Why |
| --- | --- | --- |
| Player count | 2-4 players | Matches current lobby UI and player palette |
| Passable land | Minimum 45% passable tiles | Map cannot be mostly water/mountains for land units |
| Start sites | Initial settler must be able to found a city | Player cannot start from a dead position |
| First ring | Minimum 4 passable tiles around the settler | Start must have room for first decisions |
| First-ring food | Minimum 1 food resource in first contact | Early growth cannot be blind or too slow |
| City control | Minimum 2 valid controlled-hex candidates | City founding must have a legal territory draft |
| Resource density | Food, strategic, and luxury resources | Map cannot be economically empty |
| First contact | Start distance | Players do not start too close; short games warn when contact is too slow |

## Default Thresholds

| Parameter | Value | Balance note |
| --- | --- | --- |
| `minPlayerCount` | 2 | Below this, 4X loses conflict and comparison |
| `maxPlayerCount` | 4 | Matches current lobby |
| `minPassableTileRatio` | 45% | Below this, maps often block movement and domination |
| `minPassableTilesInFirstRing` | 4 | Start must have several real options |
| `minFoodResourcesInFirstRing` | 1 | The first growth/worker goal must make sense |
| `minControlledCandidates` | 2 | Matches `CityFoundingDraft.requiredControlledHexes` |
| `minStartDistance` | 6 hexes | Less creates too-fast start collisions |
| `maxShortGameStartDistance` | 14 hexes | Above this, a 60-minute game may feel too empty |
| `maxShortGameTilesPerPlayer` | 180 | Above this, a short game needs more players or a smaller map |
| `minFoodResourcesPerPlayer` | 2 | Global early-economy backup |
| `minStrategicResources` | max(2, player count) | Military and later decisions should not be randomly cut off |
| `minLuxuryResources` | max(2, player count) | Map should provide expansion and trade goals |

## Bundled Maps

| Map | Status | Note |
| --- | --- | --- |
| `verdantia` | Passes for 2-4 players | Added the first layer of food/strategic/luxury resources |
| `myranth` | Passes for 2-3 players | Smaller capacity than `verdantia`; strategic resources and snowy northeast traversal are covered by tests |
| `terenos` | Passes for 2-3 players | Smaller capacity than `verdantia`; strategic resource minimums and objectives are covered by tests |

`verdantia` may still warn for 2-player 60-minute games because the map is
large and first contact is distant. That is correct: the warning appears in the
lobby and does not block play.

## Problem Codes

| Code | Type | Meaning |
| --- | --- | --- |
| `invalid_player_count` | error | Setup has a player count outside the allowed range |
| `map_has_no_tiles` | error | Map is empty |
| `low_passable_tile_ratio` | error | Too few tiles are available for land units |
| `low_food_resource_density` | error | Too few food resources for the player count |
| `low_strategic_resource_density` | error | Too few strategic resources |
| `low_luxury_resource_density` | error | Too few luxury resources |
| `start_site_not_foundable` | error | Initial settler stands on a tile without a legal city center |
| `start_site_low_land_ring` | error | Too few passable tiles in the first ring |
| `start_site_low_food` | error | No food resource near the start |
| `start_site_low_city_control` | error | Too few legal tiles for initial city control |
| `start_sites_too_close` | error | Starts are too close together |
| `short_game_slow_first_contact` | warning | 60-minute game may be too quiet because start distance is high |
| `short_game_large_map` | warning | 60-minute game may be too slow because tiles per player are high |

## What The System Does Not Do Yet

- It does not calculate full pathfinding distance between starts yet; it uses
  hex distance.
- It does not check yield symmetry per player yet.
- It does not validate naval starts or special maps yet.
- It does not perform automatic resource painting in the editor.
