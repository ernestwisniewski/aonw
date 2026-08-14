@tool
class_name AonwAuthoredMapSceneStore
extends RefCounted

const AtomicResourceStore := preload("res://infrastructure/map/atomic_resource_store.gd")
const GENERATED_LAYER_NAMES := [
	&"BaseTerrain",
	&"ReferenceTexture",
	&"HexGrid",
	&"Terrain3DGround",
]

var _atomic_store := AtomicResourceStore.new()

func create(path: String, map_id: String, generated_scene_path: String) -> Error:
	var generated_scene := ResourceLoader.load(
		generated_scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as PackedScene
	if generated_scene == null:
		return ERR_CANT_OPEN
	var surface := generated_scene.instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE
	) as AonwMapSurface
	if surface == null:
		return ERR_CANT_CREATE
	var root := Node3D.new()
	root.name = map_id
	root.add_child(surface)
	surface.owner = root
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = _atomic_store.save_scene(packed, path)
	root.free()
	return error

func refresh(path: String, generated_scene_path: String) -> Error:
	var authored_scene := ResourceLoader.load(
		path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	var generated_scene := ResourceLoader.load(
		generated_scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if authored_scene == null or generated_scene == null:
		return ERR_CANT_OPEN
	var root := authored_scene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var previous_surface := root.get_node_or_null("AonwMap3D")
	if previous_surface == null:
		root.free()
		return ERR_DOES_NOT_EXIST
	var surface_index := previous_surface.get_index()
	var authored_children: Array[Node] = []
	for child in previous_surface.get_children():
		if child.name in GENERATED_LAYER_NAMES:
			continue
		previous_surface.remove_child(child)
		child.owner = null
		authored_children.append(child)
	root.remove_child(previous_surface)
	previous_surface.free()
	var surface := generated_scene.instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE
	) as AonwMapSurface
	if surface == null:
		root.free()
		return ERR_CANT_CREATE
	root.add_child(surface)
	root.move_child(surface, surface_index)
	surface.owner = root
	for child in authored_children:
		surface.add_child(child)
		child.owner = root
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = _atomic_store.save_scene(packed, path)
	root.free()
	return error
