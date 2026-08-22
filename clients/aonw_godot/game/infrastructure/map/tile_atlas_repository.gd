class_name AonwTileAtlasRepository
extends AonwMapTextureAssembler

const HexGridGeometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const MapTextureProjection := preload(
	"res://game/presentation/map/geometry/map_texture_projection.gd"
)
const MANIFEST_NAME := "map_texture_manifest.json"
const MAP_HEX_RADIUS := 60.0
const MAX_ATLAS_SIZE := 16_384
const TERRAIN_COLORS := {
	"ocean": Color("245b91"),
	"coast": Color("4f9dc4"),
	"lake": Color("3f87b3"),
	"plains": Color("b7a66a"),
	"grassland": Color("6e9c54"),
	"desert": Color("c5a15f"),
	"tundra": Color("89938a"),
	"snow": Color("d9e2e3"),
	"mountain": Color("666b6f"),
	"hills": Color("8a7957"),
	"wetlands": Color("537a68"),
	"jungle": Color("356a43"),
	"forest": Color("3e7148"),
	"river": Color("3e83ad"),
}

func load_atlas(document: AonwMapDocument, source_directory: String) -> Dictionary:
	var geometry := HexGridGeometry.new(document.cols(), document.rows())
	var projection := MapTextureProjection.new(geometry)
	var reference := _load_reference_atlas(
		document,
		_resolve_path(source_directory),
	)
	if not reference["ok"]:
		return reference

	var atlas_size: Vector2i = reference["atlas_size"]
	var terrain_atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGB8)
	terrain_atlas.fill(Color("6c7178"))
	_fill_terrain_fallback(terrain_atlas, document, projection, atlas_size)
	terrain_atlas.generate_mipmaps()

	var reference_atlas: Image = reference["image"]
	reference_atlas.generate_mipmaps()
	var reference_texture := ImageTexture.create_from_image(reference_atlas)
	return {
		"ok": true,
		"texture": reference_texture,
		"terrain_texture": ImageTexture.create_from_image(terrain_atlas),
		"reference_texture": reference_texture,
		"missing_tiles": reference["missing_pages"],
		"invalid_tiles": reference["invalid_pages"],
		"resized_tiles": [],
		"atlas_size": atlas_size,
		"source_tile_size": reference["source_tile_size"],
	}

func _load_reference_atlas(
	document: AonwMapDocument,
	source_directory: String,
) -> Dictionary:
	var manifest_path := source_directory.path_join(MANIFEST_NAME)
	if source_directory.is_empty() or not FileAccess.file_exists(manifest_path):
		return _failure("map asset bundle is required: %s" % manifest_path)

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		return _failure("cannot open map texture manifest: %s" % manifest_path)
	var manifest: Variant = JSON.parse_string(manifest_file.get_as_text())
	var error := _manifest_error(manifest, document)
	if not error.is_empty():
		return _failure("invalid map texture manifest: %s" % error)

	var scale := float(manifest["compiledScale"])
	var atlas_size := Vector2i(
		ceili(float(manifest["worldWidth"]) * scale),
		ceili(float(manifest["worldHeight"]) * scale),
	)
	var atlas := Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for page in manifest["pages"]:
		var asset := str(page["asset"])
		var page_path := source_directory.path_join(str(page["file"]))
		if not FileAccess.file_exists(page_path):
			return _failure("missing map asset bundle page: %s" % asset)
		if FileAccess.get_sha256(page_path) != str(page["sha256"]):
			return _failure("map asset bundle page hash does not match: %s" % asset)
		var image := Image.load_from_file(page_path)
		if (
			image == null
			or image.is_empty()
			or image.get_width() != int(page["pixelWidth"])
			or image.get_height() != int(page["pixelHeight"])
		):
			return _failure("map asset bundle page is invalid: %s" % asset)
		image.convert(Image.FORMAT_RGBA8)
		if not _blit_page(atlas, image, page["destination"], scale):
			return _failure("map asset bundle page is outside the atlas: %s" % asset)

	return {
		"ok": true,
		"image": atlas,
		"atlas_size": atlas_size,
		"source_tile_size": Vector2i(
			ceili(MAP_HEX_RADIUS * 2.0 * scale),
			ceili(HexGridGeometry.SQRT_3 * MAP_HEX_RADIUS * scale),
		),
		"missing_pages": [],
		"invalid_pages": [],
	}

