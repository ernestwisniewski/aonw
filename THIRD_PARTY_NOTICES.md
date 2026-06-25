# Third-Party Notices

This project depends on open-source Dart, Flutter, Flame, Serverpod, and related
packages. Dependency names and versions are recorded in `pubspec.yaml`,
`pubspec.lock`, package-level `pubspec.yaml` files, and package-level lockfiles.
Each dependency remains under its upstream license.

## Fonts

- Cinzel font files under `assets/fonts/`.
- Lato font files under `assets/fonts/`.

These font families are distributed by their upstream authors under open font
licenses. Keep upstream license notices with redistributed font files when
publishing packaged assets.

## Game Assets

Game art, map images, icons, sprites, sound effects, music, marketing images,
and store collateral in this repository are included with permission for this
project. Do not assume they are available for reuse outside this project unless
their source license says so.

## Platform Assets

Platform launcher icons, web icons, and generated platform scaffolding are kept
in the relevant platform folders and `docs/marketing/`. Platform vendor files
remain subject to their upstream licenses and terms.

## Vendored Package Patches

- `third_party/sign_in_with_apple/` vendors `sign_in_with_apple` 7.0.1 under
  its upstream MIT license. The local patch adds current Swift SDK authorization
  error cases while preserving the 7.x Dart API required by
  `serverpod_auth_idp_flutter` 3.4.10.
