class_name AonwMapDocument
extends RefCounted

var _map_id: String
var _content_hash: String
var _cols: int
var _rows: int
var _default_zoom: float
var _maximum_height: int
var _objectives: Array[Dictionary]
var _tiles: Array[Dictionary]
var _tiles_by_coordinate: Dictionary

func _init(
	map_id: String,
	content_hash: String,
	cols: int,
	rows: int,
	default_zoom: float,
	objectives: Array[Dictionary],
	tiles: Array[Dictionary],
) -> void:
	_map_id = map_id
	_content_hash = content_hash
	_cols = cols
	_rows = rows
	_default_zoom = default_zoom
	_objectives = objectives
	_tiles = tiles
	_tiles_by_coordinate = {}
	_maximum_height = 0
	for tile in _tiles:
		_tiles_by_coordinate[Vector2i(tile["col"], tile["row"])] = tile
		_maximum_height = maxi(_maximum_height, int(tile["height"]))
	_tiles_by_coordinate.make_read_only()

static func from_map_view(raw: Variant) -> Dictionary:
	if not _has_exact_fields(raw, [
		"mapId", "contentHash", "gridLayout", "cols", "rows", "defaultZoom",
		"tiles", "objectives",
	]):
		return _failure("Rust map view has invalid fields")
	if (
		not raw["mapId"] is String
		or not raw["contentHash"] is String
		or raw["gridLayout"] != "oddQFlatTop"
		or not _is_integer(raw["cols"], true)
		or not _is_integer(raw["rows"], true)
		or (not raw["defaultZoom"] is int and not raw["defaultZoom"] is float)
		or not raw["objectives"] is Array
		or not raw["tiles"] is Array
	):
		return _failure("Rust map view values are invalid")

	var objectives: Array[Dictionary] = []
	for raw_objective in raw["objectives"]:
		if not _has_exact_fields(raw_objective, [
			"id", "type", "coordinate", "requiredHoldTurns", "victoryPoints", "goldPerTurn",
		]):
			return _failure("Rust map objective has invalid fields")
		var objective: Dictionary = raw_objective.duplicate(true)
		var objective_coordinate: Variant = objective["coordinate"]
		if not _is_coordinate(objective_coordinate):
			return _failure("Rust map objective coordinate is invalid")
		objective_coordinate.make_read_only()
		objective.make_read_only()
		objectives.append(objective)
	objectives.make_read_only()

	var tiles: Array[Dictionary] = []
	for raw_tile in raw["tiles"]:
		if not _has_exact_fields(raw_tile, [
			"coordinate", "displayTerrain", "yieldTerrain", "movementTerrains",
			"terrainTags", "resources", "height",
		]):
			return _failure("Rust map tile has invalid fields")
		var coordinate: Variant = raw_tile["coordinate"]
		if not _is_coordinate(coordinate):
			return _failure("Rust map tile coordinate is invalid")
		if (
			not raw_tile["movementTerrains"] is Array
			or not raw_tile["terrainTags"] is Array
			or not raw_tile["resources"] is Array
			or not _is_integer(raw_tile["height"], true)
		):
			return _failure("Rust map tile values are invalid")
		var terrains: Array = raw_tile["movementTerrains"].duplicate()
		var terrain_tags: Array = raw_tile["terrainTags"].duplicate()
		var resources: Array = raw_tile["resources"].duplicate()
		terrains.make_read_only()
		terrain_tags.make_read_only()
		resources.make_read_only()
		var tile := {
			"col": coordinate["col"],
			"row": coordinate["row"],
			"terrains": terrains,
			"displayTerrain": raw_tile["displayTerrain"],
			"yieldTerrain": raw_tile["yieldTerrain"],
			"terrainTags": terrain_tags,
			"resources": resources,
			"height": raw_tile["height"],
		}
		tile.make_read_only()
		tiles.append(tile)
	tiles.make_read_only()

	return {
		"ok": true,
		"value": AonwMapDocument.new(
			raw["mapId"],
			raw["contentHash"],
			int(raw["cols"]),
			int(raw["rows"]),
			float(raw["defaultZoom"]),
			objectives,
			tiles,
		),
	}

func map_id() -> String:
	return _map_id

func map_name() -> String:
	return _map_id

func content_hash() -> String:
	return _content_hash

func cols() -> int:
	return _cols

func rows() -> int:
	return _rows

func default_zoom() -> float:
	return _default_zoom

func maximum_height() -> int:
	return _maximum_height

func objectives() -> Array[Dictionary]:
	return _objectives

func tiles() -> Array[Dictionary]:
	return _tiles

func tile_at(coordinate: Vector2i) -> Dictionary:
	return _tiles_by_coordinate.get(coordinate, {})

static func _is_coordinate(raw: Variant) -> bool:
	return (
		_has_exact_fields(raw, ["col", "row"])
		and _is_integer(raw["col"], false)
		and _is_integer(raw["row"], false)
	)

static func _is_integer(raw: Variant, non_negative: bool) -> bool:
	if not raw is int and not raw is float:
		return false
	var integer := int(raw)
	return float(integer) == float(raw) and (not non_negative or integer >= 0)

static func _has_exact_fields(raw: Variant, fields: Array) -> bool:
	if not raw is Dictionary or raw.size() != fields.size():
		return false
	for field in fields:
		if not raw.has(field):
			return false
	return true

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
