extends SceneTree

const MapAuthoringSuite := preload("res://tests/suites/map_authoring_suite.gd")
const MapGeometrySuite := preload("res://tests/suites/map_geometry_suite.gd")
const NativeSessionSuite := preload("res://tests/suites/native_session_suite.gd")
const Terrain3DSpikeSuite := preload("res://tests/suites/terrain3d_spike_suite.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for suite in [
		MapGeometrySuite.new(),
		NativeSessionSuite.new(),
		MapAuthoringSuite.new(),
		Terrain3DSpikeSuite.new(),
	]:
		suite.run(_failures)

	if _failures.is_empty():
		print("map pipeline: OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
