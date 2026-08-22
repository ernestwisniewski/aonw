class_name AonwTerrainAuthoringStore
extends AonwTerrainAuthoringPersistence

const SnapshotStore := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_snapshot_store.gd"
)
const DRAFT_POINTER_FILE := "current_draft.v1.json"
const PUBLISHED_POINTER_FILE := "current_published.v1.json"
const DRAFT_DIRECTORY := "draft"
const PUBLISHED_DIRECTORY := "published"
const LEGACY_STATE_FILE := "terrain_authoring_state.v1.json"
const LEGACY_PUBLISH_FILE := "published_terrain.v1.json"
const LEGACY_DATA_DIRECTORY := "final"

var _root: String
var _snapshots: AonwTerrainSnapshotStore

func _init(root: String) -> void:
	assert(not root.is_empty(), "Terrain authoring root is required")
	_root = root
	_snapshots = SnapshotStore.new(root)

func reference_texture_path() -> String:
	return _root.path_join("reference_texture.res")

func load_revision(expected_identity: AonwTerrainArtifactIdentity) -> Dictionary:
	if not FileAccess.file_exists(_snapshots.pointer_path(DRAFT_POINTER_FILE)):
		return _load_empty_revision()
	var current := _snapshots.read_current(DRAFT_POINTER_FILE, DRAFT_DIRECTORY)
	if not current["ok"]:
		return current
	var pointer: Dictionary = current["pointer"]
	var compatibility := expected_identity.compatibility_with(pointer)
	if compatibility != AonwTerrainArtifactIdentity.COMPATIBLE:
		return _compatibility_failure(
			compatibility,
			"saved terrain is not compatible with the current compiled artifact",
		)
	var workspace := _snapshots.restore_workspace(current["data_directory"])
	if not workspace["ok"]:
		return workspace
	return {
		"ok": true,
		"compatibility": "compatible",
		"has_draft": true,
		"revision": int(pointer["terrainRevision"]),
		"data_directory": workspace["data_directory"],
	}

func save_reference_texture(texture: Texture2D) -> Error:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root))
	if error != OK:
		return error
	return ResourceSaver.save(texture, reference_texture_path(), ResourceSaver.FLAG_COMPRESS)

func save_draft(
	data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	terrain_revision: int,
) -> Dictionary:
	var snapshot := _snapshots.create_snapshot(
		data,
		artifact.metadata(terrain_revision),
		DRAFT_DIRECTORY,
	)
	if not snapshot["ok"]:
		return snapshot
	var switch := _snapshots.write_current(
		DRAFT_POINTER_FILE,
		snapshot["manifest"],
		snapshot["data_directory"],
	)
	if not switch["ok"]:
		return switch
	return {
		"ok": true,
		"manifest_path": switch["manifest_path"],
		"snapshot_hash": snapshot["snapshot_hash"],
		"data_directory": snapshot["data_directory"],
	}

func publish(
	data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	terrain_revision: int,
) -> Dictionary:
	var draft := save_draft(data, artifact, terrain_revision)
	if not draft["ok"]:
		return draft
	var published := _snapshots.promote_snapshot(
		draft["data_directory"],
		draft["snapshot_hash"],
		PUBLISHED_DIRECTORY,
	)
	if not published["ok"]:
		return published
	var switch := _snapshots.write_current(
		PUBLISHED_POINTER_FILE,
		published["manifest"],
		published["data_directory"],
	)
	if not switch["ok"]:
		return switch
	return {
		"ok": true,
		"manifest_path": switch["manifest_path"],
		"snapshot_hash": draft["snapshot_hash"],
		"data_directory": published["data_directory"],
	}

func _load_empty_revision() -> Dictionary:
	if _has_legacy_state():
		return _compatibility_failure(
			"requiresMigration",
			"legacy Terrain3D authoring data requires an explicit migration",
		)
	var workspace := _snapshots.prepare_empty_workspace()
	if not workspace["ok"]:
		return workspace
	return {
		"ok": true,
		"compatibility": "compatible",
		"has_draft": false,
		"revision": 0,
	}

func _has_legacy_state() -> bool:
	return (
		FileAccess.file_exists(_root.path_join(LEGACY_STATE_FILE))
		or FileAccess.file_exists(_root.path_join(LEGACY_PUBLISH_FILE))
		or DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(_root.path_join(LEGACY_DATA_DIRECTORY))
		)
	)

func _compatibility_failure(compatibility: String, message: String) -> Dictionary:
	return {"ok": false, "compatibility": compatibility, "message": message}
