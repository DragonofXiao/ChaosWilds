extends Node

var body_parts: Dictionary = {}
var skills: Dictionary = {}
var buffs: Dictionary = {}
var monsters: Dictionary = {}
var upgrades: Dictionary = {}
var upgrades_by_group: Dictionary = {}
var locale: Dictionary = {}
var current_team: int = 1

func _ready():
	load_all_data()

func load_all_data():
	load_body_parts()
	load_skills()
	load_buffs()
	load_monsters()
	load_upgrades()
	load_locale()

func load_body_parts():
	var path = "res://data/BodyPart.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 5:
			continue
		
		var data = {
			"id": int(line[0]),
			"name": line[1],
			"position": int(line[2]),
			"icon_key": line[3],
			"team_id": int(line[4])
		}
		body_parts[data["id"]] = data
	
	file.close()
	print("BodyPart: 加载 ", body_parts.size(), " 条记录")

func load_skills():
	var path = "res://data/Skill.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 10:  # 改成10列
			continue
		
		var data = {
			"skill_id": int(line[0]),
			"part_id": int(line[1]),
			"name": line[2],
			"type": int(line[3]),
			"damage": int(line[4]),
			"buff_id": int(line[5]),
			"cooldown": float(line[6]),
			"duration": float(line[7]),
			"radius": int(line[8]),
			"range_param": line[9] if line.size() > 9 else "0"
		}
		skills[data["skill_id"]] = data
	
	file.close()
	print("Skill: 加载 ", skills.size(), " 条记录")

func load_buffs():
	var path = "res://data/Buff.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 8:
			continue
		
		var data = {
			"buff_id": int(line[0]),
			"name": line[1],
			"type": int(line[2]),
			"per_damage": int(line[3]),
			"during": float(line[4]),
			"speed_down": int(line[5]),
			"stackable": int(line[6]),
			"color": line[7] if line.size() > 7 else "ffffff"
		}
		buffs[data["buff_id"]] = data
	
	file.close()
	print("Buff: 加载 ", buffs.size(), " 条记录")

func load_monsters():
	var path = "res://data/Monster.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6:
			continue
		
		var data = {
			"id": int(line[0]),
			"name": line[1],
			"hp": int(line[2]),
			"attack": int(line[3]),
			"defense": int(line[4]),
			"speed": float(line[5])
		}
		monsters[data["id"]] = data
	
	file.close()
	print("Monster: 加载 ", monsters.size(), " 条记录")

func load_upgrades():
	var path = "res://data/Upgrade.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6:
			continue
		
		var data = {
			"upgrade_id": int(line[0]),
			"group_id": int(line[1]),
			"name_key": line[2],
			"type": int(line[3]),
			"value": float(line[4]),
			"target_type": int(line[5])
		}
		upgrades[data["upgrade_id"]] = data
		
		if not upgrades_by_group.has(data["group_id"]):
			upgrades_by_group[data["group_id"]] = []
		upgrades_by_group[data["group_id"]].append(data)
	
	file.close()
	print("Upgrade: 加载 ", upgrades.size(), " 条记录")

func load_locale():
	var path = "res://data/Locale.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 3:
			continue
		
		var key = line[0]
		locale[key] = {
			"zh": line[1] if line.size() > 1 else key,
			"en": line[2] if line.size() > 2 else key
		}
	
	file.close()
	print("Locale: 加载 ", locale.size(), " 条记录")

func get_body_parts() -> Array:
	return body_parts.values()

func get_skill_by_part(part_id: int) -> Dictionary:
	for skill in skills.values():
		if skill.get("part_id", 0) == part_id:
			return skill
	return {}

func get_skills_by_team(team_id: int) -> Array:
	var result: Array = []
	for skill in skills.values():
		var part_id: int = skill.get("part_id", 0)
		var part: Dictionary = body_parts.get(part_id, {})
		if part.get("team_id", 0) == team_id:
			result.append(skill)
	return result

func get_random_upgrade_from_group(group_id: int) -> Dictionary:
	var group = upgrades_by_group.get(group_id, [])
	if group.is_empty():
		return {}
	return group[randi() % group.size()]

func get_buff(buff_id: int) -> Dictionary:
	return buffs.get(buff_id, {})

func get_text(key: String, lang: String) -> String:
	var data = locale.get(key, {})
	return data.get(lang, key)
