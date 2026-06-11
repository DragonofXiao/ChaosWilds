extends Control
class_name StartMenu

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)
	$ExitButton.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_exit_pressed():
	get_tree().quit()
