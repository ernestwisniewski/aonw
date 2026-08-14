@tool
class_name AonwTerrain3DRuntimeAdapter
extends RefCounted

const TERRAIN_CLASS := &"Terrain3D"
const GROUND_NAME := &"Terrain3DGround"
const TERRAIN_NODE_NAME := &"Terrain3D"

static func is_available() -> bool:
	return ClassDB.class_exists(TERRAIN_CLASS) and ClassDB.can_instantiate(TERRAIN_CLASS)

static func availability_message() -> String:
	if is_available():
		return "Terrain3D is available."
	return (
		"Terrain3D is not installed or its GDExtension did not load. "
		+ "Install and enable the Terrain3D addon before generating this backend."
	)

func create_ground(
	artifact: Dictionary,
	intended_parent: Node3D = null,
) -> Dictionary:
	if not artifact.get("ok", false):
		return artifact
	if not is_available():
		return _failure(availability_message())
	for required in [
		"height_map",
		"control_map",
		"color_map",
		"region_size",
		"vertex_spacing",
		"import_origin",
	]:
		if not artifact.has(required):
			return _failure("Terrain3D artifact is missing %s" % required)

	var instantiated: Object = ClassDB.instantiate(TERRAIN_CLASS)
	if not instantiated is Node3D:
		if instantiated != null:
			instantiated.free()
		return _failure("Terrain3D could not be instantiated as Node3D")

	var terrain := instantiated as Node3D
	terrain.name = TERRAIN_NODE_NAME
	# Region size and vertex spacing are read while Terrain3D enters the world,
	# so configure them before staging. Material and collision aliases are
	# initialized only after the node enters the tree and are applied below.
	_set_property_if_present(terrain, &"region_size", int(artifact["region_size"]))
	_set_property_if_present(terrain, &"vertex_spacing", float(artifact["vertex_spacing"]))

	var ground := Node3D.new()
	ground.name = GROUND_NAME
	ground.add_child(terrain)

	# Terrain3D creates Terrain3DData when it enters a world. Map generation
	# normally builds an AonwMapSurface off-tree, so stage the wrapper under the
	# active SceneTree root for initialization and detach it after import.
	var staging_result := _stage_in_tree(ground, intended_parent)
	if not staging_result["ok"]:
		ground.free()
		return staging_result

	var data := terrain.get(&"data") as Object
	if data == null or not data.has_method(&"import_images"):
		_detach_staging_ground(ground, staging_result)
		ground.free()
		return _failure(
			"Loaded Terrain3D version does not expose Terrain3DData.import_images()"
		)

	# Reapply runtime aliases after initialization. Before Terrain3D enters the
	# tree its material and collision objects do not exist, so those setters are
	# intentionally invoked here rather than only before staging.
	if terrain.has_method(&"change_region_size"):
		terrain.call(&"change_region_size", int(artifact["region_size"]))
	else:
		_set_property_if_present(terrain, &"region_size", int(artifact["region_size"]))
	_set_property_if_present(terrain, &"vertex_spacing", float(artifact["vertex_spacing"]))
	_set_property_if_present(terrain, &"show_colormap", true)
	_set_property_if_present(terrain, &"show_grey", true)
	_set_property_if_present(terrain, &"collision_mode", 0)

	var images: Array[Image] = [
		artifact["height_map"],
		artifact["control_map"],
		artifact["color_map"],
	]
	data.call(
		&"import_images",
		images,
		artifact["import_origin"],
		0.0,
		1.0,
	)
	var region_count := _region_count(data)
	if region_count <= 0:
		_detach_staging_ground(ground, staging_result)
		ground.free()
		return _failure("Terrain3D did not create any active regions")

	_detach_staging_ground(ground, staging_result)
	return {
		"ok": true,
		"ground": ground,
		"terrain": terrain,
		"already_parented": (
			intended_parent != null and ground.get_parent() == intended_parent
		),
		"version": _version(terrain),
		"region_count": region_count,
	}

