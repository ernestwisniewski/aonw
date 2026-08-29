extends SceneTree

const NativeSessionSuite := preload("res://tests/suites/native_session_suite.gd")
const MovementPresentationSuite := preload(
	"res://tests/suites/movement_presentation_suite.gd"
)

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for suite in [
		NativeSessionSuite.new(),
		MovementPresentationSuite.new(),
	]:
		await suite.run(_failures)

	if _failures.is_empty():
		print("runtime pipeline: OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
