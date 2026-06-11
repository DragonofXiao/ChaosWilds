extends SkillBase

var is_charging: bool = false
var charge_time: float = 0.0
var min_charge: float = 0.5
var max_charge: float = 1.5
var min_length: float = 40.0
var max_length: float = 128.0
var width: float = 16.0
var indicator: Line2D

func _input(event):
	if not player:
		return
	
	if event.is_action_pressed(key_name) and can_use():
		is_charging = true
		charge_time = 0.0
		show_indicator()
	
	if event.is_action_released(key_name) and is_charging:
		is_charging = false
		hide_indicator()
		if can_use():
			var actual_charge = clamp(charge_time, min_charge, max_charge)
			var charge_factor = (actual_charge - min_charge) / (max_charge - min_charge)
			var length = min_length + charge_factor * (max_length - min_length)
			use(length)

func show_indicator():
	if indicator:
		indicator.queue_free()
	
	indicator = Line2D.new()
	indicator.width = width
	indicator.default_color = Color(1.0, 0.0, 0.0, 0.4)
	player.add_child(indicator)

func update_indicator():
	if not indicator or not player:
		return
	
	var charge_factor = clamp((charge_time - min_charge) / (max_charge - min_charge), 0.0, 1.0)
	var length = min_length + charge_factor * (max_length - min_length)
	
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	var end_point = player.to_local(player.global_position + direction * length)
	
	indicator.clear_points()
	indicator.add_point(Vector2.ZERO)
	indicator.add_point(end_point)

func hide_indicator():
	if indicator:
		indicator.queue_free()
		indicator = null

func use(_param = null):
	var length = _param if _param != null else 80.0
	var damage = skill_data.get("damage", 20)
	var buff_id = skill_data.get("buff_id", 0)
	
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	var end_point = player.global_position + direction * length
	
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(player.global_position, end_point)
	query.exclude = [player]
	query.collision_mask = 2
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	show_effect(direction, length)
	
	if result and result.collider.is_in_group("enemies"):
		result.collider.take_damage(damage)
		if buff_id > 0:
			var buff_data = DataManager.get_buff(buff_id)
			if buff_data and result.collider.has_method("apply_buff"):
				result.collider.apply_buff(buff_data)
	
	start_cooldown()

func show_effect(direction: Vector2, length: float):
	var line = Line2D.new()
	var end_point = player.to_local(player.global_position + direction * length)
	line.add_point(Vector2.ZERO)
	line.add_point(end_point)
	line.width = width
	line.default_color = Color(1.0, 0.3, 0.1, 0.8)
	player.add_child(line)
	
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0, 0.15)
	tween.tween_callback(line.queue_free)

func _process(delta):
	super(delta)
	if is_charging:
		charge_time += delta
		update_indicator()
		if charge_time > max_charge:
			charge_time = max_charge
	elif not is_ready and is_charging:
		is_charging = false
		hide_indicator()
