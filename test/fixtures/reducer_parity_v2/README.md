# Current movement parity oracle

This directory contains only fixture contract version 2. The 38 committed
fixtures cover the three original reviewed cases and the complete 35-case Dart
movement characterization.

Regenerate candidates with:

```sh
make rust-movement-oracle
```

Generation does not bless changes. Review the JSON diff before committing it.
Rust loads the complete directory, executes every case through canonical
`GameEngine::apply`, and compares the complete Dart state envelope, rejection,
ordered events, and exact movement evidence. The test adapter only maps the
Dart fixture representation; fog, diplomacy, roads, cities, route planning,
capacity, and hidden-obstacle decisions are made by the Rust engine.
