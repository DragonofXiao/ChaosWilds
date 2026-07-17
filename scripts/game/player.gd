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
var current_parts: Dictionary = {}
var attack_type: String = "physical"
var upgrades: Dictionary = {
	"attack_speed": 0.0,
	"attack_damage": 0.0,
	"skill_damage": {},
	"skill_cooldown": {}
}

@onready var sprite: Sprite2D = $Sprite2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal parts_applied(parts: Dictionary, attack_type_value: String)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")

func apply_parts(parts: Dictionary) -> void:
	current_parts = parts
	
	var fire_count: int = 0
	var ice_count: int = 0
	for pos in parts:
		var part: Dictionary = parts[pos]
		if part.get("team_id", 0) == 1:
			fire_count += 1
		elif part.get("team_id", 0) == 2:
			ice_count += 1
	
	if fire_count > ice_count:
		attack_type = "fire"
	elif ice_count > fire_count:
		attack_type = "ice"
	else:
		attack_type = "physical"
	
	_load_skills_from_parts(parts)
	apply_upgrades()
	emit_signal("parts_applied", parts, attack_type)

func _load_skills_from_parts(parts: Dictionary) -> void:
	_clear_all_skills()
	
	var skill_scenes: Dictionary = {
		1: preload("res://scenes/skills/aura_skill.tscn"),
		2: preload("res://scenes/skills/breath_skill.tscn"),
		3: preload("res://scenes/skills/burst_skill.tscn"),
		4: preload("res://scenes/skills/dash_skill.tscn")
	}
	
	var action_map: Dictionary = {
		1: "skill_q",
		2: "skill_e",
		3: "skill_r",
		4: "skill_space"
	}
	
	for pos in range(1, 5):
		var part: Dictionary = parts.get(pos, {})
		if part.is_empty():
			continue
		
		var part_id: int = part.get("id", 0)
		var skill_data: Dictionary = DataManager.get_skill_by_part(part_id)
		if skill_data.is_empty():
			continue
		
		var skill_scene: PackedScene = skill_scenes.get(pos)
		if skill_scene == null:
			continue
		
		var skill: SkillBase = skill_scene.instantiate()
		skill.skill_id = skill_data["skill_id"]
		skill.key_name = action_map[pos]
		skill.set_player(self)
		add_child(skill)
		current_skill_slots[action_map[pos]] = skill

func _clear_all_skills() -> void:
	for child in get_children():
		if child is SkillBase:
			child.free()
	current_skill_slots.clear()

func get_skill_display_data() -> Dictionary:
	var key_labels: Dictionary = {
		"skill_q": "Q",
		"skill_e": "E",
		"skill_r": "R",
		"skill_space": "SPACE"
	}
	var result: Dictionary = {}
	for action in current_skill_slots:
		var skill: SkillBase = current_skill_slots[action]
		var skill_name: String = skill.skill_data.get("name", "")
		result[action] = {
			"key": key_labels.get(action, ""),
			"name": skill_name
		}
	return result

func apply_upgrades() -> void:
	for skill in current_skill_slots.values():
		var skill_id: int = skill.skill_id
		var damage_bonus: float = upgrades.get("skill_damage", {}).get(skill_id, 0.0)
		var cooldown_bonus: float = upgrades.get("skill_cooldown", {}).get(skill_id, 0.0)
		if skill.has_method("apply_upgrades"):
			skill.apply_upgrades(damage_bonus, cooldown_bonus)

func set_upgrades(new_upgrades: Dictionary) -> void:
	upgrades = new_upgrades
	apply_upgrades()

func get_auto_attack_damage() -> int:
	var bonus: float = upgrades.get("attack_damage", 0.0)
	return auto_attack_damage + int(auto_attack_damage * bonus)

func get_auto_attack_interval() -> float:
	var bonus: float = upgrades.get("attack_speed", 0.0)
	return auto_attack_interval / (1.0 + bonus)

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_auto_attack(delta)
	update_skills(delta)

func handle_movement(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()
	
	var margin: float = 6.0
	global_position.x = clamp(global_position.x, margin, 320 - margin)
	global_position.y = clamp(global_position.y, margin, 320 - margin)
	
	if velocity.length() > 0:
		sprite.flip_h = velocity.x < 0

func handle_auto_attack(delta: float) -> void:
	auto_attack_timer -= delta
	if auto_attack_timer <= 0:
		auto_attack_timer = get_auto_attack_interval()
		fire_auto_attack()

func find_nearest_enemy() -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var nearest: Node2D = null
	var min_distance: float = INF
	
	for enemy in enemies:
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = enemy as Node2D
	
	return nearest

func fire_auto_attack() -> void:
	var target: Node2D = find_nearest_enemy()
	if not target:
		return
	
	var bullet_scene: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.damage = get_auto_attack_damage()
	bullet.speed = bullet_speed
	bullet.global_position = global_position
	bullet.target = target
	bullet.attack_type = attack_type
	
	var projectiles_node: Node2D = get_tree().current_scene.get_node("World/Projectiles")
	if projectiles_node:
		projectiles_node.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)

func update_skills(delta: float) -> void:
	for skill in current_skill_slots.values():
		skill.update_cooldown(delta)

func take_damage(amount: int) -> void:
	current_hp -= amount
	emit_signal("hp_changed", current_hp, max_hp)
	
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	
	if current_hp <= 0:
		die()

func die() -> void:
	emit_signal("player_died")
	get_tree().paused = true

func get_skill_cooldown(action: String) -> Dictionary:
	var skill: SkillBase = current_skill_slots.get(action)
	if skill and skill.has_method("get_cooldown_percent"):
		return {
			"percent": skill.get_cooldown_percent(),
			"display": skill.get_cooldown_display()
		}
	return {"percent": 0.0, "display": 0}
