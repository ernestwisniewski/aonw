# MapAssetBundleManifest v1

The JSON file is named `map_texture_manifest.json` during the legacy-client
transition. Version 1 has exactly these root fields:

`version`, `mapId`, `mapContentHash`, `gridLayout`, `cols`, `rows`,
`worldWidth`, `worldHeight`, `compiledScale`, `filterQuality`,
`pageSizeLimit`, `gutter`, `pages`, and `averageColors`.

`gridLayout` is `oddQFlatTop`. `mapContentHash` is the lowercase SHA-256
identity produced by the Rust content model. Every page has exactly `file`,
`asset`, `format`, `sha256`, `pixelWidth`, `pixelHeight`, and `destination`.
Version 1 supports deterministic JPEG pages; `file` is bundle-relative and
`asset` keeps the current root Flutter asset key compatible during migration.

Unknown fields, unsafe paths, unsupported formats, mismatched map identity,
invalid dimensions, missing files, and page hash mismatches are rejected.
