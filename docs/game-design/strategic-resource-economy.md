# Strategic Resource Economy

This document defines the player-facing and balance contract for strategic
resource production, storage, allocation, and trade.

## Resource Roles

| Role | Current behavior |
| --- | --- |
| Bonus | Local tile and city value; no global stockpile |
| Luxury | Empire presence, trade, and economic value; duplicates may be traded |
| Strategic presence | Iron, horses, coal, and uranium keep the existing control/import gate |
| Strategic stockpile | Oil and aluminium are produced, stored, allocated, and delivered in quantities |

The split is declared by `ResourceCatalog`, not inferred from enum names or UI
lists. It lets later balance work migrate another resource without rewriting
the stockpile engine.

## Production And Turn Flow

An oil well on revealed oil produces one oil per turn. A bauxite mine on
revealed aluminium produces one aluminium per turn. Output belongs to the player
who currently controls the source hex. The values are configured by
`GameRuleset.resources`.

Strategic extraction is credited before resource-trade settlement. A newly
produced unit can therefore be exported in that economy step, while production
selection still uses the stock actually present when its command is resolved.
Worker completion occurs later and starts contributing from the following
eligible extraction step.

Current unit costs are:

| Unit | Strategic allocation |
| --- | --- |
| Tank | 2 oil |
| Recon plane | 1 aluminium or 1 oil, explicitly selected when both are viable |

The cost is reserved when production starts. It is not maintenance and is not
charged again at rush or completion.

## Allocation Rules

- Availability uses free stock plus the allocation refundable from the same
  city's active target.
- Starting or replacing a target is atomic: refund the old allocation, validate
  the new quote, then debit and persist the selected allocation.
- Re-selecting the same target and allocation is a semantic and identity no-op.
- Replacing a unit with a building, wonder, or project releases its allocation.
- A spawn-blocked completed unit keeps its allocation and clearly reports that
  it is ready but has no legal tile.
- Losing a source or import never deletes an existing unit and does not cancel
  already allocated production.

## Trade Settlement

Stockpiled resource agreements carry `amountPerTurn`. A missing value from
legacy data means one. The exporter must have the quantity when settlement
runs, the importer must have the gold, and the route policy must allow delivery.
Only then are stock and payment transferred.

Two reciprocal legs created by barter share an exchange group. The entire
group settles or none of it does. War blocks delivery through the diplomacy
route policy. A blocked or stock-starved turn ages the agreement without moving
stock or gold; lack of payment ends the exchange group.

## Player Interface

The top resource strip summarizes available strategic types and shortages. Its
resource breakdown is the global explanation surface:

- stored, allocated, and free quantity per stockpiled resource;
- domestic production, imports, exports, and net flow per turn;
- each improvement source with resource, improvement, city, hex, and output;
- each city allocation with target and quantity;
- navigation from a source or allocation to that city's production panel.

The city production panel uses the same domain quote as the command resolver.
Unit rows show strategic costs and quantitative shortages. Details show every
blocker, not only the first. Active production shows its allocation, rush shows
only its gold cost, and a completed spawn-blocked unit has a distinct status.

When a replacement has invested production or resources, confirmation shows
what will be released, what will be allocated, and the resulting free stock.
Multiple viable resource bundles open an explicit selector. Dispatch is
asynchronous: the panel disables duplicate input while pending, closes only
after acceptance, and stays open with refreshed data after rejection.

## AI Contract

Basic and MCTS production planners share `UnitProductionAvailability` with the
authoritative resolver and account for earlier city reservations in the same
planning pass. Trade AI protects a stock reserve, values production surplus,
and proposes real quantities. MCTS simulated states preserve stockpiles,
allocations, agreements, improvements, and the economy profile; its heuristic
uses a deliberately small reward for useful stock and positive flow.

## Balance And Follow-up

The initial one-unit extraction rate and unit costs are intentionally small and
readable. Balance telemetry should track turns with zero free stock, blocked
production attempts, allocation duration, failed deliveries, source capture,
and stock left unused at match end before migrating more resource types.

Continuous army fuel/ammunition upkeep is deferred. If introduced, shortage
must reduce movement, healing, or reinforcement through an explicit status; it
must never silently delete units. Luxury stability and diplomacy bonuses also
remain separate from the stockpile contract.
