class_name TerrainGenerator
extends Node3D

@export var chunk_size = 64
@export var terrain_height = 20
@export_range(64, 2048, 64) var view_dist = 128
var viewer: CharacterBody3D
@export var noise: FastNoiseLite
@export var render_debug := false
@export var material: Material
@export var tree_scene: PackedScene
@export var stone_scenes: Array[PackedScene]
@export var player_scene: PackedScene
var viewer_pos = Vector2()
var chunks = {}
var chunk_visible = 0
var last_visible_chunks = []
var save_dir_name = ""
var player_count = 1
var players = {}
var world_name: String = "Hekss."
var lfd := true

func _ready():
	view_dist = Settings.render_distance
	chunk_visible = roundi(view_dist / chunk_size)
	if GManager.new_world == false:
		noise.seed = GManager.curr_world_data.world_data.seed
		save_dir_name = GManager.curr_save_dir
		world_name = GManager.curr_world_data.world_data.name
	else:
		noise.seed = GManager.new_world_seed
		save_dir_name = ""
		world_name = GManager.new_world_name
	seed(noise.seed)
	for i in player_count:
		var curr_player = player_scene.instantiate()
		curr_player.name = "tst"
		curr_player.unique_id = Settings.unique_id
		add_child(curr_player)
		curr_player.position.y += 5
		players[Settings.unique_id] = curr_player
		viewer = curr_player
	if GManager.new_world == true:
		lfd = false
		update_visible_chunk()
	else:
		lfd = true
		load_data()

func load_data():
	var data = GManager.curr_world_data
	var c_datas = data.chunks
	for chunk in c_datas:
		var new_chunk = TerrainChunk.new(material, stone_scenes)
		var vcc = c_datas[chunk].c_coord / chunk_size
		new_chunk.max_terrain_h = terrain_height
		add_child(new_chunk)
		new_chunk.global_position = c_datas[chunk].pos
		new_chunk.gen_mesh(vcc, noise, chunk_size, false, true)
		chunks[vcc] = new_chunk
		new_chunk.load_datas(c_datas[chunk].trees, c_datas[chunk].stones, c_datas[chunk].objects)
	for player in data.players:
		players[player].position = data.players[player]
	update_visible_chunk()

func update_visible_chunk():
	for chunk in last_visible_chunks:
		chunk.set_chunk_visible(false)
	last_visible_chunks.clear()
	var curr_x = roundi(viewer_pos.x / chunk_size)
	var curr_y = roundi(viewer_pos.y / chunk_size)
	for y_offset in range(-chunk_visible, chunk_visible):
		for x_offset in range(-chunk_visible, chunk_visible):
			var view_chunk_coord = Vector2(curr_x - x_offset, curr_y - y_offset)
			if chunks.has(view_chunk_coord):
				chunks[view_chunk_coord].update_chunk(viewer_pos, view_dist)
				if chunks[view_chunk_coord].update_lod(viewer_pos):
					chunks[view_chunk_coord].gen_mesh(view_chunk_coord, noise, chunk_size, true, lfd)
				if chunks[view_chunk_coord].visible: last_visible_chunks.append(chunks[view_chunk_coord])
			else:
				var chunk = TerrainChunk.new(material, stone_scenes)
				chunk.max_terrain_h = terrain_height
				add_child(chunk)
				var pos = view_chunk_coord * chunk_size
				var world_pos = Vector3(pos.x, 0, pos.y)
				chunk.global_position = world_pos
				chunk.gen_mesh(view_chunk_coord, noise, chunk_size, false, false)
				chunks[view_chunk_coord] = chunk

func save_games():
	#Logic...
	save_world()
	for node in players:
		players[node].get_back()

func save_world():
	var saved_chunks = {}
	var i = 0
	for i_c in chunks:
		var chunk_dat = chunks[i_c].get_saves()
		saved_chunks["chunk%d" % i] = {
			"pos": chunks[i_c].global_position,
			"trees": chunk_dat[0],
			"stones": chunk_dat[1],
			"objects": chunk_dat[2],
			"c_coord": chunk_dat[3]
		}
		i += 1
	var loc_players = {}
	for player in players:
		loc_players[player] = players[player].position
	var saves = {
		"world_data": {"name": world_name, "seed": noise.seed},
		"chunks": saved_chunks,
		"players": loc_players
	}
	if save_dir_name == "": save_dir_name = str(randi() % 2_000_000 + 1)
	FileSystem.mkdir("world/" + save_dir_name, true)
	FileSystem.ch_dir("world/" + save_dir_name)
	FileSystem.write("world.dat", saves)
	get_viewport().get_texture().get_image().save_png(FileSystem.opened_path + "/tmb.png")
	FileSystem.ch_dir(FileSystem.base_path)

func _exit_tree():
	for child in get_children(): child.queue_free()

func process():
	viewer_pos.x = viewer.position.x
	viewer_pos.y = viewer.position.z
	update_visible_chunk()

func scene_autosave():
	pass#save_chunks()
