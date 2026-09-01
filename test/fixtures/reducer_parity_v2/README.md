# Archived reducer parity evidence

This version 2 corpus is frozen, read-only migration evidence. No Rust engine,
client, test runner, generator, or release gate reads it.

The reviewed disposition of every historical case is recorded in
`engine/fixtures/canonical_fixture_migration.md`. Active Rust behavior coverage
lives only in `engine/fixtures/canonical_commands/` and uses the strict current
canonical fixture contract.

Do not add compatibility readers, adapters, projections, generators, or new
cases here. New engine and client behavior must be expressed directly through
current contracts.
