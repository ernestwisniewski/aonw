@tool
class_name AonwTerrainAuthoringPresentationSceneFactory
extends AonwTerrainAuthoringSceneFactory

const AuthoringSurface := preload(
	"res://editor/map_authoring/presentation/terrain_authoring_surface.gd"
)

func create_scene(
	map_id: String,
	compiled_artifact_directory: String,
	authoring_root: String,
	existing_scene: PackedScene = null,
) -> PackedScene:
	var root := (
		existing_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		if existing_scene != null
		else Node3D.new()
	) as Node3D
	if root == null:
		return null
	if existing_scene == null:
		root.name = map_id
	var surface := AuthoringSurface.new()
	surface.name = "TerrainAuthoring"
	surface.configure(map_id, compiled_artifact_directory, authoring_root)
	root.add_child(surface)
	surface.owner = root
	surface.assign_generated_owners(root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		packed = null
	root.free()
	return packed
