class_name AonwTerrainAuthoringStore
extends RefCounted

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const STATE_FILE := "terrain_authoring_state.v1.json"
const PUBLISH_FILE := "published_terrain.v1.json"
const DATA_DIRECTORY := "final"

var _root: String
var _atomic_store := AtomicResourceStore.new()

func _init(root: String) -> void:
	assert(not root.is_empty(), "Terrain authoring root is required")
	_root = root

func data_directory() -> String:
	return _root.path_join(DATA_DIRECTORY)

func reference_texture_path() -> String:
	return _root.path_join("reference_texture.res")

func has_final_terrain() -> bool:
	var directory := DirAccess.open(ProjectSettings.globalize_path(data_directory()))
	if directory == null:
		return false
	for file_name in directory.get_files():
		if file_name.begins_with("terrain3d_") and file_name.get_extension() == "res":
			return true
	return false

func load_revision(expected_map_content_hash: String) -> Dictionary:
	var path := _root.path_join(STATE_FILE)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		if has_final_terrain():
			return _failure("saved Terrain3D final terrain has no authoring state")
		return {"ok": true, "revision": 0}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _failure("terrain authoring state is invalid")
	if int(parsed.get("schemaVersion", 0)) != 1:
		return _failure("terrain authoring state schemaVersion is unsupported")
	if str(parsed.get("mapContentHash", "")) != expected_map_content_hash:
		return _failure("saved terrain belongs to a different logical map revision")
	var revision := int(parsed.get("terrainRevision", -1))
	if revision < 0:
		return _failure("terrainRevision is invalid")
	return {"ok": true, "revision": revision}

func save_reference_texture(texture: Texture2D) -> Error:
	var directory_error := _ensure_root()
	if directory_error != OK:
		return directory_error
	return ResourceSaver.save(texture, reference_texture_path(), ResourceSaver.FLAG_COMPRESS)

func save_draft(
	data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	terrain_revision: int,
) -> Dictionary:
	var directory_error := _ensure_root()
	if directory_error != OK:
		return _failure("cannot create terrain authoring directory: %s" % error_string(directory_error))
	directory_error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(data_directory())
	)
	if directory_error != OK:
		return _failure("cannot create Terrain3D data directory: %s" % error_string(directory_error))
	data.save_directory(data_directory())
	if not has_final_terrain():
		return _failure("Terrain3D did not persist any final region")
	var state_error := _atomic_store.write_text(
		_root.path_join(STATE_FILE),
		JSON.stringify(artifact.metadata(terrain_revision), "  ", false) + "\n",
	)
	if state_error != OK:
		return _failure("cannot save terrain authoring state: %s" % error_string(state_error))
	return {"ok": true}

func publish(
	data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	terrain_revision: int,
) -> Dictionary:
	var draft_result := save_draft(data, artifact, terrain_revision)
	if not draft_result["ok"]:
		return draft_result
	var manifest := artifact.metadata(terrain_revision)
	manifest["terrainDataDirectory"] = data_directory()
	var publish_error := _atomic_store.write_text(
		_root.path_join(PUBLISH_FILE),
		JSON.stringify(manifest, "  ", false) + "\n",
	)
	if publish_error != OK:
		return _failure("cannot publish terrain manifest: %s" % error_string(publish_error))
	return {"ok": true, "manifest_path": _root.path_join(PUBLISH_FILE)}

func _ensure_root() -> Error:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root))

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
