extends SkillBase

var dash_distance: float = 80.0

func _input(event):
	if not player:
		return
	
	if event.is_action_pressed(key_name) and can_use():
		use()

func use(_param = null):
	var damage = skill_data.get("damage", 8)
	var buff_id = skill_data.get("buff_id", 0)
	
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	var target_pos = player.global_position + direction * dash_distance
	
	player.global_position = target_pos
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var to_enemy = enemy.global_position - player.global_position
		if to_enemy.length() <= dash_distance:
			var t = to_enemy.dot(direction)
			if t > 0 and t <= dash_distance:
				enemy.take_damage(damage)
				if buff_id > 0:
					var buff_data = DataManager.get_buff(buff_id)
					if buff_data and enemy.has_method("apply_buff"):
						enemy.apply_buff(buff_data)
	
	start_cooldown()

func apply_upgrades(damage_bonus: float, cooldown_bonus: float):
	# 例如修改伤害
	if skill_data.has("damage"):
		skill_data["damage"] = skill_data["damage"] + int(skill_data["damage"] * damage_bonus)
