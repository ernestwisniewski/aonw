class_name AonwTerrainOverlayMeshBuilder
extends RefCounted

const HexGridGeometry := preload(
	"res://game/presentation/map/geometry/hex_grid_geometry.gd"
)
const REFERENCE_OFFSET := 0.012
const GRID_OFFSET := 0.035
const CONSTRAINT_OFFSET := 0.06

func reference_mesh(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	texture: Texture2D,
	opacity: float,
) -> ArrayMesh:
	var heights := Image.create(artifact.width, artifact.height, false, Image.FORMAT_RF)
	for y in artifact.height:
		for x in artifact.width:
			var pixel := Vector2i(x, y)
			heights.set_pixelv(
				pixel,
				Color(data.get_height(artifact.local_position(pixel)) + REFERENCE_OFFSET, 0.0, 0.0),
			)
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	return _raster_mesh(
		artifact,
		heights,
		Color(1.0, 1.0, 1.0, opacity),
		texture,
		geometry.bounds(),
	)

func constraint_mesh(
	artifact: AonwTerrainCompiledArtifact,
	image: Image,
	color: Color,
	vertical_offset: float,
) -> ArrayMesh:
	var heights: Image = image.duplicate()
	for y in heights.get_height():
		for x in heights.get_width():
			var value: float = heights.get_pixel(x, y).r + vertical_offset
			heights.set_pixel(x, y, Color(value, 0.0, 0.0))
	return _raster_mesh(artifact, heights, color, null, Rect2())

func grid_mesh(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	width: float,
	opacity: float,
) -> ArrayMesh:
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var edges := {}
	for row in artifact.rows:
		for col in artifact.cols:
			var coordinate := Vector2i(col, row)
			for corner in 6:
				var first_key := geometry.corner_key(coordinate, corner)
				var second_key := geometry.corner_key(coordinate, (corner + 1) % 6)
				var edge_key := _edge_key(first_key, second_key)
				if edges.has(edge_key):
					continue
				edges[edge_key] = true
				var first := _terrain_point(
					artifact,
					data,
					geometry.corner_position(coordinate, corner),
					GRID_OFFSET,
				)
				var second := _terrain_point(
					artifact,
					data,
					geometry.corner_position(coordinate, (corner + 1) % 6),
					GRID_OFFSET,
				)
				_append_segment(vertices, indices, first, second, width)
	var mesh := _mesh(vertices, PackedVector2Array(), indices)
	mesh.surface_set_material(0, _material(Color(0.025, 0.035, 0.055, opacity)))
	return mesh

func city_marker(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	coordinate: Vector2i,
) -> Dictionary:
	if artifact.city_core_radius_meters <= 0.0:
		return {"mesh": null, "position": Vector3.ZERO}
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var world_center: Vector2 = geometry.tile_center(coordinate)
	var center := _terrain_point(artifact, data, world_center, 0.08)
	var mesh := CylinderMesh.new()
	mesh.top_radius = artifact.city_core_radius_meters
	mesh.bottom_radius = artifact.city_core_radius_meters
	mesh.height = 0.08
	mesh.radial_segments = 48
	mesh.material = _material(Color(0.95, 0.62, 0.12, 0.45))
	return {"mesh": mesh, "position": center}

func _raster_mesh(
	artifact: AonwTerrainCompiledArtifact,
	heights: Image,
	color: Color,
	texture: Texture2D,
	uv_bounds: Rect2,
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.resize(artifact.width * artifact.height)
	if texture != null:
		uvs.resize(vertices.size())
	for y in artifact.height:
		for x in artifact.width:
			var pixel := Vector2i(x, y)
			var index := y * artifact.width + x
			vertices[index] = artifact.local_position(pixel, heights.get_pixelv(pixel).r)
			if texture != null:
				var world := artifact.world_position(pixel)
				uvs[index] = (
					(Vector2(world.x, world.z) - uv_bounds.position) / uv_bounds.size
				).clamp(Vector2.ZERO, Vector2.ONE)
	for y in artifact.height - 1:
		for x in artifact.width - 1:
			var top_left := y * artifact.width + x
			var bottom_left := top_left + artifact.width
			indices.append_array(PackedInt32Array([
				top_left,
				bottom_left,
				top_left + 1,
				top_left + 1,
				bottom_left,
				bottom_left + 1,
			]))
	var mesh := _mesh(vertices, uvs, indices)
	var material := _material(color)
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.surface_set_material(0, material)
	return mesh

func _mesh(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	return material

func _terrain_point(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	world_point: Vector2,
	vertical_offset: float,
) -> Vector3:
	var local := Vector3(
		world_point.x - artifact.world_min_meters.x,
		0.0,
		world_point.y - artifact.world_min_meters.y,
	)
	local.y = data.get_height(local) + vertical_offset
	return local

func _append_segment(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	first: Vector3,
	second: Vector3,
	width: float,
) -> void:
	var direction := Vector2(second.x - first.x, second.z - first.z)
	if direction.is_zero_approx():
		return
	var perpendicular := direction.normalized().orthogonal() * maxf(width, 0.01) * 0.5
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

func _edge_key(first: Vector2i, second: Vector2i) -> Vector4i:
	if first.y < second.y or (first.y == second.y and first.x < second.x):
		return Vector4i(first.x, first.y, second.x, second.y)
	return Vector4i(second.x, second.y, first.x, first.y)
