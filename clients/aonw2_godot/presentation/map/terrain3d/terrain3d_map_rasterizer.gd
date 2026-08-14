@tool
class_name AonwTerrain3DMapRasterizer
extends RefCounted

const HexMapProjection := preload("res://presentation/map/hex_map_projection.gd")
const MapTextureProjection := preload(
	"res://presentation/map/geometry/map_texture_projection.gd"
)
const VisualCatalog := preload(
	"res://presentation/map/terrain/terrain_visual_catalog.gd"
)
const ControlCodec := preload(
	"res://presentation/map/terrain3d/terrain3d_control_codec.gd"
)

const VALID_REGION_SIZES := [64, 128, 256, 512, 1024, 2048]
const DEFAULT_REGION_SIZE := 256
const EPSILON := 0.0001

func build(
	document: AonwMapDocument,
	reference_texture: Texture2D,
	settings: Resource,
) -> Dictionary:
	var samples_per_radius := maxi(1, int(settings.terrain_samples_per_radius))
	var region_size := normalized_region_size(int(settings.terrain3d_region_size))
	var vertex_spacing := float(settings.hex_radius) / float(samples_per_radius)
	if vertex_spacing <= 0.0:
		return _failure("Terrain3D vertex spacing must be greater than zero")

	var projection := HexMapProjection.new(
		document,
		float(settings.hex_radius),
		float(settings.height_step),
	)
	var geometry = projection.geometry()
	var bounds: Rect2 = geometry.bounds()
	var required_width := ceili(bounds.size.x / vertex_spacing) + 1
	var required_height := ceili(bounds.size.y / vertex_spacing) + 1
	var region_columns := _even_region_count(required_width, region_size)
	var region_rows := _even_region_count(required_height, region_size)
	if region_columns > 32 or region_rows > 32:
		return _failure(
			"Terrain3D raster exceeds the supported 32×32 region map: %d×%d"
			% [region_columns, region_rows]
		)
	var image_size := Vector2i(
		region_columns * region_size,
		region_rows * region_size,
	)
	var import_origin := Vector3(
		-float(image_size.x / 2) * vertex_spacing,
		0.0,
		-float(image_size.y / 2) * vertex_spacing,
	)

	var height_map := Image.create(
		image_size.x,
		image_size.y,
		false,
		Image.FORMAT_RF,
	)
	var control_map := Image.create(
		image_size.x,
		image_size.y,
		false,
		Image.FORMAT_RF,
	)
	var color_map := Image.create(
		image_size.x,
		image_size.y,
		false,
		Image.FORMAT_RGBA8,
	)
	height_map.fill(Color(0.0, 0.0, 0.0, 1.0))
	control_map.fill(Color(
		ControlCodec.encode_float(ControlCodec.encode(0, 0, 0, 0, 0, true)),
		0.0,
		0.0,
		1.0,
	))
	color_map.fill(Color(1.0, 1.0, 1.0, 0.5))

	var reference_image: Image = null
	if reference_texture != null:
		reference_image = reference_texture.get_image()
	var texture_projection := MapTextureProjection.new(geometry)
	var tile_surfaces := _build_tile_surfaces(document, projection)
	var valid_sample_count := 0

	for pixel_y in range(image_size.y):
		for pixel_x in range(image_size.x):
			var local_point := Vector2(
				import_origin.x + float(pixel_x) * vertex_spacing,
				import_origin.z + float(pixel_y) * vertex_spacing,
			)
			var coordinate := projection.local_to_hex(Vector3(
				local_point.x,
				0.0,
				local_point.y,
			))
			if coordinate == HexMapProjection.INVALID_HEX:
				continue
			var surface: Dictionary = tile_surfaces.get(coordinate, {})
			if surface.is_empty():
				continue
			var height := _sample_surface_height(surface, local_point)
			if is_nan(height):
				continue

			height_map.set_pixel(pixel_x, pixel_y, Color(height, 0.0, 0.0, 1.0))
			var texture_id := VisualCatalog.texture_id_for(surface["terrains"])
			var control_bits := ControlCodec.encode(texture_id)
			control_map.set_pixel(pixel_x, pixel_y, Color(
				ControlCodec.encode_float(control_bits),
				0.0,
				0.0,
				1.0,
			))
			var color := VisualCatalog.color_for(surface["terrains"])
			color = _blend_reference_color(
				color,
				reference_image,
				texture_projection.normalized_uv(local_point + projection.map_center()),
				bool(settings.reference_visible),
				float(settings.reference_opacity),
			)
			color.a = 0.5
			color_map.set_pixel(pixel_x, pixel_y, color)
			valid_sample_count += 1

	if valid_sample_count == 0:
		return _failure("Terrain3D rasterizer did not cover any logical map samples")

	return {
		"ok": true,
		"height_map": height_map,
		"control_map": control_map,
		"color_map": color_map,
		"image_size": image_size,
		"region_size": region_size,
		"region_count": Vector2i(region_columns, region_rows),
		"vertex_spacing": vertex_spacing,
		"import_origin": import_origin,
		"world_size": bounds.size,
		"maximum_height": float(AonwMapDocument.MAX_HEIGHT) * float(settings.height_step),
		"valid_sample_count": valid_sample_count,
	}

