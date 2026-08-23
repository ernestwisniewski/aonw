@tool
class_name AonwFilesystemLogicalMapEditor
extends AonwLogicalMapEditor

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const TerrainCompiler := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_compiler.gd"
)

var _workbench: AonwLogicalMapWorkbench
var _atomic_store := AtomicResourceStore.new()
var _compiler := TerrainCompiler.new()

func _init(workbench: AonwLogicalMapWorkbench) -> void:
	assert(workbench != null, "Logical map workbench is required")
	_workbench = workbench

func inspect_tile(source: AonwMapSource, coordinate: Vector2i) -> Dictionary:
	var map_result := _read_text(source.map_path)
	if not map_result["ok"]:
		return map_result
	return _workbench.inspect_map_tile(map_result["content"], coordinate)

func set_tile_terrain(
	source: AonwMapSource,
	coordinate: Vector2i,
	terrain: StringName,
) -> Dictionary:
	var documents := _documents(source)
	if not documents["ok"]:
		return documents
	return _persist_update(source, documents, _workbench.set_tile_terrain(
		documents["map"],
		documents["profile"],
		coordinate,
		terrain,
	))

func set_tile_resources(
	source: AonwMapSource,
	coordinate: Vector2i,
	resources: Array[StringName],
) -> Dictionary:
	var documents := _documents(source)
	if not documents["ok"]:
		return documents
	return _persist_update(source, documents, _workbench.set_tile_resources(
		documents["map"],
		documents["profile"],
		coordinate,
		resources,
	))

func set_tile_height(
	source: AonwMapSource,
	coordinate: Vector2i,
	height: int,
) -> Dictionary:
	var documents := _documents(source)
	if not documents["ok"]:
		return documents
	return _persist_update(source, documents, _workbench.set_tile_height(
		documents["map"],
		documents["profile"],
		coordinate,
		height,
	))

func _documents(source: AonwMapSource) -> Dictionary:
	if source.origin != "content":
		return _failure("only canonical content maps can be edited")
	var map_result := _read_text(source.map_path)
	if not map_result["ok"]:
		return map_result
	var profile_path := _profile_path(source)
	var profile_result := _read_text(profile_path)
	if not profile_result["ok"]:
		return profile_result
	return {
		"ok": true,
		"map": map_result["content"],
		"profile": profile_result["content"],
		"profile_path": profile_path,
	}

func _persist_update(
	source: AonwMapSource,
	documents: Dictionary,
	result: Dictionary,
) -> Dictionary:
	if not result["ok"]:
		return result
	var update: Dictionary = result["update"]
	var map_error := _atomic_store.write_text(source.map_path, update["mapDocument"])
	if map_error != OK:
		return _failure("cannot save logical map: %s" % error_string(map_error))
	var profile_error := _atomic_store.write_text(
		documents["profile_path"],
		update["terrainAuthoringDocument"],
	)
	if profile_error != OK:
		var map_rollback := _atomic_store.write_text(source.map_path, documents["map"])
		return _failure(_rollback_message(
			"cannot save terrain authoring profile: %s" % error_string(profile_error),
			map_rollback,
		))
	var compiled := _compiler.compile_profiles()
	if compiled["ok"]:
		return {"ok": true, "update": update}
	var map_rollback := _atomic_store.write_text(source.map_path, documents["map"])
	var profile_rollback := _atomic_store.write_text(
		documents["profile_path"],
		documents["profile"],
	)
	var rollback_compile := _compiler.compile_profiles()
	var message: String = compiled["message"]
	for rollback in [map_rollback, profile_rollback]:
		if rollback != OK:
			message += "; document rollback failed: %s" % error_string(rollback)
	if not rollback_compile["ok"]:
		message += "; artifact rollback failed: %s" % rollback_compile["message"]
	return _failure(message)

func _rollback_message(message: String, rollback: Error) -> String:
	if rollback == OK:
		return message
	return "%s; map rollback failed: %s" % [message, error_string(rollback)]

func _profile_path(source: AonwMapSource) -> String:
	return source.map_path.get_base_dir().path_join("terrain_authoring.v1.json")

func _read_text(path: String) -> Dictionary:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % path)
	return {"ok": true, "content": file.get_as_text()}

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
