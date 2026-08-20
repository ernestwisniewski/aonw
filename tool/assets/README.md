# Runtime asset pipeline

Final game-ready images live only under `assets/runtime/`. Large editable
masters live in the external
[`aonw-assets`](https://github.com/ernestwisniewski/aonw-assets) repository,
pinned by `asset_source_manifest.json` to commit
`00b572f5137feb38d68b50684001ee24383a8369`. The application repository must
not contain a `game_assets/` tree or raw `assets/maps`, `assets/icons`, or
`assets/sprites` masters.

The pipeline requires `cwebp` and `dwebp` 1.6.0. Point
`AONW_ASSET_MASTERS` at the pinned external checkout, or pass
`--source-root PATH`. There is deliberately no fallback to the application
repository.

Commands:

- `make assets-compile` builds into a sibling staging directory, verifies it,
  and atomically replaces `assets/runtime`.
- `make assets-verify` runs source-free runtime verification. It checks the
  exact manifest allowlist, hashes, formats, semantic frame IDs, bundle budget,
  repository layout, preserved `assets/aonw2-logo.png`, and duplicate bytes.
  It also rejects the obsolete root-level `android/mipmap-*` export; Android
  launcher icons live only under `android/app/src/main/res/mipmap-*`.
- `make assets-check` regenerates into a temporary directory from the pinned
  masters and compares every byte with committed `assets/runtime`.
- `make assets-reproduce` performs the same explicit reproducibility audit for
  release or maintenance work.

`--output-root PATH` denotes an alternate application workspace; generated
files still land at `PATH/assets/runtime`. Canonical logical maps remain in
`content/maps` and are never copied into generated output. The semantic
animation-adjustment authoring file lives in `tool/assets/authoring`; its
validated final copy is generated under `assets/runtime/metadata`.
