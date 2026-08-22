@tool
class_name AonwMapAuthoringCompositionRoot
extends RefCounted

const MapAssetCatalog := preload(
	"res://editor/map_authoring/infrastructure/map_asset_catalog.gd"
)
const JsonMapRepository := preload(
	"res://game/infrastructure/map/json_map_repository.gd"
)
const TileAtlasRepository := preload(
	"res://game/infrastructure/map/tile_atlas_repository.gd"
)
const ArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const OpenMap := preload("res://game/application/map/open_map.gd")
const AuthoringStore := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd"
)
const AuthoringSession := preload(
	"res://editor/map_authoring/application/terrain_authoring_session.gd"
)
const SceneRepository := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_scene_repository.gd"
)
const SceneFactory := preload(
	"res://editor/map_authoring/presentation/terrain_authoring_scene_factory.gd"
)
const GenerateTerrainAuthoringMap := preload(
	"res://editor/map_authoring/application/generate_terrain_authoring_map.gd"
)
const WorkbenchDock := preload(
	"res://editor/map_authoring/presentation/map_workbench_dock.gd"
)

var _catalog: AonwMapSourceCatalog
var _artifact_reader: AonwTerrainCompiledArtifactRepository
var _scene_writer: AonwTerrainAuthoringSceneRepository
var _generator: AonwGenerateTerrainAuthoringMap

func _init(
	scene_root: String = AonwTerrainAuthoringSceneRepository.SCENE_ROOT,
	authoring_asset_root: String = AonwTerrainAuthoringSceneRepository.AUTHORING_ASSET_ROOT,
	compiled_artifact_root: String = AonwTerrainAuthoringSceneRepository.COMPILED_ARTIFACT_ROOT,
) -> void:
	_catalog = MapAssetCatalog.new()
	_artifact_reader = ArtifactRepository.new(compiled_artifact_root)
	_scene_writer = SceneRepository.new(
		SceneFactory.new(),
		scene_root,
		authoring_asset_root,
		compiled_artifact_root,
	)
	_generator = GenerateTerrainAuthoringMap.new(
		OpenMap.new(
			JsonMapRepository.new(),
			TileAtlasRepository.new(),
			_artifact_reader,
		),
		_scene_writer,
	)

func create_dock() -> Control:
	var dock := WorkbenchDock.new()
	dock.configure(_catalog, _generator, _scene_writer)
	return dock

func generator() -> AonwGenerateTerrainAuthoringMap:
	return _generator

func scene_writer() -> AonwTerrainAuthoringSceneWriter:
	return _scene_writer

func open_scene(scene_root: Node) -> Dictionary:
	if scene_root == null:
		return {"ok": true, "ignored": true}
	var surface := scene_root as AonwTerrainAuthoringSurface
	if surface == null:
		surface = scene_root.find_child(
			"TerrainAuthoring",
			true,
			false,
		) as AonwTerrainAuthoringSurface
	if surface == null:
		return {"ok": true, "ignored": true}
	return await open_surface(surface)

func open_surface(surface: AonwTerrainAuthoringSurface) -> Dictionary:
	if surface.is_session_open():
		return {"ok": true}
	if (
		surface.source_map_id.is_empty()
		or surface.compiled_artifact_directory.is_empty()
		or surface.authoring_root.is_empty()
	):
		return _failure("terrain authoring scene is not configured")
	var terrain := surface.terrain()
	if terrain.data == null and surface.is_inside_tree():
		await surface.get_tree().process_frame
	if terrain.data == null:
		return _failure("Terrain3D data is not ready")
	var artifact_result := _artifact_reader.load_artifact(
		surface.compiled_artifact_directory,
		surface.source_map_id,
	)
	if not artifact_result["ok"]:
		return artifact_result
	var store := AuthoringStore.new(surface.authoring_root)
	var reference_texture := ResourceLoader.load(
		store.reference_texture_path(),
		"Texture2D",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as Texture2D
	if reference_texture == null:
		return _failure("terrain reference texture is missing")
	var artifact: AonwTerrainCompiledArtifact = artifact_result["artifact"]
	var session := AuthoringSession.new(terrain.data, artifact, store)
	return surface.open_session(session, artifact, reference_texture, _artifact_reader)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
