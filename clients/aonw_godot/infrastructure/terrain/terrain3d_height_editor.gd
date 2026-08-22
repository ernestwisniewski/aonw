class_name AonwTerrain3DHeightEditor
extends RefCounted

var _data: Terrain3DData
var _minimum_height: float
var _maximum_height: float

func _init(
	data: Terrain3DData,
	minimum_height: float,
	maximum_height: float,
) -> void:
	assert(data != null, "Terrain3D data is required")
	assert(minimum_height <= maximum_height, "Terrain height range is invalid")
	_data = data
	_minimum_height = minimum_height
	_maximum_height = maximum_height

func height_at(global_position: Vector3) -> float:
	return _data.get_height(global_position)

func set_height(global_position: Vector3, requested_height: float) -> float:
	var height := clampf(requested_height, _minimum_height, _maximum_height)
	_data.set_height(global_position, height)
	return height

func change_height(
	history: UndoRedo,
	global_position: Vector3,
	requested_height: float,
) -> bool:
	var previous_height := height_at(global_position)
	var next_height := clampf(requested_height, _minimum_height, _maximum_height)
	if is_equal_approx(previous_height, next_height):
		return false
	history.create_action("Change terrain height")
	history.add_do_method(Callable(self, "set_height").bind(global_position, next_height))
	history.add_undo_method(Callable(self, "set_height").bind(global_position, previous_height))
	history.commit_action()
	return true
