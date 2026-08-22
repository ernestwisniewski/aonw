class_name AonwTerrain3DSurfaceSampler
extends RefCounted

var _terrain: Terrain3D

func _init(terrain: Terrain3D) -> void:
	assert(terrain != null, "Terrain3D node is required")
	_terrain = terrain

func align(global_position: Vector3, vertical_offset: float = 0.0) -> Vector3:
	var aligned := global_position
	aligned.y = _terrain.data.get_height(global_position) + vertical_offset
	return aligned

func intersect(global_origin: Vector3, global_direction: Vector3) -> Vector3:
	assert(not global_direction.is_zero_approx(), "Ray direction is required")
	return _terrain.get_intersection(global_origin, global_direction.normalized(), false)
