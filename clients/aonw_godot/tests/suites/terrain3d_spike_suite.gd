extends RefCounted

const SPIKE_DIRECTORY := "res://.godot/terrain3d_spike"
const HeightEditor := preload("res://infrastructure/terrain/terrain3d_height_editor.gd")
const SurfaceSampler := preload("res://infrastructure/terrain/terrain3d_surface_sampler.gd")
const MapSource := preload("res://application/map/map_source.gd")
const HexMapProjection := preload("res://presentation/map/hex_map_projection.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")

var _failures: Array[String]
var _terrain: Terrain3D
var _camera: Camera3D

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_required_api()
	if not ClassDB.class_exists("Terrain3D"):
		return
	_prepare_terrain()
	_test_heightmap_formats()
	_test_region_height_editing_and_undo()
	_test_overlays_and_picking()
	_test_region_persistence()
	_dispose_terrain()

func _test_required_api() -> void:
	for required_class in [
		"Terrain3D",
		"Terrain3DData",
		"Terrain3DRegion",
		"Terrain3DUtil",
	]:
		_check(ClassDB.class_exists(required_class), "%s is available" % required_class)

func _prepare_terrain() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPIKE_DIRECTORY))
	_terrain = Terrain3D.new()
	_terrain.vertex_spacing = 1.0
	Engine.get_main_loop().root.add_child(_terrain)
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 20.0, 10.0)
	Engine.get_main_loop().root.add_child(_camera)
	_camera.look_at(Vector3.ZERO)
	_terrain.set_camera(_camera)

func _test_heightmap_formats() -> void:
	var source := Image.create(64, 64, false, Image.FORMAT_RF)
	source.fill(Color(2.0, 0.0, 0.0, 1.0))
	source.set_pixel(32, 32, Color(4.0, 0.0, 0.0, 1.0))
	var source_path := SPIKE_DIRECTORY.path_join("height.exr")
	_check(source.save_exr(source_path) == OK, "32-bit EXR heightmap is written")
	var loaded_exr := Image.load_from_file(source_path)
	_check(
		loaded_exr != null
		and loaded_exr.get_format() == Image.FORMAT_RF
		and is_equal_approx(loaded_exr.get_pixel(32, 32).r, 4.0),
		"32-bit EXR heightmap preserves float heights",
	)
	if loaded_exr == null:
		return
	var images: Array[Image]
	images.resize(Terrain3DRegion.TYPE_MAX)
	images[Terrain3DRegion.TYPE_HEIGHT] = loaded_exr
	_terrain.data.import_images(images, Vector3.ZERO, 1.0, 2.0)
	_check(
		is_equal_approx(_terrain.data.get_height(Vector3.ZERO), 5.0),
		"EXR import applies its explicit offset and scale",
	)

	var export_path := SPIKE_DIRECTORY.path_join("height_export.exr")
	_check(
		_terrain.data.export_image(export_path, Terrain3DRegion.TYPE_HEIGHT) == OK,
		"Terrain3D exports height data to EXR",
	)
	var exported := Image.load_from_file(export_path)
	_check(
		exported != null
		and exported.get_format() in [
			Image.FORMAT_RF,
			Image.FORMAT_RGBF,
			Image.FORMAT_RGBAF,
		],
		"exported EXR remains a 32-bit float image",
	)

	var r16_path := SPIKE_DIRECTORY.path_join("height.r16")
	var r16_file := FileAccess.open(r16_path, FileAccess.WRITE)
	_check(r16_file != null, "R16 fixture can be written")
	if r16_file == null:
		return
	for value in [0, 32768, 65535, 16384]:
		r16_file.store_16(value)
	r16_file.close()
	var loaded_r16 := Terrain3DUtil.load_image(
		r16_path,
		ResourceLoader.CACHE_MODE_IGNORE,
		Vector2(-10.0, 30.0),
		Vector2i(2, 2),
	)
	_check(loaded_r16 != null, "raw R16 heightmap is decoded")
	if loaded_r16 == null:
		return
	_check_approx(loaded_r16.get_pixel(0, 0).r, -10.0, "R16 minimum uses explicit range")
	_check_approx(loaded_r16.get_pixel(1, 0).r, 10.0, "R16 midpoint uses explicit range")
	_check_approx(loaded_r16.get_pixel(0, 1).r, 30.0, "R16 maximum uses explicit range")

