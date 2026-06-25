# Asset Icon Rendering

This document describes the shared contract for rendering asset-based icons in
the game UI.

## Principle

Asset icons should not calculate their own crops, offsets, or X axes inside
usage widgets. UI widgets should use catalogs/factories:

| Asset type | Factory |
| --- | --- |
| Units | `UnitSpriteIcon` -> `SpriteAtlasIcon` |
| Cities | `CitySpriteIconCatalog.iconFor(...)` through `CitySpriteIcon` |
| Buildings | `BuildingSpriteCatalog.iconFor(...)` |
| Technologies | `TechnologySpriteCatalog.iconFor(...)` |
| Field improvements | `FieldImprovementSpriteIconCatalog.iconFor(...)` |

`SpriteAtlasIcon` is the shared renderer. By default it uses
`Alignment.center` and `BoxFit.contain`, so X comes from the center of the
prepared asset frame. If the UI needs a background instead of an icon, it can
explicitly use another `fit` and `alignment`, but the source frame should still
come from the asset catalog.

## Asset Editor

Catalogs pass `adjustmentId` to `SpriteAtlasIconData`, so offsets, crop, and
scale saved in the asset editor are applied in UI. Units map animation rows to
`UnitSpriteAction` and pass an `adjustmentFrameIndex` matching the frame column.
Cities use `CitySpriteCatalog.sourceRectFor(...)`, which means manually edited
frames from the editor rather than raw atlas cells.

Animated map units go through `UnitSpriteComponent`. The component calculates
source, destination, offset, and clip for the current frame from the same
`AnimationFrameAdjustment` values shown in the asset editor. Map layers only
set the sprite position and mirror flag; they do not add custom crops. The
frame is clipped to the authored render frame so expanded crops or scale do not
bleed outside the unit area on the map.

## Right `Action` Segment

The thumbnail for the upcoming action in the right action-list segment can act
as a background. Cities use `BoxFit.cover` and `Alignment.centerRight`, with
height equal to the button height and a small width overscan. This lets the
city cover 100% of the segment background from the right side without showing
the asset edge. The city variant also uses a less transparent mask than other
assets so the frame does not look like a cut-off, overly dark texture, but its
fade-in is slower than research thumbnails. Toolbar thumbnails end at 85% mask
visibility. Units use a separate, slower fade-in curve because their silhouettes
look better when they do not appear too abruptly at the left edge of the right
segment.

## Tests

`sprite_atlas_catalog_test.dart` verifies that unit icons go through the shared
renderer with the default centered X and asset-editor adjustment.
`sprite_asset_geometry_test.dart` verifies that animated map units use
asset-editor frame geometry and clip it to the render frame.
`game_hud_test.dart` and `hud_action_deck_test.dart` cover the right `Action`
segment thumbnail behavior, including city/research/unit thumbnail selection
and geometry.
