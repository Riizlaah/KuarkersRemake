extends Node

enum ObjType {
	wood,
	plank,
	stone,
}

var players : Dictionary = {}
var objects = [
	load("res://scene/plc_objects/wood.tscn"),
	load("res://scene/plc_objects/plank.tscn"),
	load("res://scene/plc_objects/stone.tscn"),
]
var curr_world_data: Dictionary
var curr_save_dir: String
var new_world: bool = false
var new_world_name: String
var new_world_seed: int
