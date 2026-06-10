extends Node

# 数据存储
var body_parts: Dictionary = {}
var skills: Dictionary = {}
var monsters: Dictionary = {}

# 写死的玩家部位（Demo阶段）
var player_parts: Array = [101, 102]

func _ready():
	load_all_data()

func load_all_data():
	load_body_parts()
	load_skills()
	load_monsters()

func load_body_parts():
	var path = "res://data/BodyPart.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var headasers = file.get_csv_line()
	
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
	var headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6:
			continue
		
		var data = {
			"skill_id": int(line[0]),
			"part_id": int(line[1]),
			"name": line[2],
			"type": int(line[3]),
			"damage": int(line[4]),
			"cooldown": float(line[5])
		}
		skills[data["skill_id"]] = data
	
	file.close()
	print("Skill: 加载 ", skills.size(), " 条记录")

func load_monsters():
	var path = "res://data/Monster.csv"
	if not FileAccess.file_exists(path):
		print("警告: 未找到 ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var headers = file.get_csv_line()
	
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

func get_player_skill() -> Dictionary:
	for part_id in player_parts:
		for skill in skills.values():
			if skill["part_id"] == part_id:
				return skill
	
	# 默认技能
	return {
		"skill_id": 10102,
		"part_id": 102,
		"name": "火焰吐息",
		"type": 3,
		"damage": 20,
		"cooldown": 4.0
	}
