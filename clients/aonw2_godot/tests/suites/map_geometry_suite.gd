extends RefCounted

const MapSource := preload("res://application/map/map_source.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const HexGridGeometry := preload("res://presentation/map/geometry/hex_grid_geometry.gd")
const HexMapProjection := preload("res://presentation/map/hex_map_projection.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const RenderSettings := preload("res://presentation/map/map_render_settings.gd")
const Terrain3DRasterizer := preload(
	"res://presentation/map/terrain3d/terrain3d_map_rasterizer.gd"
)
const Terrain3DControlCodec := preload(
	"res://presentation/map/terrain3d/terrain3d_control_codec.gd"
)
const TerrainVisualCatalog := preload(
	"res://presentation/map/terrain/terrain_visual_catalog.gd"
)

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_geometry()
	_test_map_projection()
	_test_render_settings_round_trip()
	_test_terrain3d_control_codec()
	_test_terrain3d_rasterizer()

func _test_geometry() -> void:
	var geometry := HexGridGeometry.new(25, 19)
	_check(
		geometry.corner_key(Vector2i(0, 0), 0) == geometry.corner_key(Vector2i(1, 0), 4)
		and geometry.corner_key(Vector2i(0, 0), 1) == geometry.corner_key(Vector2i(1, 0), 3),
		"adjacent odd-q hexes share exact corner keys",
	)
	var map_bounds := geometry.bounds().grow(0.001)
	for col in geometry.cols:
		for row in geometry.rows:
			var coordinate := Vector2i(col, row)
			_check(
				geometry.tile_at_point(geometry.tile_center(coordinate)) == coordinate,
				"world-to-hex round-trip preserves tile centers",
			)
			for corner in 6:
				_check(
					map_bounds.has_point(geometry.corner_position(coordinate, corner)),
					"map bounds contain every corner",
				)

func _test_map_projection() -> void:
	var result: Dictionary = _open_map().execute(MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	))
	_check(result["ok"], "projection fixture map opens")
	if not result["ok"]:
		return
	var document = result["document"]
	var projection := HexMapProjection.new(document, 1.0, 0.16)
	for coordinate in [Vector2i(0, 0), Vector2i(2, 3), Vector2i(4, 4)]:
		var center: Vector3 = projection.hex_center(coordinate)
		_check(
			projection.local_to_hex(center) == coordinate,
			"render projection preserves hex centers",
		)
		var picked := projection.ray_to_hex(
			center + Vector3(0.0, 10.0, 0.0),
			Vector3.DOWN,
		)
		_check(picked == coordinate, "vertical ray selects the expected hex")
	var slope_coordinate := Vector2i(4, 5)
	var slope_target := projection.hex_center(slope_coordinate).lerp(
		projection.hex_corner(slope_coordinate, 0),
		0.6,
	)
	var slope_origin := slope_target + Vector3(0.2, 5.0, 0.2)
	_check(
		projection.ray_to_hex(
			slope_origin,
			(slope_target - slope_origin).normalized(),
		) == slope_coordinate,
		"angled ray follows the rendered slope triangles",
	)
	_check(
		projection.ray_to_hex(Vector3.ZERO, Vector3.ZERO) == HexMapProjection.INVALID_HEX,
		"zero-length ray does not select a hex",
	)

func _test_render_settings_round_trip() -> void:
	var settings := RenderSettings.new()
	settings.height_step = 0.31
	settings.terrain_backend = RenderSettings.TerrainBackend.TERRAIN_3D
	settings.terrain_samples_per_radius = 6
	settings.terrain3d_region_size = 128
	settings.reference_visible = false
	settings.reference_opacity = 0.42
	settings.grid_visible = false
	settings.grid_opacity = 0.27
	settings.grid_width = 0.075
	var restored := RenderSettings.from_dictionary(settings.to_dictionary())
	_check(settings.equals(restored), "render settings survive manifest round-trip")
	var legacy := RenderSettings.from_dictionary({"height_step": 0.2})
	_check(
		legacy.terrain_backend == RenderSettings.TerrainBackend.LEGACY_MESH,
		"old render settings default to the legacy backend",
	)

func _test_terrain3d_control_codec() -> void:
	var bits := Terrain3DControlCodec.encode(
		6,
		4,
		127,
		3,
		2,
		false,
		true,
		true,
	)
	var packed := Terrain3DControlCodec.encode_float(bits)
	var decoded := Terrain3DControlCodec.decode_float(packed)
	_check(decoded == bits, "Terrain3D control bits survive float packing")
	_check(
		Terrain3DControlCodec.base_texture_id(decoded) == 6
		and Terrain3DControlCodec.overlay_texture_id(decoded) == 4,
		"Terrain3D codec retains base and overlay texture ids",
	)
	_check(
		Terrain3DControlCodec.blend_value(decoded) == 127
		and Terrain3DControlCodec.angle_value(decoded) == 3
		and Terrain3DControlCodec.scale_value(decoded) == 2,
		"Terrain3D codec retains blend and UV fields",
	)
	_check(
		not Terrain3DControlCodec.is_hole(decoded)
		and Terrain3DControlCodec.has_navigation(decoded)
		and Terrain3DControlCodec.uses_autoshader(decoded),
		"Terrain3D codec retains control flags",
	)
	_check(
		Terrain3DControlCodec.is_hole(
			Terrain3DControlCodec.encode(0, 0, 0, 0, 0, true)
		),
		"Terrain3D codec marks samples outside the map as holes",
	)

func _test_terrain3d_rasterizer() -> void:
	var result: Dictionary = _open_map().execute(MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	))
	_check(result["ok"], "Terrain3D rasterizer fixture map opens")
	if not result["ok"]:
		return
	var settings := RenderSettings.new()
	settings.terrain_backend = RenderSettings.TerrainBackend.TERRAIN_3D
	settings.terrain_samples_per_radius = 4
	settings.terrain3d_region_size = 64
	settings.reference_visible = false
	var artifact := Terrain3DRasterizer.new().build(
		result["document"],
		result["reference_texture"],
		settings,
	)
	_check(artifact["ok"], "Terrain3D rasterizer creates map images")
	if not artifact["ok"]:
		return
	var image_size: Vector2i = artifact["image_size"]
	_check(
		image_size.x % settings.terrain3d_region_size == 0
		and image_size.y % settings.terrain3d_region_size == 0,
		"Terrain3D images are aligned to complete regions",
	)
	var region_count: Vector2i = artifact["region_count"]
	_check(
		region_count.x % 2 == 0 and region_count.y % 2 == 0,
		"Terrain3D uses an even region count around the map origin",
	)
	_check(
		int(artifact["valid_sample_count"]) > result["document"].tiles().size(),
		"Terrain3D raster contains multiple samples per logical hex",
	)
	var height_map: Image = artifact["height_map"]
	var control_map: Image = artifact["control_map"]
	var color_map: Image = artifact["color_map"]
	_check(height_map.get_format() == Image.FORMAT_RF, "height map preserves float precision")
	_check(control_map.get_format() == Image.FORMAT_RF, "control map preserves packed bits")
	_check(color_map.get_format() == Image.FORMAT_RGBA8, "color map uses RGBA8")

	var outside_bits := Terrain3DControlCodec.decode_float(control_map.get_pixel(0, 0).r)
	_check(
		Terrain3DControlCodec.is_hole(outside_bits),
		"pixels outside the logical map are Terrain3D holes",
	)

	var coordinate := Vector2i(4, 5)
	var projection := HexMapProjection.new(
		result["document"],
		settings.hex_radius,
		settings.height_step,
	)
	var center := projection.hex_center(coordinate)
	var origin: Vector3 = artifact["import_origin"]
	var spacing: float = artifact["vertex_spacing"]
	var pixel := Vector2i(
		roundi((center.x - origin.x) / spacing),
		roundi((center.z - origin.z) / spacing),
	)
	var sampled_height := height_map.get_pixelv(pixel).r
	_check(
		absf(sampled_height - center.y) <= settings.height_step,
		"Terrain3D height samples follow the legacy hex surface",
	)
	var center_bits := Terrain3DControlCodec.decode_float(control_map.get_pixelv(pixel).r)
	_check(
		not Terrain3DControlCodec.is_hole(center_bits),
		"logical hex centers remain active terrain",
	)
	var expected_texture_id := TerrainVisualCatalog.texture_id_for(
		result["document"].tile_at(coordinate)["terrains"]
	)
	_check(
		Terrain3DControlCodec.base_texture_id(center_bits) == expected_texture_id,
		"Terrain3D control map keeps stable visual texture ids",
	)
	_check(
		absf(color_map.get_pixelv(pixel).a - 0.5) <= 0.01,
		"Terrain3D color map stores neutral roughness",
	)

	var repeated := Terrain3DRasterizer.new().build(
		result["document"],
		result["reference_texture"],
		settings,
	)
	_check(repeated["ok"], "Terrain3D rasterization can be repeated")
	if repeated["ok"]:
		var repeated_height: Image = repeated["height_map"]
		var repeated_control: Image = repeated["control_map"]
		var repeated_color: Image = repeated["color_map"]
		_check(
			height_map.get_data() == repeated_height.get_data()
			and control_map.get_data() == repeated_control.get_data()
			and color_map.get_data() == repeated_color.get_data(),
			"Terrain3D rasterization is deterministic",
		)

func _open_map():
	return OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
