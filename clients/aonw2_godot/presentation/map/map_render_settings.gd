@tool
class_name AonwMapRenderSettings
extends Resource

enum TerrainBackend {
	LEGACY_MESH = 0,
	TERRAIN_3D = 1,
}

const FORMAT_VERSION := 2
const VALID_REGION_SIZES := [64, 128, 256, 512, 1024, 2048]

@export_range(0.25, 4.0, 0.05) var hex_radius := 1.0:
	set(value):
		hex_radius = clampf(value, 0.25, 4.0)
		emit_changed()
@export_range(0.0, 1.0, 0.01) var height_step := 0.16:
	set(value):
		height_step = clampf(value, 0.0, 1.0)
		emit_changed()
@export_enum("Legacy mesh:0", "Terrain3D:1") var terrain_backend := TerrainBackend.LEGACY_MESH:
	set(value):
		terrain_backend = clampi(int(value), TerrainBackend.LEGACY_MESH, TerrainBackend.TERRAIN_3D)
		emit_changed()
@export_range(2, 16, 1) var terrain_samples_per_radius := 8:
	set(value):
		terrain_samples_per_radius = clampi(int(value), 2, 16)
		emit_changed()
@export_enum("64:64", "128:128", "256:256", "512:512", "1024:1024", "2048:2048")
var terrain3d_region_size := 256:
	set(value):
		terrain3d_region_size = int(value) if int(value) in VALID_REGION_SIZES else 256
		emit_changed()
@export var reference_visible := true:
	set(value):
		reference_visible = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var reference_opacity := 1.0:
	set(value):
		reference_opacity = clampf(value, 0.0, 1.0)
		emit_changed()
@export var grid_visible := true:
	set(value):
		grid_visible = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var grid_opacity := 0.72:
	set(value):
		grid_opacity = clampf(value, 0.0, 1.0)
		emit_changed()
@export_range(0.01, 0.12, 0.005) var grid_width := 0.04:
	set(value):
		grid_width = clampf(value, 0.01, 0.12)
		emit_changed()

static func from_dictionary(value: Dictionary) -> AonwMapRenderSettings:
	var settings := AonwMapRenderSettings.new()
	settings.hex_radius = float(_read(value, "hex_radius", "hexRadius", 1.0))
	settings.height_step = float(_read(value, "height_step", "heightStep", 0.16))
	settings.terrain_backend = _backend_from_value(
		_read(value, "terrain_backend", "terrainBackend", TerrainBackend.LEGACY_MESH)
	)
	settings.terrain_samples_per_radius = int(_read(
		value,
		"terrain_samples_per_radius",
		"terrainSamplesPerRadius",
		8,
	))
	settings.terrain3d_region_size = int(_read(
		value,
		"terrain3d_region_size",
		"terrain3dRegionSize",
		256,
	))
	settings.reference_visible = bool(_read(
		value,
		"reference_visible",
		"referenceVisible",
		true,
	))
	settings.reference_opacity = float(_read(
		value,
		"reference_opacity",
		"referenceOpacity",
		1.0,
	))
	settings.grid_visible = bool(_read(value, "grid_visible", "gridVisible", true))
	settings.grid_opacity = float(_read(value, "grid_opacity", "gridOpacity", 0.72))
	settings.grid_width = float(_read(value, "grid_width", "gridWidth", 0.04))
	return settings

func snapshot() -> AonwMapRenderSettings:
	return duplicate(true) as AonwMapRenderSettings

func to_dictionary() -> Dictionary:
	return {
		"formatVersion": FORMAT_VERSION,
		"hexRadius": hex_radius,
		"heightStep": height_step,
		"terrainBackend": terrain_backend_name(),
		"terrainSamplesPerRadius": terrain_samples_per_radius,
		"terrain3dRegionSize": terrain3d_region_size,
		"referenceVisible": reference_visible,
		"referenceOpacity": reference_opacity,
		"gridVisible": grid_visible,
		"gridOpacity": grid_opacity,
		"gridWidth": grid_width,
	}

func terrain_backend_name() -> String:
	return "terrain3d" if terrain_backend == TerrainBackend.TERRAIN_3D else "legacyMesh"

func equals(other: AonwMapRenderSettings) -> bool:
	return (
		other != null
		and is_equal_approx(hex_radius, other.hex_radius)
		and is_equal_approx(height_step, other.height_step)
		and terrain_backend == other.terrain_backend
		and terrain_samples_per_radius == other.terrain_samples_per_radius
		and terrain3d_region_size == other.terrain3d_region_size
		and reference_visible == other.reference_visible
		and is_equal_approx(reference_opacity, other.reference_opacity)
		and grid_visible == other.grid_visible
		and is_equal_approx(grid_opacity, other.grid_opacity)
		and is_equal_approx(grid_width, other.grid_width)
	)

static func _read(
	value: Dictionary,
	snake_case_key: String,
	camel_case_key: String,
	fallback: Variant,
) -> Variant:
	if value.has(snake_case_key):
		return value[snake_case_key]
	return value.get(camel_case_key, fallback)

static func _backend_from_value(value: Variant) -> int:
	if value is String:
		var normalized := String(value).to_lower()
		if normalized in ["terrain3d", "terrain_3d", "terrain-3d"]:
			return TerrainBackend.TERRAIN_3D
		return TerrainBackend.LEGACY_MESH
	return clampi(int(value), TerrainBackend.LEGACY_MESH, TerrainBackend.TERRAIN_3D)
