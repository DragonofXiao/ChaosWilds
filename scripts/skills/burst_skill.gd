extends SkillBase

var is_holding: bool = false
var radius: float = 80.0
var angle: float = 120.0
var indicator: Node2D

func _input(event):
	if not player:
		return
	
	if event.is_action_pressed(key_name) and can_use():
		is_holding = true
		show_indicator()
	
	if event.is_action_released(key_name) and is_holding:
		is_holding = false
		hide_indicator()
		if can_use():
			use()

func show_indicator():
	if indicator:
		indicator.queue_free()
	
	indicator = Node2D.new()
	update_indicator_direction()
	player.add_child(indicator)

func update_indicator_direction():
	if not indicator:
		return
	
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	var mesh = Polygon2D.new()
	var points = generate_sector_points()
	var rotated_points = PackedVector2Array()
	for point in points:
		rotated_points.append(point.rotated(direction.angle()))
	mesh.polygon = rotated_points
	mesh.color = Color(1.0, 0.0, 0.0, 0.3)
	
	# 清除旧的并添加新的
	for child in indicator.get_children():
		child.queue_free()
	indicator.add_child(mesh)

func generate_sector_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var start_angle = -angle / 2.0
	var end_angle = angle / 2.0
	var segments = 20
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var current_angle = start_angle + t * angle
		var rad = deg_to_rad(current_angle)
		var point = Vector2(cos(rad), sin(rad)) * radius
		points.append(point)
	
	return points

func hide_indicator():
	if indicator:
		indicator.queue_free()
		indicator = null

func use(_param = null):
	
	var damage = skill_data.get("damage", 28)
	var buff_id = skill_data.get("buff_id", 0)
	
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var to_enemy = enemy.global_position - player.global_position
		if to_enemy.length() <= radius:
			var enemy_angle = to_enemy.angle()
			var angle_diff = abs(enemy_angle - direction.angle())
			if angle_diff <= deg_to_rad(angle / 2.0):
				enemy.take_damage(damage)
				if buff_id > 0:
					var buff_data = DataManager.get_buff(buff_id)
					if buff_data and enemy.has_method("apply_buff"):
						enemy.apply_buff(buff_data)
	
	show_effect(direction)
	start_cooldown()

func show_effect(direction: Vector2):
	var points = generate_sector_points()
	var rotated_points = PackedVector2Array()
	for point in points:
		var rotated = point.rotated(direction.angle())
		rotated_points.append(rotated)
	
	var mesh = Polygon2D.new()
	mesh.polygon = rotated_points
	mesh.color = Color(1.0, 0.3, 0.1, 0.5)
	player.add_child(mesh)
	
	var tween = create_tween()
	tween.tween_property(mesh, "modulate:a", 0, 0.2)
	tween.tween_callback(mesh.queue_free)

func _process(delta):
	super(delta)
	if is_holding and player:
		update_indicator_direction()
	
	if not is_ready and is_holding:
		is_holding = false
		hide_indicator()

func apply_upgrades(damage_bonus: float, cooldown_bonus: float):
	# 例如修改伤害
	if skill_data.has("damage"):
		skill_data["damage"] = skill_data["damage"] + int(skill_data["damage"] * damage_bonus)
