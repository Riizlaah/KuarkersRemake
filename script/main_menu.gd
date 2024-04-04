extends Control

@onready var play_menu = $Mcont/PlayMenu
@export var version: String
const developer = "NR-Heks"

func _ready():
	$Mcont2/Version.text = version
	$Mcont2/Developer.text = developer
	print(DisplayServer.window_get_min_size(), DisplayServer.window_get_max_size())
	DisplayServer.window_set_size(Vector2i(1000, 600))
	print(DisplayServer.window_get_size())

func _on_m_cont_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		play_menu.hide()

func _on_play_pressed():
	play_menu.show()

func _on_quit_pressed():
	get_tree().quit()
