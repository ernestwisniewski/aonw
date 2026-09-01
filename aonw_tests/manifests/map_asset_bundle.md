# MapAssetBundleManifest

The JSON file is named `map_texture_manifest.json` and has exactly these root
fields:

`mapId`, `mapContentHash`, `gridLayout`, `cols`, `rows`, `worldWidth`,
`worldHeight`, `compiledScale`, `filterQuality`, `pageSizeLimit`, `gutter`,
`pages`, and `averageColors`.

`gridLayout` is `oddQFlatTop`. `mapContentHash` is the lowercase SHA-256
identity produced by the Rust content model. Every page has exactly `file`,
`asset`, `format`, `sha256`, `pixelWidth`, `pixelHeight`, and `destination`.
The contract supports deterministic JPEG pages; `file` is bundle-relative and
`asset` is the packaged Flutter asset key.

Unknown fields, unsafe paths, unsupported formats, mismatched map identity,
invalid dimensions, missing files, and page hash mismatches are rejected.
