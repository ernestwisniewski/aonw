# World Wonders

World wonders are a separate production domain for globally unique, high-cost
structures. They are not `CityBuildingType`s: regular buildings are repeatable
city-local infrastructure, while wonders need global ownership, race resolution,
host-city state, and empire-scoped effects.

## Core Model

The shared core owns the source of truth:

| Area | Source |
| --- | --- |
| Domain export | `packages/aonw_core/lib/game/domain/wonder.dart` |
| Catalog | `packages/aonw_core/lib/game/domain/wonder/wonder_catalog.dart` |
| Availability | `wonder_availability_policy.dart` |
| Completion and refunds | `wonder_completion_resolver.dart` |
| Standing effects | `wonder_effect_resolver.dart` |
| Global completion state | `WonderRegistry` |

Each completed wonder is recorded globally in `WonderRegistry.completedBy`
(`WonderType -> playerId`) and also attached to the host city in
`GameCity.wonders`. The registry blocks future attempts worldwide. The host
city determines whether standing effects are active.

Capture transfers the host city and therefore transfers the active wonder
effects. Destroying the host city leaves the wonder globally completed and
blocked, but inactive because no surviving city hosts it.

## Production Rules

Wonders are queued through `WonderProductionTarget` and `StartWonderCommand`.
A city can start a wonder only when all gates pass:

| Gate | Meaning |
| --- | --- |
| Global uniqueness | The wonder is not already completed in `WonderRegistry` |
| Technology | The owning player has researched the wonder's unlock tech |
| Host requirements | Terrain, river, mountain, coast, or resource gates pass |
| One-at-a-time | The player has no other wonder already in production |
| Current queue | The city is not already building a wonder |

Normal completion resolves in the core turn pipeline after city production and
before research processing. Rush completion uses the same claim/refund semantics
from the app reducer and `PersistentCityProductionResolver`.

If multiple players complete the same wonder in the same turn, the first player
in the established processing order wins. After a claim, every losing queue for
that wonder is removed and its invested production is returned to that city's
`productionOverflow`.

## Effects

Standing effects are centralized in `WonderEffectResolver`, then consumed by
city economy, science yield, stability inputs, turn processing, UI forecasts,
and AI scoring.

| Effect type | Behavior |
| --- | --- |
| `EmpireFlatYieldEffect` | Adds a yield to every active owner city |
| `HostCityFlatYieldEffect` | Adds yield only to the wonder host city |
| `EmpireScienceEffect` | Adds science per active owner city |
| `EmpireGoldMultiplierEffect` | Multiplies owner gold output |
| `EmpireProductionMultiplierEffect` | Multiplies owner production output |
| `StabilityEffect` | Adds stability through `StabilityInputBuilder` |
| `GrantFreeTechnology` | Completes the active research target and clears it |
| `GrantGold` | Adds gold once on completion |
| `ProductionBurst` | Adds production overflow to the host city once |

## Catalog

The current standard catalog has 11 wonders:

| Wonder | Tech gate | Cost | Requirement | Standing effect | Completion |
| --- | --- | ---: | --- | --- | --- |
| Great Library | `writing` | 120 | - | +1 science per city | Complete active research |
| Hanging Gardens | `waterEngineering` | 120 | Adjacent river | +2 food host, +1 food per city | - |
| Great Wall | `militaryOrganization` | 140 | - | +3 defense per city | - |
| Petra | `stoneworking` | 150 | City-center desert | +2 food, +2 production, +1 gold host | - |
| Central Bank | `banking` | 220 | - | +15% gold | +120 gold |
| Imperial University | `education` | 240 | - | +2 science per city | - |
| Grand Cathedral | `law` | 200 | Marble | +4 stability | - |
| Mother Factory | `steamPower` | 360 | Coal or iron | +10% production | +80 production overflow |
| National Observatory | `scientificMethod` | 380 | Adjacent mountain | +3 science per city | - |
| Svalbard Seed Vault | `nuclearPhysics` | 340 | City-center snow | +1 food per city, +3 stability | - |
| Grand Exposition | `radio` | 400 | - | +2 gold per city, +2 stability | - |

Terrain requirements use the host city's base terrain through `TileYieldRules`,
so river overlays do not make a river-only tile count as desert, snow, or any
other base terrain.

## UI And Input

The city production panel has a Wonders section before Units. Locked wonders
show explicit missing requirement labels for technology, terrain, resource,
river, or mountain gates. Completed wonders show a "Built by ..." label and
stay unavailable.

Gamepad navigation treats wonders as first-class production choices with keys
in the form `wonder:<name>`. Selecting a wonder dispatches the same
`StartWonderCommand` path as tapping the row.

## AI And Balance

AI production scoring includes wonders as candidates after availability checks.
The initial scoring uses discounted effect value minus production cost and race
risk, and respects the one-at-a-time rule.

Wonders do not add a separate score category in the current scoring model. They
can still affect score pressure indirectly through stronger science, economy,
stability, growth, production, conquest, or survival. If direct wonder points are
added later, update `EmpireScoreCalculator` and the scoring docs in the same
change.

Balance should be checked with the existing simulation and telemetry tools after
catalog changes. In particular, watch for over-valued science wonders, excessive
production multiplier compounding, and terrain-locked wonders that are too rare
to matter on bundled maps.

## Serialization

`WonderRegistry`, city-hosted wonders, `WonderProductionTarget`,
`StartWonderCommand`, `CityBuiltWonderEvent`, and
`WonderProductionRefundedEvent` round-trip through the existing save, snapshot,
wire, and event serialization paths. There is no parallel wonder-specific save
path.
