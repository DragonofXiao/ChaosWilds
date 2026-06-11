extends Label
class_name FloatingDamage

func setup(damage: int, position: Vector2):
	text = str(damage)
	global_position = position
	
	# 向上飘移动画
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -30), 0.5)
	
	# 淡出动画
	tween.parallel().tween_property(self, "modulate:a", 0, 0.5)
	
	# 动画结束后删除
	tween.tween_callback(queue_free)
