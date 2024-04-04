class_name TerrainChunk
extends MeshInstance3D

const tree_scene = preload("res://scene/INF_Terrain/tree.tscn")

var resolution: int
var max_terrain_h: int
var chunk_size
var lods = [2, 4, 8]
var lods_dist = [896, 512, 386]
var coord = Vector2()
var set_colls = false
var tree_percentage: int
var vertexes = []
var was_ready: bool = false
var tree_loaded = false
var object_count
var stone_scenes : Array[PackedScene]
const ctr_offset = 0.5

#objects in chunk
var trees = []
var stones = []
var o_objs = []


enum StoneType {
	none = -1,
	first = 0,
	second = 1,
	third = 2
}

func _init(mat, stones2):
	material_override = mat
	stone_scenes = stones2

func _ready():
	lods = Settings.lods
	lods_dist = Settings.lods_dist
	object_count = randi_range(1, 5)
	set_process(false)
	set_physics_process(false)

func _complete_load():
	if tree_loaded == false and vertexes.is_empty() == false: _init_object()

func gen_mesh(pos: Vector2, noise: FastNoiseLite, size: float, init_visible: bool, load_from_data: bool):
	var arr_mesh : ArrayMesh
	var surf_tool = SurfaceTool.new()
	chunk_size = size
	coord = pos * size
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in resolution + 1:
		for x in resolution + 1:
			var percent = Vector2(x, z) / resolution
			var point_on_mesh = Vector3((percent.x - ctr_offset), 0, (percent.y - ctr_offset))
			var vertex = point_on_mesh * size
			vertex.y = noise.get_noise_2d(position.x + vertex.x, position.z + vertex.z) * max_terrain_h
			if is_nan(vertex.y): break
			var uv = Vector2()
			uv.x = percent.x
			uv.y = percent.y
			surf_tool.set_uv(uv)
			surf_tool.add_vertex(vertex)
			if vertexes.has(vertex) == false:
				vertexes.append(vertex)
	var vert = 0
	for z in resolution:
		for x in resolution:
			surf_tool.add_index(vert)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 1)
			surf_tool.add_index(vert  + resolution + 1)
			surf_tool.add_index(vert + 1)
			surf_tool.add_index(vert + resolution + 2)
			vert += 1
		vert += 1
	surf_tool.generate_normals()
	arr_mesh = surf_tool.commit()
	mesh = arr_mesh
	if set_colls: create_colls()
	set_chunk_visible(init_visible)
	seed(noise.seed)
	if !load_from_data: _complete_load()

func load_datas(trees2, stones2, objs2):
	for tree in trees2:
		_spawn_tree(trees2[tree].pos, trees2[tree].height, trees2[tree].valid)
	for stone in stones2:
		_spawn_stone(stones2[stone].pos, stones2[stone].type)
	for obj in objs2:
		place_object(objs2[obj].pos, objs2[obj].type)
	pass

func update_lod(view_pos: Vector2):
	var viewer_dist = coord.distance_to(view_pos)
	var update = false
	var new_lod = lods[0]
	for i in range(lods.size()):
		if viewer_dist < lods_dist[i]: new_lod = lods[i]
	if new_lod >= lods[lods.size() - 1]: set_colls = true
	else: set_colls = false
	if resolution != new_lod:
		resolution = new_lod
		update = true
	return update

func update_chunk(view_pos: Vector2, max_dist):
	var viewer_dist = coord.distance_to(view_pos)
	var is_visib = viewer_dist <= (max_dist * 1.25)
	set_chunk_visible(is_visib)

func create_colls():
	if has_node("StaticBody3D"): get_node("StaticBody3D").free()
	create_trimesh_collision()

func set_chunk_visible(visib: bool):
	if visib == true: _show()
	else: _hide()

func _init_object():
	vertexes.shuffle()
	for i in object_count: _spawn_tree(vertexes[i])
	vertexes.shuffle()
	vertexes.shuffle()
	object_count = randi_range(1, 3)
	for i in object_count: _spawn_stone(vertexes[i])
	tree_loaded = true

func get_saves():
	var loc_trees = {}
	var loc_stones = {}
	var loc_objs = {}
	var i = 0
	for tree in trees:
		if !is_instance_valid(tree): continue
		loc_trees[i] = {"pos": tree.position, "height": tree.wood_count, "valid": tree.valid}
		i += 1
	i = 0
	for stone in stones:
		if !is_instance_valid(stone): continue
		loc_stones[i] = {"pos": stone.position, "type": stone.stone_type}
		i += 1
	i = 0
	for obj in o_objs:
		if !is_instance_valid(obj): continue
		loc_objs[i] = {"pos": obj.global_position, "type": obj.type}
		i += 1
	return [loc_trees, loc_stones, loc_objs, coord]

func _spawn_tree(spawn_pos: Vector3, height: int = 0, valid: bool = true) -> void:
	var new_tree = tree_scene.instantiate()
	new_tree.wood_count = randi_range(2, 6) if height == 0 else height
	new_tree.valid = valid
	add_child(new_tree)
	new_tree.position = spawn_pos
	trees.append(new_tree)

func _spawn_stone(pos: Vector3, type = -1):
	var new_stone = stone_scenes.pick_random().instantiate() if type == -1 else stone_scenes[type].instantiate()
	add_child(new_stone)
	new_stone.position = pos
	new_stone.position.y -= 0.25
	stones.append(new_stone)

func _show():
	visible = true
	for i in get_children(): i.visible = true

func _hide():
	visible = false
	for i in get_children(): i.visible = false

func place_object(glob_pos: Vector3, obj_type: GManager.ObjType):
	var new_obj = GManager.objects[obj_type].instantiate()
	add_child(new_obj)
	new_obj.global_position = glob_pos
	o_objs.append(new_obj)
