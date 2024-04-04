extends HBoxContainer

signal world_pressed(data: Dictionary, save_dir: String)
signal edit_pressed(world_if: HBoxContainer)

var world_data = {}
var save_dir: String
var tmb: Texture
var world_name: String
var world_seed: int

@onready var del_confr = $DelConf
@onready var w_lb = $Button/Mcont/Hbox/Vbox/Label

func parse_data(data: Dictionary):
	world_data = {"world_data": data.world_data, "chunks": data.chunks, "players": data.players}
	save_dir = data.save_dir
	tmb = data.tmb
	world_name = data.world_data.name
	world_seed = data.world_data.seed

func _ready():
	$Button/Mcont/Hbox/Texr.texture = tmb
	w_lb.text = world_name
	$Button/Mcont/Hbox/Vbox/Label2.text = "Seed : %d" % world_seed

func load_world():
	world_pressed.emit(world_data, save_dir)

func _on_edit_pressed():
	edit_pressed.emit(self)

func _on_del_pressed():
	del_confr.show()
	del_confr.dialog_text = "Hapus dunia : '%s' ?" % world_name

func _on_del_conf_confirmed():
	FileSystem.rm("world/%s" % save_dir)
	queue_free()

func apply_edit():
	w_lb.text = world_name
	world_data.world_data.name = world_name
	FileSystem.write("world/" + save_dir + "/world.dat", world_data)