func _test_region_height_editing_and_undo() -> void:
	_check(_terrain.data.get_region_count() == 1, "import creates one bounded region")
	var region_locations := _terrain.data.get_region_locations()
	_check(
		region_locations.size() == 1 and region_locations[0] == Vector2i.ZERO,
		"the imported region has an explicit location",
	)
	var region: Terrain3DRegion = _terrain.data.get_region(Vector2i.ZERO)
	_check(region != null, "bounded region can be read")
	if region != null:
		_check(
			region.get_map(Terrain3DRegion.TYPE_HEIGHT).get_size()
				== Vector2i(_terrain.region_size, _terrain.region_size),
			"bounded region owns one height map",
		)

	var editor := HeightEditor.new(_terrain.data, -10.0, 12.0)
	var history := UndoRedo.new()
	var position := Vector3.ZERO
	var previous_height := editor.height_at(position)
	_check(
		editor.change_height(history, position, 100.0),
		"height edit records an undoable action",
	)
	_check_approx(editor.height_at(position), 12.0, "height writes enforce the maximum")
	history.undo()
	_check_approx(editor.height_at(position), previous_height, "height edit can be undone")
	history.redo()
	_check_approx(editor.height_at(position), 12.0, "height edit can be redone")
	_check_approx(editor.set_height(position, -100.0), -10.0, "height writes enforce the minimum")
	history.clear_history(false)
	history.free()

func _test_overlays_and_picking() -> void:
	var map_result: Dictionary = JsonMapRepository.new().load_map(MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	))
	_check(map_result["ok"], "terrain alignment fixture map opens")
	if not map_result["ok"]:
		return
	var projection := HexMapProjection.new(map_result["document"], 1.0, 0.16)
	var coordinate := Vector2i(4, 4)
	var logical_center: Vector3 = projection.hex_center(coordinate)
	var sample_position := Vector3(
		roundf(logical_center.x),
		0.0,
		roundf(logical_center.z),
	)
	var editor := HeightEditor.new(_terrain.data, -10.0, 12.0)
	editor.set_height(sample_position, 8.0)
	var surface := SurfaceSampler.new(_terrain)
	var reference_position := surface.align(sample_position, 0.02)
	var grid_position := surface.align(sample_position, 0.04)
	_check_approx(reference_position.y, 8.02, "reference overlay follows deformation")
	_check_approx(grid_position.y, 8.04, "grid overlay follows deformation independently")

	var intersection := surface.intersect(
		sample_position + Vector3(0.0, 20.0, 0.0),
		Vector3.DOWN,
	)
	_check(intersection.is_finite(), "deformed terrain ray has an intersection")
	if intersection.is_finite():
		_check_approx(intersection.y, 8.0, "picking returns the deformed surface height")
		_check(
			projection.local_to_hex(intersection) == coordinate,
			"deformed Terrain3D picking resolves the logical hex",
		)

func _test_region_persistence() -> void:
	var data_directory := SPIKE_DIRECTORY.path_join("data")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(data_directory))
	_terrain.data.save_directory(data_directory)
	_check(
		FileAccess.file_exists(data_directory.path_join("terrain3d_00_00.res")),
		"bounded Terrain3D region is persisted",
	)
	var restored := Terrain3D.new()
	restored.vertex_spacing = 1.0
	Engine.get_main_loop().root.add_child(restored)
	restored.data.load_directory(data_directory)
	_check(restored.data.get_region_count() == 1, "persisted region is restored")
	_check_approx(
		restored.data.get_height(Vector3.ZERO),
		_terrain.data.get_height(Vector3.ZERO),
		"restored region preserves edited heights",
	)
	restored.free()

func _dispose_terrain() -> void:
	_camera.free()
	_terrain.free()

func _check_approx(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) <= 0.001, "%s (%s != %s)" % [message, actual, expected])

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
