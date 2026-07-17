extends Node

const SETTINGS_PATH = "user://settings.cfg"
const TUTORIAL_KEY = "tutorial_shown"

func _ready():
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_setting(TUTORIAL_KEY, false)

func has_seen_tutorial() -> bool:
	return load_setting(TUTORIAL_KEY, false)

func set_tutorial_seen():
	save_setting(TUTORIAL_KEY, true)

func save_setting(key: String, value):
	var config = ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	config.set_value("settings", key, value)
	config.save(SETTINGS_PATH)

func load_setting(key: String, default):
	var config = ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	return config.get_value("settings", key, default)
