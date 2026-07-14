## Summary

<!-- What does this change do, and why? -->

## Related issues

<!-- e.g. Closes #123 -->

## Checklist

- [ ] `make bootstrap` succeeds without changing committed lockfiles.
- [ ] `make analyze` passes with the shared fatal policy for all four packages.
- [ ] `make ci` passes (generated-code drift, format, analysis, architecture, mutation, coverage, and generated-client smoke test).
- [ ] `make coverage-check` passes; any baseline or policy change preserves the historical ratchet and is explained in the summary.
- [ ] `make architecture` passes; any architecture baseline change only reduces existing above-target debt and is explained in the summary.
- [ ] `make mutation` passes; any mutation census change is explained and introduces no surviving mutant.
- [ ] `make critical-e2e-test` passes when local persistence or multiplayer auth/match/command/reconnect behavior changed.
- [ ] Generator input changes were regenerated deliberately and the resulting build-runner, localization, Serverpod, and migration diffs were reviewed (`make generated-code-check`).
- [ ] Docs updated when behavior, persistence, APIs, game rules, or build/deploy flows changed.
- [ ] Architecture boundaries and accepted ADRs respected (see `test/architecture/layer_boundaries_test.dart` and `docs/adr/README.md`).

<!-- For Serverpod schema, migration, Compose, or deploy changes, also run: make serverpod-ops-check -->
