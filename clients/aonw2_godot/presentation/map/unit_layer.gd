class_name AonwUnitLayer
extends Node3D

const UNIT_OFFSET := 0.24

var _projection: AonwHexMapProjection
var _units: Dictionary = {}
var _instances: Dictionary = {}
var _movement_tweens: Dictionary = {}

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
		if _coordinate(unit) == coordinate:
			return unit_id
	return ""

func move_unit(unit_id: String, coordinate: Vector2i, animated: bool = true) -> void:
	if not _units.has(unit_id) or not _instances.has(unit_id):
		return
	var unit: Dictionary = _units[unit_id]
	unit["coordinate"] = {"col": coordinate.x, "row": coordinate.y}
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

func apply_transition(patch: Dictionary, evidence: Variant) -> void:
	for value in patch["removedUnitIds"]:
		_remove_unit(str(value))
	var movement_unit_id := ""
	var steps: Array = []
	if evidence is Dictionary and evidence.get("type", "") == "unitMovement":
		movement_unit_id = str(evidence["unitId"])
		steps = evidence["steps"]
	for value in patch["upsertedUnits"]:
		var unit: Dictionary = value
		var unit_id := str(unit["id"])
		var exists := _instances.has(unit_id)
		_units[unit_id] = unit.duplicate(true)
		if not exists:
			var instance := _create_marker(unit_id)
			_instances[unit_id] = instance
			add_child(instance)
			instance.position = _unit_position(unit)
		elif unit_id == movement_unit_id and not steps.is_empty():
			_animate_steps(unit_id, steps)
		else:
			(_instances[unit_id] as MeshInstance3D).position = _unit_position(unit)

func _animate_steps(unit_id: String, steps: Array) -> void:
	if _movement_tweens.has(unit_id):
		(_movement_tweens[unit_id] as Tween).kill()
	var instance: MeshInstance3D = _instances[unit_id]
	if not is_inside_tree():
		instance.position = _unit_position(_units[unit_id])
		return
	var tween := create_tween()
	_movement_tweens[unit_id] = tween
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	for value in steps:
		var step: Dictionary = value
		var coordinate := _coordinate(step)
		tween.tween_property(instance, "position", _projection.hex_center(
			coordinate,
			UNIT_OFFSET,
		), 0.18)
	tween.finished.connect(func() -> void: _movement_tweens.erase(unit_id))

func _unit_position(unit: Dictionary) -> Vector3:
	return _projection.hex_center(_coordinate(unit), UNIT_OFFSET)

func _coordinate(value: Dictionary) -> Vector2i:
	var coordinate: Dictionary = value["coordinate"]
	return Vector2i(int(coordinate["col"]), int(coordinate["row"]))

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
	for tween in _movement_tweens.values():
		(tween as Tween).kill()
	for instance in _instances.values():
		(instance as Node).queue_free()
	_units.clear()
	_instances.clear()
	_movement_tweens.clear()

func _remove_unit(unit_id: String) -> void:
	if _movement_tweens.has(unit_id):
		(_movement_tweens[unit_id] as Tween).kill()
		_movement_tweens.erase(unit_id)
	if _instances.has(unit_id):
		(_instances[unit_id] as Node).queue_free()
		_instances.erase(unit_id)
	_units.erase(unit_id)
