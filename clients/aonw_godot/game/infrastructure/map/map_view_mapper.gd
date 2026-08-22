class_name AonwMapViewMapper
extends RefCounted

const MapView := preload("res://game/application/map/read_model/map_view.gd")
const MapTileView := preload("res://game/application/map/read_model/map_tile_view.gd")
const MapObjectiveView := preload(
	"res://game/application/map/read_model/map_objective_view.gd"
)

func from_wire(raw: Variant) -> Dictionary:
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
		or int(raw["cols"]) == 0
		or not _is_integer(raw["rows"], true)
		or int(raw["rows"]) == 0
		or not _is_positive_number(raw["defaultZoom"])
		or not raw["objectives"] is Array
		or not raw["tiles"] is Array
	):
		return _failure("Rust map view values are invalid")

	var objectives: Array[AonwMapObjectiveView] = []
	for raw_objective in raw["objectives"]:
		var objective_result := _objective(raw_objective)
		if not objective_result["ok"]:
			return objective_result
		objectives.append(objective_result["value"])

	var tiles: Array[AonwMapTileView] = []
	for raw_tile in raw["tiles"]:
		var tile_result := _tile(raw_tile)
		if not tile_result["ok"]:
			return tile_result
		tiles.append(tile_result["value"])

	return {
		"ok": true,
		"value": MapView.new(
			StringName(raw["mapId"]),
			raw["contentHash"],
			StringName(raw["gridLayout"]),
			int(raw["cols"]),
			int(raw["rows"]),
			float(raw["defaultZoom"]),
			objectives,
			tiles,
		),
	}

func _objective(raw: Variant) -> Dictionary:
	if not _has_exact_fields(raw, [
		"id", "type", "coordinate", "requiredHoldTurns", "victoryPoints", "goldPerTurn",
	]):
		return _failure("Rust map objective has invalid fields")
	if (
		not raw["id"] is String
		or not raw["type"] is String
		or not _is_coordinate(raw["coordinate"])
		or not _is_integer(raw["requiredHoldTurns"], true)
		or not _is_integer(raw["victoryPoints"], true)
		or not _is_integer(raw["goldPerTurn"], true)
	):
		return _failure("Rust map objective values are invalid")
	return {
		"ok": true,
		"value": MapObjectiveView.new(
			StringName(raw["id"]),
			StringName(raw["type"]),
			_coordinate(raw["coordinate"]),
			int(raw["requiredHoldTurns"]),
			int(raw["victoryPoints"]),
			int(raw["goldPerTurn"]),
		),
	}

func _tile(raw: Variant) -> Dictionary:
	if not _has_exact_fields(raw, [
		"coordinate", "displayTerrain", "yieldTerrain", "movementTerrains",
		"terrainTags", "resources", "height",
	]):
		return _failure("Rust map tile has invalid fields")
	if (
		not _is_coordinate(raw["coordinate"])
		or not raw["displayTerrain"] is String
		or not raw["yieldTerrain"] is String
		or not raw["movementTerrains"] is Array
		or not raw["terrainTags"] is Array
		or not raw["resources"] is Array
		or not _is_integer(raw["height"], true)
	):
		return _failure("Rust map tile values are invalid")
	var movement_terrains := _names(raw["movementTerrains"])
	var terrain_tags := _names(raw["terrainTags"])
	var resources := _names(raw["resources"])
	for result in [movement_terrains, terrain_tags, resources]:
		if not result["ok"]:
			return _failure("Rust map tile collections are invalid")
	return {
		"ok": true,
		"value": MapTileView.new(
			_coordinate(raw["coordinate"]),
			StringName(raw["displayTerrain"]),
			StringName(raw["yieldTerrain"]),
			movement_terrains["value"],
			terrain_tags["value"],
			resources["value"],
			int(raw["height"]),
		),
	}

func _names(raw: Array) -> Dictionary:
	var result: Array[StringName] = []
	for value in raw:
		if not value is String:
			return _failure("expected a string collection")
		result.append(StringName(value))
	return {"ok": true, "value": result}

func _is_coordinate(raw: Variant) -> bool:
	return (
		_has_exact_fields(raw, ["col", "row"])
		and _is_integer(raw["col"], true)
		and _is_integer(raw["row"], true)
	)

func _coordinate(raw: Dictionary) -> Vector2i:
	return Vector2i(int(raw["col"]), int(raw["row"]))

func _is_positive_number(raw: Variant) -> bool:
	return (raw is int or raw is float) and float(raw) > 0.0 and is_finite(float(raw))

func _is_integer(raw: Variant, non_negative: bool) -> bool:
	if not raw is int and not raw is float:
		return false
	var integer := int(raw)
	return float(integer) == float(raw) and (not non_negative or integer >= 0)

func _has_exact_fields(raw: Variant, fields: Array) -> bool:
	if not raw is Dictionary or raw.size() != fields.size():
		return false
	for field in fields:
		if not raw.has(field):
			return false
	return true

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
