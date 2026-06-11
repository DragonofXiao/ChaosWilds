extends CharacterBody2D
class_name Player

@export var max_hp: int = 100
@export var speed: float = 120.0
@export var auto_attack_damage: int = 12
@export var auto_attack_interval: float = 0.6
@export var bullet_speed: float = 240.0

var current_hp: int
var auto_attack_timer: float = 0.0
var current_skill_slots: Dictionary = {}
var current_team: int = 1
var upgrades: Dictionary = {
	"attack_speed": 0.0,
	"attack_damage": 0.0,
	"skill_damage": {},
	"skill_cooldown": {}
}

@onready var sprite: Sprite2D = $Sprite2D

signal hp_changed(current_hp, max_hp)
signal player_died

func _ready():
	current_hp = max_hp
	add_to_group("player")
	load_skills_for_team(current_team)

func load_skills_for_team(team_id: int):
	# 清除旧技能
	for skill in current_skill_slots.values():
		if skill:
			skill.queue_free()
	current_skill_slots.clear()
	
	# 获取队伍技能
	var team_skills = DataManager.get_skills_by_team(team_id)
	var part_to_skill = {}
	for skill in team_skills:
		var part_id = skill["part_id"]
		var part = DataManager.body_parts.get(part_id, {})
		var position = part.get("position", 0)
		part_to_skill[position] = skill
	
	var skill_scenes = {
		1: preload("res://scenes/skills/aura_skill.tscn"),
		2: preload("res://scenes/skills/breath_skill.tscn"),
		3: preload("res://scenes/skills/burst_skill.tscn"),
		4: preload("res://scenes/skills/dash_skill.tscn")
	}
	
	var action_map = {
		1: "skill_q",
		2: "skill_e",
		3: "skill_r",
		4: "skill_space"
	}
	
	for pos in range(1, 5):
		var skill_data = part_to_skill.get(pos)
		if skill_data:
			var skill_scene = skill_scenes.get(pos)
			if skill_scene:
				var skill = skill_scene.instantiate()
				skill.skill_id = skill_data["skill_id"]
				skill.key_name = action_map[pos]
				skill.set_player(self)
				add_child(skill)
				current_skill_slots[action_map[pos]] = skill
	
	# 应用升级效果
	apply_upgrades()

func apply_upgrades():
	for skill in current_skill_slots.values():
		var skill_id = skill.skill_id
		var damage_bonus = upgrades.get("skill_damage", {}).get(skill_id, 0.0)
		var cooldown_bonus = upgrades.get("skill_cooldown", {}).get(skill_id, 0.0)
		if skill.has_method("apply_upgrades"):
			skill.apply_upgrades(damage_bonus, cooldown_bonus)

func set_upgrades(new_upgrades: Dictionary):
	upgrades = new_upgrades
	apply_upgrades()

func get_auto_attack_damage() -> int:
	var bonus = upgrades.get("attack_damage", 0.0)
	return auto_attack_damage + int(auto_attack_damage * bonus)

func get_auto_attack_interval() -> float:
	var bonus = upgrades.get("attack_speed", 0.0)
	return auto_attack_interval / (1.0 + bonus)

func _physics_process(delta):
	handle_movement(delta)
	handle_auto_attack(delta)
	update_skills(delta)

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()
	
	var margin = 6.0
	global_position.x = clamp(global_position.x, margin, 320 - margin)
	global_position.y = clamp(global_position.y, margin, 320 - margin)
	
	if velocity.length() > 0:
		sprite.flip_h = velocity.x < 0

func handle_auto_attack(delta):
	auto_attack_timer -= delta
	if auto_attack_timer <= 0:
		auto_attack_timer = get_auto_attack_interval()
		fire_auto_attack()

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var nearest = null
	var min_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = enemy
	
	return nearest

func fire_auto_attack():
	var target = find_nearest_enemy()
	if not target:
		return
	
	var bullet_scene = preload("res://scenes/projectiles/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.damage = get_auto_attack_damage()
	bullet.speed = bullet_speed
	bullet.global_position = global_position
	bullet.target = target
	
	var projectiles_node = get_tree().current_scene.get_node("World/Projectiles")
	if projectiles_node:
		projectiles_node.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)

func update_skills(delta):
	for skill in current_skill_slots.values():
		skill.update_cooldown(delta)

func take_damage(amount: int):
	current_hp -= amount
	emit_signal("hp_changed", current_hp, max_hp)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	
	if current_hp <= 0:
		die()

func die():
	emit_signal("player_died")
	get_tree().paused = true

func get_skill_cooldown(action: String) -> Dictionary:
	var skill = current_skill_slots.get(action)
	if skill and skill.has_method("get_cooldown_percent"):
		return {
			"percent": skill.get_cooldown_percent(),
			"display": skill.get_cooldown_display()
		}
	return {"percent": 0.0, "display": 0}
