extends Control

@onready var play_menu = $Mcont/PlayMenu

func _ready():
	pass

func _on_m_cont_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		play_menu.hide()

func _on_play_pressed():
	play_menu.show()

func _on_quit_pressed():
	get_tree().quit()
