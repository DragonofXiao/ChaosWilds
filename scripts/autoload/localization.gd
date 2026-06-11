extends Node

enum Language { ZH, EN }

var current_lang: Language = Language.ZH

var texts: Dictionary = {
	"zh": {
		"game_title": "混沌世界",
		"btn_start": "开始游戏",
		"btn_exit": "退出",
		"btn_restart": "重新开始",
		"btn_menu": "返回菜单",
		"hp": "生命值",
		"victory": "胜利！",
		"defeat": "失败...",
		"kill_count": "击杀",
		"skill_aura": "光环",
		"skill_breath": "吐息",
		"skill_burst": "爆裂",
		"skill_dash": "残影"
	},
	"en": {
		"game_title": "Chaos Wilds",
		"btn_start": "Start Game",
		"btn_exit": "Exit",
		"btn_restart": "Restart",
		"btn_menu": "Back to Menu",
		"hp": "HP",
		"victory": "Victory!",
		"defeat": "Defeat...",
		"kill_count": "Kills",
		"skill_aura": "Aura",
		"skill_breath": "Breath",
		"skill_burst": "Burst",
		"skill_dash": "Dash"
	}
}

func t(key: String) -> String:
	var lang_code = "zh" if current_lang == Language.ZH else "en"
	return texts[lang_code].get(key, key)

func set_language(lang: Language):
	current_lang = lang
