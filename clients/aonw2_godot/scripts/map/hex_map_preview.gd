@tool
extends Node3D

const MapDocument := preload("res://scripts/map/map_document.gd")
const SQRT_3 := 1.7320508075688772

@export_file("*.json") var map_source := "res://../../content/maps/aonw2_starter/map.json":
	set(value):
		map_source = value
		if is_inside_tree():
			call_deferred("_rebuild")
@export_range(0.25, 4.0, 0.05) var hex_radius := 1.0:
	set(value):
		hex_radius = value
		if is_inside_tree():
			call_deferred("_rebuild")

var _last_modified_time := 0

func _ready() -> void:
	_rebuild()
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	var modified_time := FileAccess.get_modified_time(MapDocument.resolve_path(map_source))
	if modified_time != _last_modified_time:
		_rebuild()

func _rebuild() -> void:
	var source_path: String = MapDocument.resolve_path(map_source)
	_last_modified_time = FileAccess.get_modified_time(source_path)
	var document: Dictionary = MapDocument.load_map(source_path)
	if document.is_empty():
		return

	var previous := get_node_or_null("GeneratedTiles")
	if previous != null:
		previous.free()

	var generated := Node3D.new()
	generated.name = "GeneratedTiles"
	add_child(generated)

	var groups := _group_tile_transforms(document["tiles"])
	for key in groups:
		_add_group(generated, groups[key])

	var cols := int(document["cols"])
	var rows := int(document["rows"])
	var width := float(cols - 1) * 1.5 * hex_radius
	var depth := float(rows - 1) * SQRT_3 * hex_radius
	if cols > 1:
		depth += 0.5 * SQRT_3 * hex_radius
	generated.position = Vector3(-width * 0.5, 0.0, -depth * 0.5)

func _group_tile_transforms(tiles: Array) -> Dictionary:
	var groups := {}
	for tile: Dictionary in tiles:
		var terrain: String = tile["terrains"][0]
		var height := int(tile["height"])
		var key := "%s:%d" % [terrain, height]
		if not groups.has(key):
			groups[key] = {
				"terrain": terrain,
				"height": height,
				"transforms": [],
			}
		var x := float(tile["col"]) * 1.5 * hex_radius
		var z := float(tile["row"]) * SQRT_3 * hex_radius
		if int(tile["col"]) % 2 == 1:
			z += 0.5 * SQRT_3 * hex_radius
		var mesh_height := _mesh_height(height)
		groups[key]["transforms"].append(
			Transform3D(Basis.IDENTITY, Vector3(x, mesh_height * 0.5, z))
		)
	return groups

func _add_group(parent: Node3D, group: Dictionary) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = hex_radius * 0.96
	mesh.bottom_radius = hex_radius * 0.96
	mesh.height = _mesh_height(group["height"])
	mesh.radial_segments = 6
	mesh.rings = 1

	var material := StandardMaterial3D.new()
	material.albedo_color = _terrain_color(group["terrain"])
	material.roughness = 0.92
	mesh.material = material

	var transforms: Array = group["transforms"]
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = mesh
	multi_mesh.instance_count = transforms.size()
	for index in transforms.size():
		multi_mesh.set_instance_transform(index, transforms[index])

	var instance := MultiMeshInstance3D.new()
	instance.name = "%s_%d" % [group["terrain"], group["height"]]
	instance.multimesh = multi_mesh
	instance.rotation.y = PI / 6.0
	parent.add_child(instance)

func _mesh_height(height: int) -> float:
	return 0.18 + float(height) * 0.18

func _terrain_color(terrain: String) -> Color:
	match terrain:
		"ocean": return Color("244c72")
		"coast": return Color("3f7f9e")
		"lake": return Color("367aa3")
		"plains": return Color("b6a662")
		"grassland": return Color("669653")
		"desert": return Color("d1ad68")
		"tundra": return Color("8f9890")
		"snow": return Color("d9e2e5")
		"mountain": return Color("5d6064")
		"hills": return Color("887553")
		"wetlands": return Color("477263")
		"jungle": return Color("2f6f42")
		"forest": return Color("3e6840")
		"river": return Color("4387b5")
		_: return Color.MAGENTA
