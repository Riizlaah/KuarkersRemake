extends ColorRect

@onready var server_list = $Mcont/Hbox/Vbox/Scont/ServerList
@onready var player_list = $Mcont/Hbox/Scont2/PlayerList
@onready var play = $Mcont/Hbox/Vbox2/Button4
@onready var timer = $Timer
@onready var worlds = $Mcont/Hbox/Vbox2/Scont/Worlds
@onready var cwm = $"../../CWM"
@onready var ewm = $"../../EWM"
@onready var cwn = $"../../CWM/Panel/Mcont/Hbox/Vbox/WorldName"
@onready var ewn = $"../../EWM/Panel/Mcont/Hbox/Vbox/WorldName"
@onready var seed_input = $"../../CWM/Panel/Mcont/Hbox/Vbox/Hbox/Seed"
@onready var refresh = $Mcont/Hbox/Vbox/Refresh
@onready var wref = $Mcont/Hbox/Vbox2/Hbox/Refresh

@export var server_i: PackedScene
@export var player_i: PackedScene
@export var world_if_s: PackedScene

const lt_port = 8082
const br_port = 8083
const main_scene = "res://scene/main.tscn"
const world_scene = "res://scene/INF_Terrain/inf_terrain.tscn"

var cw_ed: HBoxContainer
var lt_peer = PacketPeerUDP.new()
var br_peer
var server_info: Dictionary
var iface_name
var multicast_addr: String = "224.0.0.1"
var ip_addr
var port

func _ready():
	iface_name = IP.get_local_interfaces()[0].name
	var label = $"../../Label"
	label.hide()
	ip_addr = IP.get_local_addresses()[0]
	port = randi_range(8085, 9990)
	var err = lt_peer.bind(lt_port)
	lt_peer.join_multicast_group(multicast_addr, iface_name)
	if err != OK: label.show()
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	load_worlds()

func load_worlds(wait: bool = false):
	for i in worlds.get_children(): i.queue_free()
	if wait == true: await get_tree().create_timer(0.5).timeout
	var datas = FileSystem.get_worlds_data()
	for data in datas:
		var new_w_if = world_if_s.instantiate()
		new_w_if.parse_data(data)
		worlds.add_child(new_w_if)
		new_w_if.world_pressed.connect(_load_world)
		new_w_if.edit_pressed.connect(world_edited)

func _connected_to_server():
	_toggle_menu(true)
	_send_info.rpc_id(1, Settings.player_name, Settings.unique_id, multiplayer.get_unique_id())
	get_world_info.rpc_id(1)

func _connection_failed():
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(main_scene)

func _peer_connected(_id):
	await get_tree().create_timer(0.15).timeout
	_refresh_list()

func _refresh_list():
	for node in player_list.get_children(): node.queue_free()
	for i in GManager.players:
		var new_player = player_i.instantiate()
		player_list.add_child(new_player)
		if i == 1: new_player.text = GManager.players[i].name + " [host]"
		else: new_player.text = GManager.players[i].name
		if i == multiplayer.get_unique_id(): new_player.text = new_player.text + " [kamu]"

func _peer_disconnected(id):
	GManager.players.erase(id)
	_refresh_list()

func _server_disconnected():
	GManager.players.clear()
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(main_scene)

func _load_world(data, save_dir: String):
	GManager.curr_world_data = data
	GManager.curr_save_dir = save_dir
	setup_games()

func _on_create_pressed():
	_randomize_seed()
	cwm.show()

func setup_games():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port)
	if err != OK:
		OS.alert('Gagal membuat server...', 'Peringatan')
		get_tree().change_scene_to_file(main_scene)
		return
	multiplayer.set_multiplayer_peer(peer)
	_send_info(Settings.player_name, Settings.unique_id, 1)
	_refresh_list()
	_toggle_menu(true)
	play.show()
	_broadcast()

func _toggle_menu(show_menu : bool):
	if show_menu == true:
		for node in get_tree().get_nodes_in_group("info_menu"):
			node.hide()
		for node in get_tree().get_nodes_in_group("wait_menu"):
			node.show()
	else:
		for node in get_tree().get_nodes_in_group("info_menu"):
			node.show()
		for node in get_tree().get_nodes_in_group("wait_menu"):
			node.hide()

