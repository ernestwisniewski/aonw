extends RefCounted

const GenerateGodotMap := preload("res://application/map/generate_godot_map.gd")
const MapSource := preload("res://application/map/map_source.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const GodotMapSceneRepository := preload("res://infrastructure/map/godot_map_scene_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const RenderSettings := preload("res://presentation/map/map_render_settings.gd")
const Terrain3DAdapter := preload(
	"res://presentation/map/terrain3d/terrain3d_runtime_adapter.gd"
)

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_backend_generation_contract()

func _test_backend_generation_contract() -> void:
	var source := MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	)
	var scene_repository := GodotMapSceneRepository.new(
		"res://.godot/terrain3d_authoring_test/scenes",
		"res://.godot/terrain3d_authoring_test/assets",
		"res://.godot/terrain3d_authoring_test/generated",
	)
	var generator := GenerateGodotMap.new(
		OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new()),
		scene_repository,
	)
	var legacy := generator.execute(source, {
		"terrain_backend": RenderSettings.TerrainBackend.LEGACY_MESH,
	})
	_check(legacy["ok"], "legacy backend remains generation default and fallback")
	if not legacy["ok"]:
		return
	_check(
		legacy["terrain_backend"] == "legacyMesh",
		"legacy generation reports its backend",
	)
	var manifest_path := (
		"res://.godot/terrain3d_authoring_test/assets/aonw2_starter/manifest.json"
	)
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	_check(manifest_file != null, "backend generation writes a manifest")
	if manifest_file != null:
		var manifest: Variant = JSON.parse_string(manifest_file.get_as_text())
		_check(manifest is Dictionary, "backend manifest is valid JSON")
		if manifest is Dictionary:
			_check(manifest["formatVersion"] == 2, "backend manifest uses format version 2")
			_check(manifest["terrainBackend"] == "legacyMesh", "manifest records legacy backend")
			_check(not manifest["terrain3d"]["enabled"], "legacy manifest disables Terrain3D")

	var terrain3d := generator.execute(source, {
		"terrain_backend": RenderSettings.TerrainBackend.TERRAIN_3D,
		"terrain_samples_per_radius": 4,
		"terrain3d_region_size": 64,
		"reference_visible": false,
	})
	if not Terrain3DAdapter.is_available():
		_check(not terrain3d["ok"], "missing Terrain3D addon rejects generation cleanly")
		_check(
			str(terrain3d.get("message", "")).contains("Terrain3D"),
			"missing Terrain3D error names the required addon",
		)
		return
	_check(terrain3d["ok"], "installed Terrain3D backend generates a scene")
	if not terrain3d["ok"]:
		return
	_check(
		terrain3d["terrain_backend"] == "terrain3d",
		"Terrain3D generation reports its backend",
	)
	var data_directory := str(terrain3d["terrain3d_data_directory"])
	_check(not data_directory.is_empty(), "Terrain3D generation persists a data directory")
	var directory := DirAccess.open(ProjectSettings.globalize_path(data_directory))
	_check(directory != null, "persisted Terrain3D data directory reopens")
	if directory != null:
		var has_region := false
		for file_name in directory.get_files():
			if file_name.begins_with("terrain3d_"):
				has_region = true
				break
		_check(has_region, "Terrain3D generation writes region resources")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
