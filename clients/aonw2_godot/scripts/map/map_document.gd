@tool
class_name AonwMapDocument
extends RefCounted

const SCHEMA_VERSION := 1
const GRID_LAYOUT := "oddQFlatTop"
const MIN_COLS := 5
const MAX_COLS := 40
const MIN_ROWS := 5
const MAX_ROWS := 30
const MAX_HEIGHT := 5
const TERRAIN_NAMES := [
	"ocean", "coast", "lake", "plains", "grassland", "desert", "tundra",
	"snow", "mountain", "hills", "wetlands", "jungle", "forest", "river",
]

static func load_map(source_path: String) -> Dictionary:
	var path := resolve_path(source_path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open AoNW map: %s" % path)
		return {}

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error("Invalid AoNW map JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return {}
	if not parser.data is Dictionary:
		push_error("AoNW map root must be an object")
		return {}

	var document: Dictionary = parser.data
	var validation_error := _validate(document)
	if not validation_error.is_empty():
		push_error("Invalid AoNW map: %s" % validation_error)
		return {}
	return document

static func resolve_path(source_path: String) -> String:
	if source_path.begins_with("res://") or source_path.begins_with("user://"):
		return ProjectSettings.globalize_path(source_path)
	return source_path

static func _validate(document: Dictionary) -> String:
	for field in ["schemaVersion", "gridLayout", "cols", "rows", "mapName", "tiles"]:
		if not document.has(field):
			return "missing field %s" % field
	if document["schemaVersion"] != SCHEMA_VERSION:
		return "unsupported schemaVersion"
	if document["gridLayout"] != GRID_LAYOUT:
		return "gridLayout must be %s" % GRID_LAYOUT
	if not _is_integer(document["cols"]) or not _is_integer(document["rows"]):
		return "cols and rows must be integers"

	var cols := int(document["cols"])
	var rows := int(document["rows"])
	if cols < MIN_COLS or cols > MAX_COLS or rows < MIN_ROWS or rows > MAX_ROWS:
		return "dimensions exceed schema limits"
	if not document["tiles"] is Array:
		return "tiles must be an array"

	var tiles: Array = document["tiles"]
	if tiles.size() != cols * rows:
		return "tiles must cover the complete grid"
	var coordinates := {}
	for index in tiles.size():
		var tile: Variant = tiles[index]
		if not tile is Dictionary:
			return "tiles[%d] must be an object" % index
		var tile_error := _validate_tile(tile, index, cols, rows, coordinates)
		if not tile_error.is_empty():
			return tile_error
	return ""

static func _validate_tile(
	tile: Dictionary,
	index: int,
	cols: int,
	rows: int,
	coordinates: Dictionary,
) -> String:
	for field in ["col", "row", "terrains", "resources", "height"]:
		if not tile.has(field):
			return "tiles[%d] is missing %s" % [index, field]
	if not _is_integer(tile["col"]) or not _is_integer(tile["row"]) or not _is_integer(tile["height"]):
		return "tiles[%d] coordinates and height must be integers" % index

	var col := int(tile["col"])
	var row := int(tile["row"])
	var height := int(tile["height"])
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return "tiles[%d] is outside map bounds" % index
	if height < 0 or height > MAX_HEIGHT:
		return "tiles[%d].height is outside 0..%d" % [index, MAX_HEIGHT]

	var key := "%d:%d" % [col, row]
	if coordinates.has(key):
		return "duplicate tile at %s" % key
	coordinates[key] = true

	if not tile["terrains"] is Array or tile["terrains"].is_empty():
		return "tiles[%d].terrains must be a non-empty array" % index
	if not tile["resources"] is Array:
		return "tiles[%d].resources must be an array" % index
	for terrain in tile["terrains"]:
		if not terrain is String or not TERRAIN_NAMES.has(terrain):
			return "tiles[%d] contains unknown terrain" % index
	return ""

static func _is_integer(value: Variant) -> bool:
	return (value is int) or (value is float and value == floorf(value))
