#!/usr/bin/env python3
"""Generate the reviewed Dart-to-Rust public export disposition ledger."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "packages/aonw_core/lib"
EXPORT_PATTERN = re.compile(r"^export\s+['\"]([^'\"]+)['\"](?:\s+show\s+[^;]+)?;$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def disposition(barrel: str, target: str) -> str:
    key = f"{barrel}:{target}"
    explicit = {
        "ai.dart:ai/ai_strategy_registry.dart": "retire",
        "ai.dart:ai/civilization/civilization_profile_registry.dart": "retire",
        "ai.dart:ai/mcts/mcts_debug.dart": "retire",
        "ai.dart:ai/mcts/mcts_simulated_state.dart": "retire",
        "ai.dart:ai/mcts/mcts_simulator.dart": "retire",
        "ai.dart:ai/strategies/basic_strategy_planning_session.dart": "retire",
        "application.dart:game/application/engine/combat_animation_fact.dart": "replace-with-protocol",
        "application.dart:game/application/engine/combat_animation_fact_codec.dart": "replace-with-protocol",
        "application.dart:game/application/lifecycle/match_lifecycle_wire_adapter.dart": "replace-with-protocol",
        "game/domain/combat.dart:combat/combat_serialization.dart": "replace-with-protocol",
        "game/domain/command.dart:command/game_command_serialization.dart": "replace-with-protocol",
        "game/domain/event.dart:event/event_serialization.dart": "replace-with-protocol",
        "game/domain/movement.dart:movement/movement_snapshot_migration.dart": "retire",
        "game/domain/save.dart:save/game_save.dart": "replace-with-protocol",
        "game/domain/save.dart:save/game_save_origin.dart": "retire",
        "game/domain/save.dart:save/multiplayer_save_name.dart": "move-to-server",
        "game/domain/save/game_save.dart:package:aonw_core/game/domain/state/game_mode.dart": "replace-with-protocol",
        "game/domain/state.dart:state/canonical_game_snapshot_codec.dart": "replace-with-protocol",
        "game/view.dart:view/player_view_state.dart": "replace-with-protocol",
        "game/view.dart:view/recipient_snapshot.dart": "replace-with-protocol",
    }
    if key in explicit:
        return explicit[key]
    if barrel == "protocol.dart" or barrel.startswith("protocol/"):
        return "replace-with-protocol"
    if barrel == "map/persistence.dart":
        return "replace-with-content"
    return "port-to-rust"


def source_entries() -> tuple[list[str], list[dict[str, str]]]:
    barrels: list[str] = []
    entries: list[dict[str, str]] = []
    for path in sorted(SOURCE_ROOT.rglob("*.dart")):
        barrel = path.relative_to(SOURCE_ROOT).as_posix()
        found = False
        statement = ""
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if statement:
                statement = f"{statement} {line}"
            elif line.startswith("export "):
                statement = line
            else:
                continue
            if not statement.endswith(";"):
                continue
            match = EXPORT_PATTERN.fullmatch(statement)
            if match is None:
                raise SystemExit(
                    f"unsupported Dart export syntax in {barrel}: {statement}"
                )
            found = True
            target = match.group(1)
            entries.append(
                {
                    "barrel": barrel,
                    "export": target,
                    "disposition": disposition(barrel, target),
                }
            )
            statement = ""
        if statement:
            raise SystemExit(f"unterminated Dart export syntax in {barrel}: {statement}")
        if found:
            barrels.append(barrel)
    barrels.sort()
    entries.sort(key=lambda entry: (entry["barrel"], entry["export"]))
    return barrels, entries


def main() -> None:
    args = parse_args()
    barrels, entries = source_entries()
    document = {
        "sourceRoot": "packages/aonw_core/lib",
        "policy": "one-current-rust-replacement-no-legacy",
        "sourceBarrelCount": len(barrels),
        "sourceExportCount": len(entries),
        "legacyPaths": False,
        "barrels": barrels,
        "entries": entries,
    }
    rendered = json.dumps(document, indent=2) + "\n"
    if args.output is None:
        print(rendered, end="")
        return
    output = args.output if args.output.is_absolute() else ROOT / args.output
    output.write_text(rendered, encoding="utf-8")


if __name__ == "__main__":
    main()
