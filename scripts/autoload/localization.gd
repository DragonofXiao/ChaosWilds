extends Node

enum Language { ZH, EN }

var current_lang: String = "zh"

func _ready():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var lang_str = config.get_value("settings", "language", "zh")
		current_lang = lang_str

func t(key: String) -> String:
	return DataManager.get_text(key, current_lang)

func set_language(lang: String):
	current_lang = lang
	var config = ConfigFile.new()
	config.set_value("settings", "language", current_lang)
	config.save("user://settings.cfg")
	
	# 刷新所有UI文本
	EventBus.language_changed.emit()

func get_current_lang() -> String:
	return "中文" if current_lang == "zh" else "English"
