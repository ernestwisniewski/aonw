class_name AonwTileAtlasRepository
extends RefCounted

const HexGridGeometry := preload("res://domain/map/hex_grid_geometry.gd")
const SOURCE_TILE_SIZE := Vector2i(160, 120)
const MISSING_TILE_COLOR := Color("6c7178")

func load_atlas(document: AonwMapDocument, source_directory: String) -> Dictionary:
	var geometry := HexGridGeometry.new(document.cols(), document.rows())
	var atlas_size := geometry.target_atlas_size(SOURCE_TILE_SIZE)
	var atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGB8)
	atlas.fill(MISSING_TILE_COLOR)

	var missing: Array[String] = []
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var file_name := "%dx%d.jpg" % [coordinate.x + 1, coordinate.y + 1]
		var image_path := source_directory.path_join(file_name)
		if not FileAccess.file_exists(image_path):
			missing.append(file_name)
			continue
		var image := Image.load_from_file(image_path)
		if image == null or image.is_empty():
			missing.append(file_name)
			continue
		var rect := geometry.tile_slice_rect(coordinate, atlas_size)
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		image.convert(Image.FORMAT_RGB8)
		if image.get_size() != rect.size:
			image.resize(rect.size.x, rect.size.y, Image.INTERPOLATE_BILINEAR)
		atlas.blit_rect(image, Rect2i(Vector2i.ZERO, rect.size), rect.position)

	atlas.generate_mipmaps()
	return {
		"ok": true,
		"texture": ImageTexture.create_from_image(atlas),
		"missing_tiles": missing,
		"atlas_size": atlas_size,
	}
