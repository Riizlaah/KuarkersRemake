class_name Tree3D
extends Node3D

var wood_count: int
var valid: bool

func _ready():
	var leaf = get_node("Leaf")
	var curr_wood = get_node("Wood")
	for i in wood_count:
		if i == 0: continue
		var new_wood = curr_wood.duplicate()
		new_wood.position.y = (i * 4)
		new_wood.name = "Wood" + str(i)
		call_thread_safe("add_child", new_wood)
		curr_wood.next_remove = new_wood
		curr_wood = new_wood
	if !valid:
		leaf.free()
		return
	curr_wood.next_remove = leaf
	leaf.position = Vector3(0, (wood_count * 4) + 4, 0)

func check_wood_count():
	await get_tree().create_timer(0.05).timeout
	wood_count = get_child_count()
	valid = false
	if wood_count == 0: queue_free()

func place_object(glob_pos: Vector3, obj_type: GManager.ObjType):
	get_parent().place_object(glob_pos, obj_type)
