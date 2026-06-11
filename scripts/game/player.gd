extends CharacterBody2D
class_name Player

@export var max_hp: int = 100
@export var speed: float = 120.0
@export var auto_attack_damage: int = 12
@export var auto_attack_interval: float = 0.6
@export var bullet_speed: float = 240.0

var current_hp: int
var auto_attack_timer: float = 0.0
var skills: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var aura_skill: SkillBase = $AuraSkill
@onready var breath_skill: SkillBase = $BreathSkill
@onready var burst_skill: SkillBase = $BurstSkill
@onready var dash_skill: SkillBase = $DashSkill

signal hp_changed(current_hp, max_hp)
signal player_died

func _ready():
	current_hp = max_hp
	add_to_group("player")
	
	aura_skill.set_player(self)
	breath_skill.set_player(self)
	burst_skill.set_player(self)
	dash_skill.set_player(self)
	
	skills = {
		"q": aura_skill,
		"e": breath_skill,
		"r": burst_skill,
		"space": dash_skill
	}

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
		auto_attack_timer = auto_attack_interval
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
	bullet.damage = auto_attack_damage
	bullet.speed = bullet_speed
	bullet.global_position = global_position
	bullet.target = target
	
	var projectiles_node = get_tree().current_scene.get_node("World/Projectiles")
	if projectiles_node:
		projectiles_node.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)

func update_skills(delta):
	for skill in skills.values():
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
	var skill = skills.get(action)
	if skill:
		return {
			"percent": skill.get_cooldown_percent(),
			"display": skill.get_cooldown_display()
		}
	return {"percent": 0.0, "display": 0}
