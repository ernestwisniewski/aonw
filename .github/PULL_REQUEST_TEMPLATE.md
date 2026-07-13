## Summary

<!-- What does this change do, and why? -->

## Related issues

<!-- e.g. Closes #123 -->

## Checklist

- [ ] `make bootstrap` succeeds without changing committed lockfiles.
- [ ] `make analyze` passes with the shared fatal policy for all four packages.
- [ ] `make ci` passes (generated-code drift, format, Flutter app, `aonw_core`, generated client, server unit tests).
- [ ] Generator input changes were regenerated deliberately and the resulting build-runner, localization, Serverpod, and migration diffs were reviewed (`make generated-code-check`).
- [ ] Docs updated when behavior, persistence, APIs, game rules, or build/deploy flows changed.
- [ ] Architecture boundaries and accepted ADRs respected (see `test/architecture/layer_boundaries_test.dart` and `docs/adr/README.md`).

<!-- For Serverpod schema, migration, Compose, or deploy changes, also run: make serverpod-ops-check -->
