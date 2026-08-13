# Current Rust command parity oracle

This directory contains only fixture contract version 2. The 44 committed
fixtures cover 38 movement cases and six cancel/skip/fortify cases generated
from the independently reviewed Dart corpus.

Regenerate candidates with:

```sh
make rust-engine-oracle
```

Generation does not bless changes. Review the JSON diff before committing it.
Rust loads the complete directory, executes every case through canonical
`GameEngine::apply`, and compares the complete Dart state envelope, rejection,
ordered events, and exact movement evidence. The test adapter only maps the
Dart fixture representation; fog, diplomacy, roads, cities, route planning,
capacity, hidden-obstacle decisions, and unit actions are made by the Rust
engine.
