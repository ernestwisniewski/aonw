class_name AonwUnitLayer
extends Node3D

const UNIT_OFFSET := 0.24

var _projection: AonwHexMapProjection
var _units: Dictionary = {}
var _instances: Dictionary = {}

func present(projection: AonwHexMapProjection, units: Array) -> void:
	_projection = projection
	_clear_instances()
	for value in units:
		var unit: Dictionary = value
		var unit_id := str(unit["id"])
		_units[unit_id] = unit.duplicate(true)
		var instance := _create_marker(unit_id)
		_instances[unit_id] = instance
		add_child(instance)
		instance.position = _unit_position(unit)

func unit_at(coordinate: Vector2i) -> String:
	for unit_id in _units:
		var unit: Dictionary = _units[unit_id]
		if Vector2i(int(unit["col"]), int(unit["row"])) == coordinate:
			return unit_id
	return ""

func move_unit(unit_id: String, coordinate: Vector2i, animated: bool = true) -> void:
	if not _units.has(unit_id) or not _instances.has(unit_id):
		return
	var unit: Dictionary = _units[unit_id]
	unit["col"] = coordinate.x
	unit["row"] = coordinate.y
	_units[unit_id] = unit
	var instance: MeshInstance3D = _instances[unit_id]
	var target := _unit_position(unit)
	if not animated or not is_inside_tree():
		instance.position = target
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(instance, "position", target, 0.28)

func _unit_position(unit: Dictionary) -> Vector3:
	var coordinate := Vector2i(int(unit["col"]), int(unit["row"]))
	return _projection.hex_center(coordinate, UNIT_OFFSET)

func _create_marker(unit_id: String) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.2
	mesh.bottom_radius = 0.24
	mesh.height = 0.38
	mesh.radial_segments = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.72, 1.0)
	material.metallic = 0.15
	material.roughness = 0.38
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = unit_id.validate_node_name()
	instance.mesh = mesh
	return instance

func _clear_instances() -> void:
	for instance in _instances.values():
		(instance as Node).queue_free()
	_units.clear()
	_instances.clear()
