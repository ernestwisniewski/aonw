class_name AonwMapSurfaceMeshBuilder
extends RefCounted

const HexGridGeometry := preload("res://domain/map/hex_grid_geometry.gd")

func build(
	document: AonwMapDocument,
	map_texture: Texture2D,
	radius: float,
	height_step: float,
) -> Dictionary:
	var geometry := HexGridGeometry.new(document.cols(), document.rows(), radius)
	var corner_heights := _corner_heights(document, geometry, height_step)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var corner_indices := {}
	var map_center := geometry.bounds().get_center()

	var sorted_corner_keys: Array = corner_heights.keys()
	sorted_corner_keys.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		return left.y < right.y or (left.y == right.y and left.x < right.x)
	)
	for key: Vector2i in sorted_corner_keys:
		var world_position := geometry.lattice_to_world(key)
		corner_indices[key] = vertices.size()
		vertices.append(Vector3(
			world_position.x - map_center.x,
			corner_heights[key],
			world_position.y - map_center.y,
		))
		uvs.append(geometry.normalized_uv(world_position))

	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var center := geometry.tile_center(coordinate)
		var center_index := vertices.size()
		vertices.append(Vector3(
			center.x - map_center.x,
			float(tile["height"]) * height_step,
			center.y - map_center.y,
		))
		uvs.append(geometry.normalized_uv(center))
		for corner in 6:
			indices.append(center_index)
			indices.append(corner_indices[geometry.corner_key(coordinate, (corner + 1) % 6)])
			indices.append(corner_indices[geometry.corner_key(coordinate, corner)])

	var terrain_mesh := _terrain_mesh(vertices, uvs, indices, map_texture)
	var grid_mesh := _grid_mesh(document, geometry, corner_indices, vertices)
	return {
		"terrain_mesh": terrain_mesh,
		"grid_mesh": grid_mesh,
		"world_size": geometry.bounds().size,
	}

func _corner_heights(
	document: AonwMapDocument,
	geometry: AonwHexGridGeometry,
	height_step: float,
) -> Dictionary:
	var totals := {}
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		for corner in 6:
			var key := geometry.corner_key(coordinate, corner)
			var total: Vector2 = totals.get(key, Vector2.ZERO)
			totals[key] = total + Vector2(float(tile["height"]) * height_step, 1.0)
	for key in totals:
		var total: Vector2 = totals[key]
		totals[key] = total.x / total.y
	return totals

func _terrain_mesh(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	map_texture: Texture2D,
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
	material.albedo_texture = map_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.surface_set_material(0, material)
	return mesh

func _grid_mesh(
	document: AonwMapDocument,
	geometry: AonwHexGridGeometry,
	corner_indices: Dictionary,
	terrain_vertices: PackedVector3Array,
) -> ArrayMesh:
	var vertices := PackedVector3Array()
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
			first_vertex.y += 0.025
			second_vertex.y += 0.025
			vertices.append(first_vertex)
			vertices.append(second_vertex)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.06, 0.08, 0.1, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.surface_set_material(0, material)
	return mesh
func _edge_key(first: Vector2i, second: Vector2i) -> String:
	if first.y < second.y or (first.y == second.y and first.x < second.x):
		return "%d:%d|%d:%d" % [first.x, first.y, second.x, second.y]
	return "%d:%d|%d:%d" % [second.x, second.y, first.x, first.y]
