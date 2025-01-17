extends Node

var system: DirAccess
var opened_path = ""
var base_path

func _enter_tree():
	var path = OS.get_system_dir(OS.SYSTEM_DIR_DCIM, false).split("/")
	path.remove_at(path.size() - 1)
	path = "/".join(path) + "/games/kr"
	DirAccess.make_dir_recursive_absolute(path)
	base_path = path
	system = DirAccess.open(path)
	system.make_dir("world")
	opened_path = system.get_current_dir()

func ch_dir(path: String = ".."):
	system.change_dir(path)
	opened_path = system.get_current_dir()

func mkdir(path: String, recursive: bool = false):
	if recursive == true: return system.make_dir_recursive(path)
	return system.make_dir(path)

func write(path: String, what):
	var file = FileAccess.open(opened_path + "/" + path, FileAccess.WRITE_READ)
	if file.get_error() != OK: return ERR_CANT_OPEN
	file.store_string("")
	if what is String:
		file.store_string(what)
	elif what is PackedByteArray:
		file.store_buffer(what)
	else:
		file.store_var(what)
	file.close()

func get_worlds_data():
	mkdir("world")
	ch_dir("world")
	var list_dir = system.get_directories()
	var datas = []
	for dir in list_dir:
		if !system.file_exists(dir + "/world.dat"): break
		if !system.file_exists(dir + "/tmb.png"): break
		var file_dat = read(dir + "/world.dat", true)
		file_dat["tmb"] = ImageTexture.create_from_image(Image.load_from_file(opened_path + "/" + dir + "/tmb.png"))
		file_dat["save_dir"] = dir
		datas.append(file_dat)
	ch_dir(base_path)
	return datas

func read(path: String, get_var: bool = false):
	var file = FileAccess.open(opened_path + "/" + path, FileAccess.READ)
	if !get_var: return file.get_as_text()
	return file.get_var()

func rm(path: String):
	if system.dir_exists(path):
		for dir in DirAccess.get_directories_at(opened_path + "/" + path): rm(path + "/" + dir)
		for file in DirAccess.get_files_at(opened_path + "/" + path): system.remove(path + "/" + file)
		system.remove(path)
	elif system.file_exists(path):
		system.remove(path)
	else: pass
