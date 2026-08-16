# Asset templates

The SVG files in this directory define atlas grids, safe areas, pivots, and export sizes for game art. Open them as reference layers in a graphics editor; the game does not load the SVGs.

The important rule is simple: align and crop art correctly before export. Runtime widgets should not need frame-specific fixes beyond the shared asset-editor adjustment data.

## Templates

| File | Runtime target | Layout |
| --- | --- | --- |
| `unit_sheet_6x4_512x768.svg` | `assets/sprites/units/<unit>.png/.webp` | 6 columns × 4 animation rows |
| `buildings_atlas_*_5x4_512.svg` | building atlas A/B/C | 20 slots per atlas |
| `technologies_atlas_8x7_512.svg` | technology atlas | 56 slots |
| `cities_atlas_6x4_512x320.svg` | city atlas | 6 levels × 4 profiles |
| `field_improvements_atlas_*.svg` | improvement atlas family | era columns and type rows |
| `ui_icons_atlas_10x10_256.svg` | UI icon atlas | 100 slots |

## Grid marks

- blue: cell boundary;
- yellow: safe zone;
- pink: horizontal pivot/center;
- turquoise: baseline.

Keep the primary object inside the safe zone and use one stable pivot across every frame of an animation.

## Unit rows

```text
0 idle
1 walk
2 attack or work
3 die
```

Do not crop frames independently or move the feet, wheels, or hull unless the animation actually moves them.

## Export

- Export sprites as PNG or lossless WebP with alpha. Do not use JPG where transparency is required.
- Keep the template dimensions; do not resize after export.
- Leave unused cells transparent.
- Keep shadows and effects inside the cell.
- Preserve PNG fallback files where runtime loading prefers WebP first.
- Regenerate or update the matching runtime catalog when an atlas layout changes.

Example lossless conversion:

```sh
cwebp -lossless -m 6 -mt warrior.png -o warrior.webp
```

Use the in-app Assets Editor for small shared adjustment data, not as a substitute for badly aligned source art.
