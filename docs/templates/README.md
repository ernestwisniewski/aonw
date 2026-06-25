# Asset Templates

This directory contains SVG templates for new game assets. The SVGs can be
opened in Figma, Photoshop, Illustrator, Affinity, or Krita as reference layers.
The final export should be PNG or WebP with alpha. Do not use JPG for sprites
with transparency.

Most important rule: the asset should be correct at export time. Runtime code
should not need to move, crop, or scale individual frames.

## Files

| Template | Target asset | Grid | Cell | Atlas size | Usage |
| --- | --- | ---: | ---: | ---: | --- |
| `unit_sheet_6x4_512x768.svg` | `assets/sprites/units/<unit>.png` | 6 x 4 | 512 x 768 | 3072 x 3072 | Animated units |
| `buildings_atlas_a_5x4_512.svg` | `assets/sprites/buildings_atlas_a_5x4_512.png` + `.webp` | 5 x 4 | 512 x 512 | 2560 x 2048 | Buildings 00-19 |
| `buildings_atlas_b_5x4_512.svg` | `assets/sprites/buildings_atlas_b_5x4_512.png` + `.webp` | 5 x 4 | 512 x 512 | 2560 x 2048 | Buildings 20-39 |
| `buildings_atlas_c_5x4_512.svg` | `assets/sprites/buildings_atlas_c_5x4_512.png` + `.webp` | 5 x 4 | 512 x 512 | 2560 x 2048 | Buildings 40-58, slot 59 empty |
| `technologies_atlas_8x7_512.svg` | `assets/sprites/technologies_atlas_8x7_512.png` + `.webp` | 8 x 7 | 512 x 512 | 4096 x 3584 | Technologies 00-54 |
| `cities_atlas_6x4_512x320.svg` | `assets/sprites/cities_atlas_6x4_512x320.jpg` | 6 x 4 | 512 x 320 | 3072 x 1280 | Map cities |
| `field_improvements_atlas_a_4x10_512x288.svg` | Runtime atlas family `assets/sprites/improvements1.jpg` ... `improvements4.jpg` | 4 x 10 | 512 x 288 | 2048 x 2880 | Improvements 00-09 |
| `field_improvements_atlas_b_4x9_512x288.svg` | Runtime atlas family `assets/sprites/improvements1.jpg` ... `improvements4.jpg` | 4 x 9 | 512 x 288 | 2048 x 2592 | Improvements 10-18 |
| `ui_icons_atlas_10x10_256.svg` | `assets/sprites/ui_icons.png` | 10 x 10 | 256 x 256 | 2560 x 2560 | Future UI icon atlas |

## How To Read The Grid

- Navy background: transparent cell area.
- Blue frame: cell boundary. Art must not leave this area.
- Yellow rectangle: safe zone. Keep the primary object inside this area.
- Pink vertical line: center / pivot X.
- Turquoise horizontal line: baseline / pivot Y for map objects and units.

## Units

Each unit type has its own spritesheet:

```text
row 0: idle
row 1: walk
row 2: attack or work
row 3: die
columns: 6 frames
```

All frames for the same unit must use the same pivot. Do not crop each frame
individually. If the character stands in place, its feet, wheels, or hull should
hit the same baseline in every frame.

## Buildings

Buildings are split into three atlases of 20 slots so each cell can stay at
512 px without creating one very large texture. Slots follow `CityBuildingType`,
left-to-right and top-to-bottom:

- atlas A: indexes 00-19
- atlas B: indexes 20-39
- atlas C: indexes 40-58, slot 59 remains empty

For runtime, keep PNG as a fallback and generate lossless WebP with the same
base name:

```text
cwebp -lossless -z 9 buildings_atlas_a_5x4_512.png -o buildings_atlas_a_5x4_512.webp
```

The code tries to load WebP first. If a build/environment cannot decode it, it
automatically falls back to PNG.

## Technologies

Technologies follow the target technology catalog order, left-to-right and
top-to-bottom. The atlas has 56 slots; the final slot remains empty.

Keep PNG and lossless WebP exports with the same base name so the runtime can
prefer WebP and fall back to PNG.

## Cities

Columns are city visual level `0..5`, rows are technology profile:

```text
row 0: growth / civic
row 1: trade / knowledge / maritime
row 2: military / fortified
row 3: industry / modern
```

## Field Improvements

Columns are era:

```text
col 0: early
col 1: developed
col 2: industrial
col 3: modern
```

Rows follow the target type list. Sheet A contains types 00-09; sheet B
contains types 10-18. The current runtime splits field-improvement art across
the `improvements1.jpg` through `improvements4.jpg` atlas family, so update the
runtime catalog if you change the export layout.

## Export

- Export as PNG or WebP with alpha.
- Do not resize the file after export.
- Leave empty slots fully transparent.
- Do not add shadows that leave the cell.
- If an element touches the safe-zone edge, leave at least 2 px from the cell
  boundary.
- For animations, do not move the object between frames unless that is the
  actual animation movement.
