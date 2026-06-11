extends SkillBase

var is_holding: bool = false
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
	var radius = skill_data.get("radius", 40)
	
	var circle = Sprite2D.new()
	circle.texture = create_circle_texture(radius)
	circle.modulate = Color(1.0, 0.0, 0.0, 0.3)
	indicator.add_child(circle)
	
	player.add_child(indicator)

func hide_indicator():
	if indicator:
		indicator.queue_free()
		indicator = null

func use(_param = null):
	var radius = skill_data.get("radius", 40)
	var damage = skill_data.get("damage", 0)
	var duration = skill_data.get("duration", 5.0)
	var buff_id = skill_data.get("buff_id", 0)
	
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if player.global_position.distance_to(enemy.global_position) <= radius:
			if damage > 0 and enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			
			if buff_id > 0:
				var buff_data = DataManager.get_buff(buff_id)
				if buff_data and enemy.has_method("apply_buff"):
					enemy.apply_buff(buff_data)
	
	start_cooldown()
	show_effect(radius)

func show_effect(radius: float):
	var effect = Sprite2D.new()
	effect.texture = create_circle_texture(radius)
	effect.modulate = Color(1.0, 0.5, 0.0, 0.5)
	player.add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0, 0.2)
	tween.tween_callback(effect.queue_free)

func create_circle_texture(radius: float) -> Texture2D:
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = radius
	var r = radius
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			if sqrt(dx*dx + dy*dy) <= r:
				image.set_pixel(x, y, Color.WHITE)
	
	return ImageTexture.create_from_image(image)

func update_cooldown(delta: float):
	super(delta)
	if not is_ready and is_holding:
		is_holding = false
		hide_indicator()

func apply_upgrades(damage_bonus: float, cooldown_bonus: float):
	# 例如修改伤害
	if skill_data.has("damage"):
		skill_data["damage"] = skill_data["damage"] + int(skill_data["damage"] * damage_bonus)
