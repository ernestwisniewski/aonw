class_name AonwMapSurfaceMeshBuilder
extends RefCounted

const HexGridGeometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const MapTextureProjection := preload(
	"res://game/presentation/map/geometry/map_texture_projection.gd"
)
const HexMapProjection := preload("res://game/presentation/map/hex_map_projection.gd")
const REFERENCE_OFFSET := 0.012
const GRID_OFFSET := 0.035
const GRID_RENDER_PRIORITY := 1

func build(
	document: AonwMapDocument,
	terrain_texture: Texture2D,
	reference_texture: Texture2D,
	settings: Resource,
) -> Dictionary:
	var surface_projection := HexMapProjection.new(
		document,
		settings.hex_radius,
		settings.height_step,
	)
	var geometry: AonwHexGridGeometry = surface_projection.geometry()
	var projection := MapTextureProjection.new(geometry)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var corner_indices := {}
	var map_center := surface_projection.map_center()

	var sorted_corner_keys: Array = surface_projection.corner_keys()
	sorted_corner_keys.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		return left.y < right.y or (left.y == right.y and left.x < right.x)
	)
	for key: Vector2i in sorted_corner_keys:
		var world_position := geometry.lattice_to_world(key)
		corner_indices[key] = vertices.size()
		vertices.append(Vector3(
			world_position.x - map_center.x,
			surface_projection.corner_height(key),
			world_position.y - map_center.y,
		))
		uvs.append(projection.normalized_uv(world_position))

	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var center := surface_projection.hex_center(coordinate)
		var center_index := vertices.size()
		vertices.append(center)
		uvs.append(projection.normalized_uv(geometry.tile_center(coordinate)))
		for corner in 6:
			indices.append(center_index)
			indices.append(corner_indices[geometry.corner_key(coordinate, (corner + 1) % 6)])
			indices.append(corner_indices[geometry.corner_key(coordinate, corner)])

	return {
		"terrain_mesh": _textured_mesh(vertices, uvs, indices, terrain_texture, 1.0),
		"reference_mesh": _textured_mesh(
			_offset_vertices(vertices, REFERENCE_OFFSET),
			uvs,
			indices,
			reference_texture,
			settings.reference_opacity,
		),
		"grid_mesh": _grid_mesh(
			document,
			geometry,
			corner_indices,
			vertices,
			settings.grid_width,
			settings.grid_opacity,
		),
		"world_size": geometry.bounds().size,
		"maximum_height": float(AonwMapDocument.MAX_HEIGHT) * settings.height_step,
	}

func _textured_mesh(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	texture: Texture2D,
	opacity: float,
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = texture
	material.albedo_color = Color(1.0, 1.0, 1.0, opacity)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.surface_set_material(0, material)
	return mesh

func _grid_mesh(
	document: AonwMapDocument,
	geometry: AonwHexGridGeometry,
	corner_indices: Dictionary,
	terrain_vertices: PackedVector3Array,
	width: float,
	opacity: float,
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var edges := {}
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		for corner in 6:
			var first := geometry.corner_key(coordinate, corner)
			var second := geometry.corner_key(coordinate, (corner + 1) % 6)
			var edge_key := _edge_key(first, second)
			if edges.has(edge_key):
				continue
			edges[edge_key] = true
			var first_vertex: Vector3 = terrain_vertices[corner_indices[first]]
			var second_vertex: Vector3 = terrain_vertices[corner_indices[second]]
			first_vertex.y += GRID_OFFSET
			second_vertex.y += GRID_OFFSET
			_append_grid_segment(vertices, indices, first_vertex, second_vertex, width)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.025, 0.035, 0.055, opacity)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.render_priority = GRID_RENDER_PRIORITY
	material.no_depth_test = true
	mesh.surface_set_material(0, material)
	return mesh

func _append_grid_segment(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	first: Vector3,
	second: Vector3,
	width: float,
) -> void:
	var direction := Vector2(second.x - first.x, second.z - first.z)
	if direction.is_zero_approx():
		return
	var perpendicular := direction.normalized().orthogonal() * maxf(width, 0.001) * 0.5
	var offset := Vector3(perpendicular.x, 0.0, perpendicular.y)
	var start := vertices.size()
	vertices.append(first - offset)
	vertices.append(first + offset)
	vertices.append(second + offset)
	vertices.append(second - offset)
	indices.append_array(PackedInt32Array([
		start,
		start + 1,
		start + 2,
		start,
		start + 2,
		start + 3,
	]))

func _offset_vertices(vertices: PackedVector3Array, offset: float) -> PackedVector3Array:
	var result := vertices.duplicate()
	for index in result.size():
		var vertex := result[index]
		vertex.y += offset
		result[index] = vertex
	return result

func _edge_key(first: Vector2i, second: Vector2i) -> Vector4i:
	if first.y < second.y or (first.y == second.y and first.x < second.x):
		return Vector4i(first.x, first.y, second.x, second.y)
	return Vector4i(second.x, second.y, first.x, first.y)
