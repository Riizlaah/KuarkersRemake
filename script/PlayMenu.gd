extends ColorRect

@onready var server_list = $Mcont/Hbox/Vbox/Scont/ServerList
@onready var player_list = $Mcont/Hbox/Scont2/PlayerList
@onready var play = $Mcont/Hbox/Vbox2/Button4
@onready var timer = $Timer

@export var server_i: PackedScene
@export var player_i: PackedScene

var ip_addr
var tr_addr
var port
const lt_port = 8082
const br_port = 8083
var lt_peer = PacketPeerUDP.new()
var br_peer
var server_info: Dictionary

func _ready():
	var label = $"../../Label"
	label.hide()
	ip_addr = IP.get_local_addresses()[0]
	setup_tr_ip()
	port = randi_range(8085, 9990)
	var err = lt_peer.bind(lt_port, ip_addr)
	if err != OK: label.show()
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _connected_to_server():
	_toggle_menu(true)
	_send_info.rpc_id(1, Settings.player_name, multiplayer.get_unique_id())

func _connection_failed():
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scene/main.tscn")

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
	get_tree().change_scene_to_file("res://scene/main.tscn")

func setup_tr_ip():
	var output = []
	OS.execute("ip", ["neigh"], output)
	if output == [""]:
		tr_addr = ip_addr
		return
	tr_addr = output[0].get_slice(" ", 0)

func _on_create_pressed():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port)
	if err != OK:
		OS.alert('Gagal membuat server...', 'Peringatan')
		get_tree().change_scene_to_file("res://scene/main.tscn")
		return
	multiplayer.set_multiplayer_peer(peer)
	_send_info(Settings.player_name, 1)
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
	var err = br_peer.bind(br_port, ip_addr)
	if err != OK:
		OS.alert("Error tidak bisa broadcast")
		get_tree().change_scene_to_file("res://scene/main.tscn")
		return
	br_peer.set_broadcast_enabled(true)
	br_peer.set_dest_address(tr_addr, lt_port)
	timer.start()

func _on_br_out():
	server_info.name = Settings.player_name + " Server"
	server_info.port = port
	server_info.count = GManager.players.size()
	server_info.ip = ip_addr
	var data = (JSON.stringify(server_info)).to_ascii_buffer()
	br_peer.put_packet(data)
	

@rpc("any_peer")
func _send_info(nama, id):
	if !GManager.players.has(id):
		GManager.players[id] = {
			'name': nama
		}
	if multiplayer.is_server():
		GManager.players = make_uniq_name(GManager.players)
		for i in GManager.players:
			if id != 1: _send_info.rpc(GManager.players[i].name, i)

func _join_server(ip: String, port2: int):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port2)
	if err != OK:
		OS.alert('Gagal bergabung...', 'Peringatan')
		get_tree().change_scene_to_file("res://scene/main.tscn")
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
			print(new_server.ip, new_server.port)
			return
		server_node.text = "-- " + packet.name + " --\nPemain : " + str(packet.count)

func _on_refresh():
	for node in server_list.get_children(): node.queue_free()

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

func _start_game():
	pass # Replace with function body
