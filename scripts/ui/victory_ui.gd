extends Control

func _ready():

	await get_tree().process_frame
	
	# 查找按钮（使用正确的节点名）
	var button = find_child("RestartButton", true, false)
	if button:

		button.pressed.connect(_on_restart_pressed)
	else:
	
		for child in get_children():
			print("子节点: ", child.name)

func _on_restart_pressed():

	get_tree().paused = false
	get_tree().reload_current_scene()
