## Summary

<!-- What does this change do, and why? -->

## Related issues

<!-- e.g. Closes #123 -->

## Checklist

- [ ] `make ci` passes (format, Flutter app, `aonw_core`, generated client, server unit tests).
- [ ] Generated files (`*.g.dart`, `*.freezed.dart`, localization, Serverpod protocol) are in sync with their sources.
- [ ] Docs updated when behavior, persistence, APIs, game rules, or build/deploy flows changed.
- [ ] Architecture boundaries and accepted ADRs respected (see `test/architecture/layer_boundaries_test.dart` and `docs/adr/README.md`).

<!-- For Serverpod schema, migration, Compose, or deploy changes, also run: make serverpod-ops-check -->
