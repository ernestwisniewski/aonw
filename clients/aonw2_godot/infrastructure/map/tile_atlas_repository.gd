class_name AonwTileAtlasRepository
extends AonwMapTextureAssembler

const HexGridGeometry := preload("res://presentation/map/geometry/hex_grid_geometry.gd")
const MapTextureProjection := preload(
	"res://presentation/map/geometry/map_texture_projection.gd"
)
const VisualCatalog := preload(
	"res://presentation/map/terrain/terrain_visual_catalog.gd"
)
const DEFAULT_TILE_SIZE := Vector2i(160, 120)
const MAX_PREVIEW_TILE_SIZE := Vector2i(160, 120)

func load_atlas(document: AonwMapDocument, source_directory: String) -> Dictionary:
	var resolved_directory := _resolve_path(source_directory)
	var geometry := HexGridGeometry.new(document.cols(), document.rows())
	var projection := MapTextureProjection.new(geometry)
	var source_tile_size := _preview_tile_size(document, resolved_directory)
	var atlas_size := projection.target_atlas_size(source_tile_size)
	var terrain_atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGB8)
	terrain_atlas.fill(VisualCatalog.FALLBACK_COLOR)
	_fill_terrain_fallback(terrain_atlas, document, projection, atlas_size)
	var reference_atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	reference_atlas.fill(Color.TRANSPARENT)

	var missing: Array[String] = []
	var invalid: Array[String] = []
	var resized: Array[String] = []
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var file_name := "%dx%d.jpg" % [coordinate.x + 1, coordinate.y + 1]
		var image_path := resolved_directory.path_join(file_name)
		if source_directory.is_empty() or not FileAccess.file_exists(image_path):
			missing.append(file_name)
			continue
		var image := Image.load_from_file(image_path)
		if image == null or image.is_empty():
			invalid.append(file_name)
			continue
		var rect := projection.tile_slice_rect(coordinate, atlas_size)
		if rect.size.x <= 0 or rect.size.y <= 0:
			invalid.append(file_name)
			continue
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size() != rect.size:
			resized.append(file_name)
			image.resize(rect.size.x, rect.size.y, Image.INTERPOLATE_BILINEAR)
		reference_atlas.blit_rect(image, Rect2i(Vector2i.ZERO, rect.size), rect.position)

	terrain_atlas.generate_mipmaps()
	reference_atlas.generate_mipmaps()
	var terrain_texture := ImageTexture.create_from_image(terrain_atlas)
	var reference_texture := ImageTexture.create_from_image(reference_atlas)
	return {
		"ok": true,
		"texture": reference_texture,
		"terrain_texture": terrain_texture,
		"reference_texture": reference_texture,
		"missing_tiles": missing,
		"invalid_tiles": invalid,
		"resized_tiles": resized,
		"atlas_size": atlas_size,
		"source_tile_size": source_tile_size,
	}

func _preview_tile_size(document: AonwMapDocument, source_directory: String) -> Vector2i:
	if source_directory.is_empty():
		return DEFAULT_TILE_SIZE
	for tile in document.tiles():
		var path := source_directory.path_join(
			"%dx%d.jpg" % [int(tile["col"]) + 1, int(tile["row"]) + 1]
		)
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			continue
		var size := image.get_size()
		var scale := minf(
			1.0,
			minf(
				float(MAX_PREVIEW_TILE_SIZE.x) / float(size.x),
				float(MAX_PREVIEW_TILE_SIZE.y) / float(size.y),
			)
		)
		return Vector2i(
			maxi(1, roundi(float(size.x) * scale)),
			maxi(1, roundi(float(size.y) * scale)),
		)
	return DEFAULT_TILE_SIZE

func _fill_terrain_fallback(
	atlas: Image,
	document: AonwMapDocument,
	projection,
	atlas_size: Vector2i,
) -> void:
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var rect: Rect2i = projection.tile_slice_rect(coordinate, atlas_size)
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		atlas.fill_rect(rect, VisualCatalog.color_for(tile["terrains"]))

static func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path
