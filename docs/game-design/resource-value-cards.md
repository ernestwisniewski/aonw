# Resource Value Cards

This document describes the resource-value card contract. The goal is for
clicking a resource hex to answer: "What does this tile provide now, what will
it unlock later, and why is it worth expanding toward?".

## UI Placement

| Element | Behavior |
| --- | --- |
| Hex click | The existing inspection panel shows a `Resources` chip when the hex has at least one resource |
| Hex long-press | A compact popup shows the description, terrain, resources, and matching `Possible improvements` |
| `Resources` chip | Opens a detailed popup with one card per resource on the hex |
| Old fallback | If the model has no value cards, the popup can still show a simple resource-name list |

We do not add a separate global screen. The card is part of the map-inspection
flow because the player should see it exactly when deciding whether to explore,
found a city, or send a worker.

The long-press popup uses the same list of matching improvements as the hex
inspection model. Each improvement shows the required technology in
parentheses: red text means the active player does not have it yet, green means
the technology is already unlocked.

## Card Sections

| Section | Meaning | Data source |
| --- | --- | --- |
| Header | Resource name and `Bonus`, `Luxury`, or `Strategic` category | `ResourceType`, `GameDisplayNames.resource`, resource groups |
| `Now` | Base resource yield and the whole hex potential before improvement | `ResourceYieldRules`, `HexAssessment.yield` |
| `Improve` | Best matching improvement, its yield, and current status | `FieldImprovementRules`, `TechnologyUnlockQuery`, city/border status |
| `Later` | Technologies, research boosts, or effects that increase resource value | `TechnologyRuleset.technologies`, technology boosts and effects |
| `Expansion` | Short strategic reason to claim the tile inside borders | Resource category and dominant yield after improvement |

## Categories

| Category | Resources | Player role |
| --- | --- | --- |
| Bonus | Food and early-growth resources, for example wheat, fish, deer, sheep, rice, fruit | Faster city growth, stronger starts, and more workable tiles |
| Luxury | Gold, silver, gems, silk, spices, cotton, grapes, ivory, pearls, coffee, cocoa, tobacco, sugar | Economy, gold, and expansion reasons after the right improvement |
| Strategic | Iron, coal, oil, aluminium, uranium, horses, marble | Secures production, military, and late technologies before rivals do |

## Balance Contract

The card has no private yield table. It reads the active ruleset:

| Value | Contract |
| --- | --- |
| Base tile yield | `HexAssessment.yield`, the same unified yield preview used by city economy |
| Resource yield | `ResourceYieldRules.yieldFor(resource, ruleset)` |
| Improvement yield | `FieldImprovementRules.yieldFor(type, ruleset)` |
| Improvement unlock | `TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement` |
| Legality status | City/borders/existing improvement/city center plus technology |
| Future hooks | `ControlsResource`, `ControlsAnyResource`, `StrategicResourceProductionBonus` |

That means changes to `CityRuleset`, the improvement catalog, or technologies
automatically change card information. Documentation and UI should not manually
duplicate those values.

## Examples

| Resource | How the card should help |
| --- | --- |
| Wheat | Shows immediate food, farm after Agriculture, and the reason: faster city growth |
| Gold | Shows that the base tile may not yield anything, but a prospector camp/economy can make it an expansion target |
| Iron | Shows production potential, mine/Mining, and the later Iron Working effect |
| Horses | Shows that the tile itself is strategic and Horseback Riding increases army and expansion value |

## Out of Scope

| Out of scope | Reason |
| --- | --- |
| Resource-yield changes | The card explains the current balance; it does not tune the economy |
| New `claim resource` objectives | Future work after checking whether the card is clear |
| AI expansion scoring for resources | Requires separate scoring and telemetry |
| Inventory/luxury happiness | No closed ruleset exists for this mechanic yet |
| Automatic improvement selection | Worker actions remain manual through `Improve` |

## Potential Next Steps

| Direction | Reason |
| --- | --- |
| Objective tie-in | After discovering a valuable resource, the `Objectives` panel can suggest claiming it inside borders |
| City role suggestion | The card can say whether the area looks like a growth, production, or trade city |
| Resource scarcity goals | Strategic/luxury resources can become mid-game goals if the map has enough resource density |
| Telemetry | Measure whether players click or claim resources after seeing the card |
