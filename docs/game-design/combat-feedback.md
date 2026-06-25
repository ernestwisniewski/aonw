# Combat Feedback

This document describes feedback after combat resolution. It complements
`docs/game-design/combat-preview.md`: the preview answers "what will happen
after I click?", while post-combat feedback answers "what actually happened?".

## Mechanical Goal

| Goal | Meaning |
| --- | --- |
| Immediate confirmation | The player sees real damage and the result after the attack resolves. |
| Log consistency | Toasts, the activity log, and the combat log use the same message. |
| Previous-state memory | Removed units still have names and miniatures in the message. |
| No new save state | `previousState` is transient presentation context, not part of the save. |

## Current Feedback Layers

| Layer | Role |
| --- | --- |
| `ShowFloatingTextEffect` | Damage numbers on the map, for example `-3 HP` on the unit hex |
| `ShakeCameraEffect` | Short impact after `CombatResolvedEvent` |
| `SmoothCameraEffect` | When the active player's city is attacked, the camera first moves to the city |
| `SpawnParticleBurstEffect.cityAttacked` | Red-gold burst on the active player's attacked city |
| `GameEventNotificationMessage` | Compact toast with the combat result |
| Activity log | Persistent event record for the player |
| Combat log | Filtered combat record |
| Map pins | Quick camera return to important combat locations |

## Map Timing

Renderer effects are queued so the player first sees the attack movement and
then the result.

| Order | Effect | Rule |
| --- | --- | --- |
| 1 | `PlayCombatAnimationEffect` | Reducer attack animation blocks later effects until completion |
| 2 | `SmoothCameraEffect` for my city | Only when the defender is the active player's city |
| 3 | `ShakeCameraEffect` | Short impact after resolution |
| 4 | `cityAttacked` particles | Only on the active player's attacked city |
| 5 | Damage text | `-X HP` appears after the animation, without extra delay |
| 6 | Kill/retreat cue | `KO` or `Retreat` uses a short delay so it does not cover damage |

`ShowFloatingTextEffect.delay` is a transient renderer option. The delay is not
written to the save file and does not change domain events.

The attacked-city feedback is transient renderer state, like particles and
floating text. There is currently no cross-turn city-hex alert layer; persistent
strategic memory for the attack is carried by notifications, activity log
entries, diplomacy state, and camera-return pins.

An attack on the active player's city is assigned to the defender in the
notification provider, even when `CombatResolvedEvent` comes from an opponent
move. That makes the toast, activity log, camera-return click, and map effects
visible to the city owner in single player, hot-seat, and multiplayer snapshots.

## Combat Summary Format

The message body shows the effect on the defender first, then the attacker-side
risk:

| Case | Example |
| --- | --- |
| Combat with retaliation | `Enemy: -3 HP -> 4 HP | Warrior: -2 HP -> 8 HP` |
| No retaliation | `Enemy: -5 HP -> defeated | Archer: no retaliation` |
| Retreat | `Enemy: -6 HP -> 1 HP, retreat | Warrior: no retaliation` |
| Attacker defeated | `Enemy: -2 HP -> 1 HP | Warrior: -9 HP -> defeated` |

Details remain more technical:

| Detail | Meaning |
| --- | --- |
| `Defender defeated` | Defender was removed |
| `Attacker defeated` | Attacker was removed |
| `Defender retreated` | Defender survived due to retreat |
| `Attack: -X HP` | Attack damage |
| `Retaliation: -X HP` | Retaliation damage |
| `No retaliation` | Defender did not or could not retaliate |
| `Roll X` | Combat RNG variance |
| Modifier labels | Terrain, technology, rank, or garrison |

## Previous-State Context

After combat resolution, a unit may be removed from `GameState`. Without extra
context, the toast would only show `unit.id` or lose its miniature.

| Element | Decision |
| --- | --- |
| Storage location | `GameEventNotification.previousState` |
| Source | `GameCommandController` passes the pre-dispatch state |
| Lifetime | Notification/log only, in UI memory |
| Save schema | No change |
| Usage | Names, miniatures, playerId assignment for the combat toast |

## Out of Scope

| Out of scope | Reason |
| --- | --- |
| New unit animations | `PlayCombatAnimationEffect` already exists; this work improves message clarity |
| New damage numbers | `GameEventRendererEffectMapper` already creates floating damage text |
| Sound hook | Separate combat-juice phase |
| Balance change | Feedback describes the result; it does not change the result |
| New domain events | `CombatResolvedEvent` plus existing kill/retreat events are enough |

## Further Improvement Direction

| Problem | Possible improvement |
| --- | --- |
| The player wants to know why damage had that value | Expanded modifier breakdown in the combat log |
| Floating text gets lost with many effects | Queueing/offsetting multiple texts on one hex |
| Combat lacks drama | Sound hook, hit flash, and stronger per-type particles |
| RNG is hard to read | Show damage range in preview and final roll in a more human form |
