class_name AonwMapOverlayLayer
extends Node3D

const HOVER_OFFSET := 0.055
const SELECTION_OFFSET := 0.05
const REACHABLE_OFFSET := 0.045

var _projection: AonwHexMapProjection
var _hover: MeshInstance3D
var _selection: MeshInstance3D
var _reachable: MeshInstance3D

func _ready() -> void:
	_ensure_layers()

func present(projection: AonwHexMapProjection) -> void:
	_projection = projection
	_ensure_layers()
	clear()

func set_hovered(coordinate: Vector2i) -> void:
	_set_single_hex(_hover, coordinate, HOVER_OFFSET)

func set_selected(coordinate: Vector2i) -> void:
	_set_single_hex(_selection, coordinate, SELECTION_OFFSET)

func set_reachable(coordinates: Array) -> void:
	_ensure_layers()
	_reachable.mesh = _build_mesh(coordinates, REACHABLE_OFFSET)

func clear() -> void:
	_ensure_layers()
	_hover.mesh = null
	_selection.mesh = null
	_reachable.mesh = null

func _set_single_hex(layer: MeshInstance3D, coordinate: Vector2i, offset: float) -> void:
	_ensure_layers()
	if _projection == null or not _projection.contains(coordinate):
		layer.mesh = null
		return
	layer.mesh = _build_mesh([coordinate], offset)

func _build_mesh(coordinates: Array, offset: float) -> ArrayMesh:
	if _projection == null or coordinates.is_empty():
		return null
	var vertices := PackedVector3Array()
	for value in coordinates:
		var coordinate: Vector2i = value
		if not _projection.contains(coordinate):
			continue
		var center := _projection.hex_center(coordinate, offset)
		for corner in 6:
			vertices.append(center)
			vertices.append(_projection.hex_corner(coordinate, corner, offset))
			vertices.append(_projection.hex_corner(coordinate, (corner + 1) % 6, offset))
	if vertices.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _ensure_layers() -> void:
	if _reachable == null:
		_reachable = _layer("Reachable", Color(0.12, 0.78, 0.45, 0.28))
	if _selection == null:
		_selection = _layer("Selection", Color(0.12, 0.72, 1.0, 0.5))
	if _hover == null:
		_hover = _layer("Hover", Color(1.0, 0.82, 0.18, 0.38))

func _layer(layer_name: String, color: Color) -> MeshInstance3D:
	var layer := get_node_or_null(layer_name) as MeshInstance3D
	if layer == null:
		layer = MeshInstance3D.new()
		layer.name = layer_name
		add_child(layer)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	material.albedo_color = color
	layer.material_override = material
	layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return layer
