class_name BaseItem
extends Resource

@export_category("BaseItem")
@export var icon: Texture2D
@export var name: String
@export var stackable: bool
@export var stack_count: int = 1:
	set(val):
		stack_count = val
		if stackable == false: stack_count = clamp(stack_count, 0, 1)


