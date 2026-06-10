extends CharacterBody2D
class_name Player

# 写死配置
@export var max_hp: int = 100
@export var speed: float = 120.0
@export var auto_attack_damage: int = 12
@export var auto_attack_interval: float = 0.6
@export var bullet_speed: float = 240.0

var current_hp: int
var auto_attack_timer: float = 0.0

# 技能相关
var current_skill: Dictionary
var is_charging: bool = false
var charge_time: float = 0.0
var skill_cooldown: float = 0.0
var skill_damage: int

# 无敌相关
var invincible_timer: float = 0.0
var invincible_duration: float = 0.5  # 无敌持续时间（秒）

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HpBar

signal hp_changed(current_hp, max_hp)
signal player_died

func _ready():
	current_hp = max_hp
	update_hp_bar()
	
	current_skill = DataManager.get_player_skill()
	skill_damage = current_skill["damage"]
	
	add_to_group("player")
	

func _physics_process(delta):
	handle_movement(delta)
	handle_auto_attack(delta)
	handle_skill(delta)
	
	# 无敌时间递减
	if invincible_timer > 0:
		invincible_timer -= delta

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()
	
	# 边界限制 (0, 0) 到 (320, 320)
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
	get_tree().current_scene.add_child(bullet)

func handle_skill(delta):
	# 冷却更新
	if skill_cooldown > 0:
		skill_cooldown -= delta
	
	# 蓄力逻辑
	if Input.is_action_just_pressed("skill") and skill_cooldown <= 0:
		start_charge()
	
	if is_charging:
		charge_time += delta
		
		if Input.is_action_just_released("skill"):
			release_skill()

func start_charge():
	is_charging = true
	charge_time = 0.0
	show_charge_indicator(true)

func release_skill():
	is_charging = false
	show_charge_indicator(false)
	
	var min_charge = 0.5
	var max_charge = 1.5
	var actual_charge = clamp(charge_time, min_charge, max_charge)
	
	var charge_factor = (actual_charge - min_charge) / (max_charge - min_charge)
	var max_distance = 200.0  # 增加最大距离
	var min_distance = 50.0
	var distance = min_distance + charge_factor * (max_distance - min_distance)
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	fire_skill(direction, distance)
	skill_cooldown = current_skill["cooldown"]

func fire_skill(direction: Vector2, distance: float):
	var end_point = global_position + direction * distance
	
	# 射线检测 - 支持检测 Area2D
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, end_point)
	query.exclude = [self]
	query.collision_mask = 2  # 检测第2层（敌人层）
	query.collide_with_areas = true   # 关键：让射线检测 Area2D
	query.collide_with_bodies = false  # 不检测刚体/静态体
	
	var result = space_state.intersect_ray(query)
	
	# 技能特效
	draw_skill_effect(direction, distance)
	
	# 造成伤害
	if result and result.collider.is_in_group("enemies"):
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(skill_damage)


func draw_skill_effect(direction: Vector2, distance: float):
	var end_point = to_local(global_position + direction * distance)
	var line = Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(end_point)
	line.width = 16
	line.default_color = Color(1.0, 0.3, 0.1, 0.8)
	add_child(line)
	
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0, 0.15)
	tween.tween_callback(line.queue_free)

func show_charge_indicator(show: bool):
	var indicator = $ChargeIndicator
	if not indicator and show:
		var circle = Sprite2D.new()
		circle.name = "ChargeIndicator"
		circle.texture = create_circle_texture(16)
		circle.modulate = Color(1.0, 0.5, 0.0, 0.6)
		circle.scale = Vector2(0.1, 0.1)
		add_child(circle)
		
		var tween = create_tween()
		tween.tween_property(circle, "scale", Vector2(1.5, 1.5), 1.0)
	elif indicator and not show:
		indicator.queue_free()

func create_circle_texture(radius: int) -> Texture2D:
	var image = Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	for x in range(radius * 2):
		for y in range(radius * 2):
			var dx = x - radius
			var dy = y - radius
			if sqrt(dx*dx + dy*dy) <= radius:
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func take_damage(amount: int):
	# 无敌时免疫伤害
	if invincible_timer > 0:
		return
	
	current_hp -= amount
	update_hp_bar()
	
	# 设置无敌时间
	invincible_timer = invincible_duration
	
	# 受伤闪烁效果
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	
	if current_hp <= 0:
		die()

func update_hp_bar():
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		hp_bar.visible = current_hp < max_hp
	hp_changed.emit(current_hp, max_hp)

func die():
	player_died.emit()
	get_tree().paused = true
