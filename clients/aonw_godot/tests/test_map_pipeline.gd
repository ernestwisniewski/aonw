extends SceneTree

const MapAuthoringSuite := preload("res://tests/suites/map_authoring_suite.gd")
const MapGeometrySuite := preload("res://tests/suites/map_geometry_suite.gd")
const NativeSessionSuite := preload("res://tests/suites/native_session_suite.gd")
const NewMapCreationSuite := preload("res://tests/suites/new_map_creation_suite.gd")
const Terrain3DSpikeSuite := preload("res://tests/suites/terrain3d_spike_suite.gd")
const TerrainAuthoringSuite := preload("res://tests/suites/terrain_authoring_suite.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for suite in [
		MapGeometrySuite.new(),
		NativeSessionSuite.new(),
		NewMapCreationSuite.new(),
		MapAuthoringSuite.new(),
		Terrain3DSpikeSuite.new(),
		TerrainAuthoringSuite.new(),
	]:
		await suite.run(_failures)

	if _failures.is_empty():
		print("map pipeline: OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