func _on_quit_pressed():
	if multiplayer.is_server():
		multiplayer.server_disconnected.emit()
		return
	_toggle_menu(false)
	play.hide()
	GManager.players.clear()
	multiplayer.peer_disconnected.emit(multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = null

func _broadcast():
	br_peer = PacketPeerUDP.new()
	var err = br_peer.bind(br_port)
	if err != OK:
		OS.alert("Error tidak bisa broadcast")
		get_tree().change_scene_to_file(main_scene)
		return
	br_peer.set_broadcast_enabled(true)
	br_peer.set_dest_address(multicast_addr, lt_port)
	timer.start()

func _on_br_out():
	server_info.name = Settings.player_name + " Server"
	server_info.port = port
	server_info.count = GManager.players.size()
	server_info.ip = ip_addr
	var data = (JSON.stringify(server_info)).to_ascii_buffer()
	br_peer.put_packet(data)

@rpc("any_peer")
func _send_info(nama, uniqid, id):
	if !GManager.players.has(id):
		GManager.players[id] = {
			'name': nama,
			'uniqid': uniqid
		}
	if multiplayer.is_server():
		GManager.players = make_uniq_name(GManager.players)
		for i in GManager.players:
			if id != 1: _send_info.rpc(GManager.players[i].name, GManager.players[i].uniqid, i)

@rpc("any_peer", "reliable")
func get_world_info():
	if multiplayer.is_server():
		for i in GManager.players:
			if i != 1: send_world_info.rpc_id(i, GManager.curr_world_data)

@rpc("any_peer", "reliable")
func send_world_info(data):
	GManager.curr_world_data = data

func _join_server(ip: String, port2: int):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port2)
	if err != OK:
		OS.alert('Gagal bergabung...', 'Peringatan')
		get_tree().change_scene_to_file(main_scene)
		return
	multiplayer.set_multiplayer_peer(peer)

func _process(_delta):
	if lt_peer.get_available_packet_count() > 0:
		var packet = JSON.parse_string((lt_peer.get_packet()).get_string_from_ascii())
		var server_node = server_list.get_node_or_null(packet.ip.replace('.', '_'))
		if is_instance_valid(server_node) == false:
			var new_server = server_i.instantiate()
			new_server.name = packet.ip
			server_list.add_child(new_server)
			new_server.ip = packet.ip
			new_server.port = packet.port
			new_server.text = "-- " + packet.name + " --\nPemain : " + str(packet.count)
			new_server.ServerPressed.connect(_join_server)
			return
		server_node.text = "-- " + packet.name + " --\nPemain : " + str(packet.count)

func _on_refresh():
	refresh.disabled = true
	for node in server_list.get_children(): node.queue_free()
	await get_tree().create_timer(0.5).timeout
	refresh.disabled = false

func _exit_tree():
	timer.stop()
	lt_peer.close()
	if br_peer != null: br_peer.close()

func make_uniq_name(dict: Dictionary):
	var not_dup = [""]
	var count = 1
	for i in dict:
		var val = dict[i].name
		if val in not_dup:
			dict[i].name = "%s-%d" % [val, count]
			count += 1
		else: not_dup.append(val)
	return dict

@rpc("any_peer", "call_local")
func start_locally():
	get_tree().change_scene_to_file(world_scene)

func _start_game():
	start_locally.rpc()

func _on_cancel_wm_pressed():
	cwm.hide()
	ewm.hide()
	seed_input.text = ""
	cwn.text = ""

func _on_wm_submit():
	var w_name = cwn.text if cwn.text != "" else "Hekss."
	var w_seed = seed_input.text.to_int() if seed_input.text != "" else str(randi())
	GManager.new_world = true
	GManager.new_world_name = w_name
	GManager.new_world_seed = w_seed
	get_tree().change_scene_to_file(world_scene)

func _randomize_seed():
	seed_input.text = str(randi())

func _on_seed_input_changed(new_text: String):
	if !new_text.is_valid_int():
		var arr = Array(new_text.split())
		for i in arr:
			if i in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']:
				continue
			else:
				arr.erase(i)
		seed_input.text = "".join(arr)

func world_edited(hbox: HBoxContainer):
	ewn.text = hbox.world_name
	cw_ed = hbox
	ewm.show()

func _on_aped_submit():
	cw_ed.world_name = ewn.text
	cw_ed.apply_edit()
	ewm.hide()

func _on_wref():
	wref.disabled = true
	load_worlds(true)
	await get_tree().create_timer(0.5).timeout
	wref.disabled = false
