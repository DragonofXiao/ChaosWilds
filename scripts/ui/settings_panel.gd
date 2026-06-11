extends Control
class_name SettingsPanel

@onready var fullscreen_check: CheckBox = $SettingsContainer/FullscreenRow/FullscreenCheck
@onready var quality_option: OptionButton = $SettingsContainer/QualityRow/QualityOption
@onready var lang_button: Button = $SettingsContainer/LanguageRow/LangButton
@onready var close_button: Button = $CloseButton

func _ready():
	# 全屏
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# 画质（占位）
	quality_option.add_item(Localization.t("quality_low"), 0)
	quality_option.add_item(Localization.t("quality_medium"), 1)
	quality_option.add_item(Localization.t("quality_high"), 2)
	
	# 语言
	update_lang_button()
	lang_button.pressed.connect(_on_lang_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_fullscreen_toggled(button_pressed: bool):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_lang_pressed():
	var new_lang = "en" if Localization.current_lang == "zh" else "zh"
	Localization.set_language(new_lang)
	update_lang_button()
	EventBus.language_changed.emit()

func update_lang_button():
	lang_button.text = "中文" if Localization.current_lang == "zh" else "English"

func _on_close_pressed():
	print("关闭设置面板")
	visible = false
