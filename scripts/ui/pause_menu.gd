extends Control

@onready var settings_panel: Control = $SettingsPanel

func _ready():
	await get_tree().process_frame
	# 连接按钮信号
	$MenuPanel/ButtonContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$MenuPanel/ButtonContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$MenuPanel/ButtonContainer/MenuButton.pressed.connect(_on_menu_pressed)
	$MenuPanel/ButtonContainer/ExitButton.pressed.connect(_on_exit_pressed)
	
	# 设置面板初始隐藏
	if settings_panel:
		settings_panel.visible = false

func _on_resume_pressed():
	print("=== 按钮被点击了！===")
	var game_manager = get_tree().current_scene
	print("获取到的 game_manager: ", game_manager)
	if game_manager:
		print("是否有 resume_game 方法: ", game_manager.has_method("resume_game"))
		if game_manager.has_method("resume_game"):
			game_manager.resume_game()
		else:
			print("resume_game 方法不存在")
	else:
		print("game_manager 是 null")

func _on_settings_pressed():
	if settings_panel:
		settings_panel.visible = true

func _on_menu_pressed():
	var game_manager = get_tree().current_scene
	if game_manager and game_manager.has_method("return_to_menu"):
		game_manager.return_to_menu()

func _on_exit_pressed():
	get_tree().quit()
