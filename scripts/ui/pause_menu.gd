extends Control
class_name PauseMenu

@onready var settings_panel: Control = null

func _ready():
	# 设置根节点
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 创建背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	
	# 创建菜单面板
	var panel = Panel.new()
	panel.name = "MenuPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -125
	panel.offset_top = -160
	panel.offset_right = 125
	panel.offset_bottom = 160
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	
	# 创建按钮容器
	var vbox = VBoxContainer.new()
	vbox.name = "ButtonContainer"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# 创建按钮
	var btns = [
		{"name": "ResumeButton", "text": "继续游戏"},
		{"name": "SettingsButton", "text": "设置"},
		{"name": "MenuButton", "text": "返回主界面"},
		{"name": "ExitButton", "text": "退出游戏"}
	]
	
	for btn_data in btns:
		var btn = Button.new()
		btn.name = btn_data["name"]
		btn.text = btn_data["text"]
		btn.custom_minimum_size = Vector2(200, 50)
		btn.size = Vector2(200, 50)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.add_theme_font_size_override("font_size", 20)
		vbox.add_child(btn)
	
	# 连接信号（使用 call_deferred 确保节点完全准备好）
	call_deferred("_connect_signals")

func _connect_signals():
	var resume_btn = $MenuPanel/ButtonContainer/ResumeButton
	var settings_btn = $MenuPanel/ButtonContainer/SettingsButton
	var menu_btn = $MenuPanel/ButtonContainer/MenuButton
	var exit_btn = $MenuPanel/ButtonContainer/ExitButton
	
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
		print("ResumeButton 信号已连接")
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
		print("SettingsButton 信号已连接")
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
		print("MenuButton 信号已连接")
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)
		print("ExitButton 信号已连接")
	
	settings_panel = find_child("SettingsPanel", true, false)

func _on_resume_pressed():
	print("继续游戏按钮被点击")
	var game_manager = get_tree().current_scene
	if game_manager and game_manager.has_method("resume_game"):
		game_manager.resume_game()

func _on_settings_pressed():
	print("设置按钮被点击")
	if settings_panel:
		settings_panel.visible = true

func _on_menu_pressed():
	print("返回主菜单按钮被点击")
	var game_manager = get_tree().current_scene
	if game_manager and game_manager.has_method("return_to_menu"):
		game_manager.return_to_menu()

func _on_exit_pressed():
	print("退出游戏按钮被点击")
	get_tree().quit()