func save_directory(ground: Node3D, path: String) -> Dictionary:
	var terrain := terrain_node(ground)
	if terrain == null:
		return _failure("Terrain3D ground does not contain a Terrain3D node")
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path)
	if directory_error != OK:
		return _failure(
			"cannot create Terrain3D data directory: %s" % error_string(directory_error)
		)

	# Save first while the node still points at its current generation. Changing
	# data_directory from a non-empty path makes Terrain3D reload immediately;
	# doing that before save would replace the live regions with the new empty
	# directory when an authored scene is saved without a preceding rebuild.
	var data := terrain.get(&"data") as Object
	if data == null or not data.has_method(&"save_directory"):
		return _failure("Loaded Terrain3D version does not expose save_directory()")
	var saved_region_count := _region_count(data)
	if saved_region_count <= 0:
		return _failure("Terrain3D data is empty before saving")
	data.call(&"save_directory", path)

	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return _failure("cannot reopen Terrain3D data directory")
	var saved_files: Array[String] = []
	for file_name in directory.get_files():
		if file_name.begins_with("terrain3d_"):
			saved_files.append(file_name)
	if saved_files.is_empty():
		return _failure("Terrain3D did not write any region resources")
	if saved_files.size() < saved_region_count:
		return _failure(
			"Terrain3D wrote %d region files for %d active regions"
			% [saved_files.size(), saved_region_count]
		)
	saved_files.sort()

	_set_property_if_present(terrain, &"data_directory", path)
	# Off-tree generation deliberately leaves Terrain3D to load the new path
	# when the packed scene next enters a world. In an open editor/runtime scene
	# it reloads immediately, so validate that live data as well.
	if terrain.is_inside_tree():
		data = terrain.get(&"data") as Object
		if data == null or _region_count(data) <= 0:
			return _failure("Terrain3D could not reload the persisted region resources")
		saved_region_count = _region_count(data)
	return {
		"ok": true,
		"data_directory": path,
		"region_count": saved_region_count,
		"saved_files": saved_files,
		"version": _version(terrain),
	}

func terrain_node(ground: Node3D) -> Node3D:
	if ground == null:
		return null
	if ground.is_class(String(TERRAIN_CLASS)):
		return ground
	return ground.get_node_or_null(NodePath(String(TERRAIN_NODE_NAME))) as Node3D

func active_region_count(ground: Node3D) -> int:
	var terrain := terrain_node(ground)
	if terrain == null:
		return 0
	return _region_count(terrain.get(&"data") as Object)

func height_at(ground: Node3D, global_position: Vector3) -> float:
	var terrain := terrain_node(ground)
	if terrain == null:
		return NAN
	var data := terrain.get(&"data") as Object
	if data == null or not data.has_method(&"get_height"):
		return NAN
	return float(data.call(&"get_height", global_position))

func intersect(
	ground: Node3D,
	global_origin: Vector3,
	global_direction: Vector3,
) -> Dictionary:
	var terrain := terrain_node(ground)
	if terrain == null or not terrain.has_method(&"get_intersection"):
		return _failure("Terrain3D intersection API is unavailable")
	var point: Vector3 = terrain.call(
		&"get_intersection",
		global_origin,
		global_direction,
		false,
	)
	if is_nan(point.x) or is_nan(point.y) or is_nan(point.z):
		return _failure("Terrain3D intersection failed")
	var largest_component := maxf(absf(point.x), maxf(absf(point.y), absf(point.z)))
	if largest_component > 3.4e38:
		return {"ok": true, "hit": false}
	return {"ok": true, "hit": true, "position": point}

func version(ground: Node3D) -> String:
	return _version(terrain_node(ground))

func _stage_in_tree(ground: Node3D, intended_parent: Node3D) -> Dictionary:
	if intended_parent != null and intended_parent.is_inside_tree():
		intended_parent.add_child(ground)
		return {"ok": true, "staging_parent": intended_parent, "temporary": false}

	var main_loop := Engine.get_main_loop()
	if not main_loop is SceneTree:
		return _failure("Terrain3D generation requires an active SceneTree")
	var tree := main_loop as SceneTree
	if tree.root == null:
		return _failure("Terrain3D generation cannot access the SceneTree root")
	ground.name = "%sStaging" % String(GROUND_NAME)
	tree.root.add_child(ground, true)
	return {"ok": true, "staging_parent": tree.root, "temporary": true}

func _detach_staging_ground(ground: Node3D, staging_result: Dictionary) -> void:
	if not staging_result.get("temporary", false):
		return
	var staging_parent := staging_result.get("staging_parent") as Node
	if staging_parent != null and ground.get_parent() == staging_parent:
		staging_parent.remove_child(ground)
	ground.name = GROUND_NAME

func _version(terrain: Node3D) -> String:
	if terrain == null:
		return ""
	for method_name in [&"get_version", &"get_plugin_version"]:
		if terrain.has_method(method_name):
			return str(terrain.call(method_name))
	if _has_property(terrain, &"version"):
		return str(terrain.get(&"version"))
	return "1.x"

func _region_count(data: Object) -> int:
	if data == null or not data.has_method(&"get_region_count"):
		return 0
	return int(data.call(&"get_region_count"))

func _set_property_if_present(
	object: Object,
	property_name: StringName,
	value: Variant,
) -> void:
	if _has_property(object, property_name):
		object.set(property_name, value)

func _has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property["name"]) == property_name:
			return true
	return false

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