func _manifest_error(
	value: Variant,
	document: AonwMapDocument,
) -> String:
	if value is not Dictionary:
		return "root must be an object"
	var manifest: Dictionary = value
	if not _has_exact_fields(manifest, [
		"version", "mapId", "mapContentHash", "gridLayout", "cols", "rows",
		"worldWidth", "worldHeight", "compiledScale", "filterQuality",
		"pageSizeLimit", "gutter", "pages", "averageColors",
	]):
		return "fields do not match MapAssetBundleManifest v1"
	if manifest.get("version") != 1:
		return "unsupported version"
	if manifest.get("mapId") != document.map_id():
		return "map identity does not match"
	if manifest.get("mapContentHash") != document.content_hash():
		return "map content hash does not match"
	if manifest.get("gridLayout") != "oddQFlatTop":
		return "grid layout does not match"
	if manifest.get("cols") != document.cols() or manifest.get("rows") != document.rows():
		return "map dimensions do not match"
	for field in ["worldWidth", "worldHeight", "compiledScale"]:
		if not _is_positive_number(manifest.get(field)):
			return "%s must be a positive number" % field
	var scale := float(manifest["compiledScale"])
	if (
		ceili(float(manifest["worldWidth"]) * scale) > MAX_ATLAS_SIZE
		or ceili(float(manifest["worldHeight"]) * scale) > MAX_ATLAS_SIZE
	):
		return "atlas exceeds the supported size"
	var pages: Variant = manifest.get("pages")
	if pages is not Array or pages.is_empty():
		return "pages must be a non-empty array"
	var expected_prefix := "assets/runtime/maps/%s/" % document.map_id()
	var seen := {}
	for page_value in pages:
		if page_value is not Dictionary:
			return "page must be an object"
		var page: Dictionary = page_value
		if not _has_exact_fields(page, [
			"file", "asset", "format", "sha256", "pixelWidth", "pixelHeight",
			"destination",
		]):
			return "page fields do not match MapAssetBundleManifest v1"
		var asset: Variant = page.get("asset")
		var page_name: Variant = page.get("file")
		if asset is not String or page_name is not String:
			return "page paths must be strings"
		if (
			str(page_name).get_file() != page_name
			or not _is_page_file(str(page_name))
			or str(asset) != expected_prefix + str(page_name)
		):
			return "page asset is outside the map runtime directory"
		if seen.has(page_name):
			return "page asset is duplicated"
		seen[page_name] = true
		if page.get("format") != "jpeg":
			return "%s has an unsupported format" % page_name
		if not _is_sha256(page.get("sha256")):
			return "%s has an invalid SHA-256" % page_name
		if not _is_positive_integer(page.get("pixelWidth")):
			return "%s has an invalid width" % page_name
		if not _is_positive_integer(page.get("pixelHeight")):
			return "%s has an invalid height" % page_name
		var destination: Variant = page.get("destination")
		if destination is not Array or destination.size() != 4:
			return "%s has an invalid destination" % page_name
		if not destination.all(_is_number):
			return "%s has a non-numeric destination" % page_name
		if float(destination[2]) <= 0.0 or float(destination[3]) <= 0.0:
			return "%s has an invalid destination size" % page_name
		if (
			absf(float(destination[2]) * scale - float(page["pixelWidth"])) > 0.01
			or absf(float(destination[3]) * scale - float(page["pixelHeight"])) > 0.01
		):
			return "%s destination does not match its pixel size" % page_name
	return ""

func _blit_page(atlas: Image, page: Image, destination: Array, scale: float) -> bool:
	var target := Vector2i(
		roundi(float(destination[0]) * scale),
		roundi(float(destination[1]) * scale),
	)
	var source := Vector2i.ZERO
	if target.x < 0:
		source.x = -target.x
		target.x = 0
	if target.y < 0:
		source.y = -target.y
		target.y = 0
	var size := Vector2i(
		mini(page.get_width() - source.x, atlas.get_width() - target.x),
		mini(page.get_height() - source.y, atlas.get_height() - target.y),
	)
	if size.x <= 0 or size.y <= 0:
		return false
	atlas.blit_rect(page, Rect2i(source, size), target)
	return true

func _fill_terrain_fallback(
	atlas: Image,
	document: AonwMapDocument,
	projection,
	atlas_size: Vector2i,
) -> void:
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var rect: Rect2i = projection.tile_slice_rect(coordinate, atlas_size)
		if rect.size.x > 0 and rect.size.y > 0:
			atlas.fill_rect(rect, _terrain_color(tile))

func _terrain_color(tile: Dictionary) -> Color:
	return TERRAIN_COLORS.get(str(tile["displayTerrain"]), Color("6c7178"))

static func _is_positive_number(value: Variant) -> bool:
	return _is_number(value) and float(value) > 0.0

static func _is_positive_integer(value: Variant) -> bool:
	return (
		_is_number(value)
		and float(value) > 0.0
		and float(value) <= MAX_ATLAS_SIZE
		and float(value) == floorf(float(value))
	)

static func _is_number(value: Variant) -> bool:
	return (
		typeof(value) in [TYPE_INT, TYPE_FLOAT]
		and absf(float(value)) <= 1_000_000.0
	)

static func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)

static func _is_page_file(value: String) -> bool:
	if not value.begins_with("page_") or not value.ends_with(".jpg"):
		return false
	var index := value.trim_prefix("page_").trim_suffix(".jpg")
	return not index.is_empty() and not index.begins_with("-") and index.is_valid_int()

static func _has_exact_fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

static func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path
