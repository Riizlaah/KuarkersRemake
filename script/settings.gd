extends Node

var player_name: String = "Hekerd"
var render_distance: int = 128
var lods = [2, 4, 8]
var lods_dist = [1024, 640, 512]
var unique_id: int = 0

func _ready():
	await get_tree().create_timer(0.25).timeout
	if unique_id == 0:
		var data = FileAccess.get_file_as_string("user://unique_id")
		if data == "": data = str(randi())
		unique_id = data.to_int()
		var file = FileAccess.open("user://unique_id", FileAccess.WRITE)
		file.store_string("")
		file.store_string(data)
		file.flush()