static func normalized_region_size(value: int) -> int:
	return value if value in VALID_REGION_SIZES else DEFAULT_REGION_SIZE

func _even_region_count(required_pixels: int, region_size: int) -> int:
	var count := maxi(2, ceili(float(required_pixels) / float(region_size)))
	return count if count % 2 == 0 else count + 1

func _build_tile_surfaces(
	document: AonwMapDocument,
	projection: AonwHexMapProjection,
) -> Dictionary:
	var result := {}
	for tile in document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var corners: Array[Vector3] = []
		for corner in range(6):
			corners.append(projection.hex_corner(coordinate, corner))
		result[coordinate] = {
			"center": projection.hex_center(coordinate),
			"corners": corners,
			"terrains": tile["terrains"],
		}
	return result

func _sample_surface_height(surface: Dictionary, point: Vector2) -> float:
	var center: Vector3 = surface["center"]
	var corners: Array = surface["corners"]
	for corner in range(6):
		var height := _triangle_height(
			point,
			center,
			corners[corner],
			corners[(corner + 1) % 6],
		)
		if not is_nan(height):
			return height
	return NAN

func _triangle_height(
	point: Vector2,
	first: Vector3,
	second: Vector3,
	third: Vector3,
) -> float:
	var a := Vector2(first.x, first.z)
	var b := Vector2(second.x, second.z)
	var c := Vector2(third.x, third.z)
	var first_edge := b - a
	var second_edge := c - a
	var relative := point - a
	var determinant := first_edge.cross(second_edge)
	if is_zero_approx(determinant):
		return NAN
	var second_weight := relative.cross(second_edge) / determinant
	var third_weight := first_edge.cross(relative) / determinant
	var first_weight := 1.0 - second_weight - third_weight
	if (
		first_weight < -EPSILON
		or second_weight < -EPSILON
		or third_weight < -EPSILON
	):
		return NAN
	return (
		first.y * first_weight
		+ second.y * second_weight
		+ third.y * third_weight
	)

func _blend_reference_color(
	fallback: Color,
	reference_image: Image,
	uv: Vector2,
	visible: bool,
	opacity: float,
) -> Color:
	if (
		not visible
		or opacity <= 0.0
		or reference_image == null
		or reference_image.is_empty()
	):
		return fallback
	var clamped_uv := uv.clamp(Vector2.ZERO, Vector2.ONE)
	var pixel := Vector2i(
		clampi(roundi(clamped_uv.x * float(reference_image.get_width() - 1)), 0, reference_image.get_width() - 1),
		clampi(roundi(clamped_uv.y * float(reference_image.get_height() - 1)), 0, reference_image.get_height() - 1),
	)
	var reference_color := reference_image.get_pixelv(pixel)
	var amount := clampf(reference_color.a * opacity, 0.0, 1.0)
	return fallback.lerp(reference_color, amount)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
