extends Node2D
class_name SkillBase

@export var skill_id: int = 0
@export var key_name: String = ""

var skill_data: Dictionary
var current_cooldown: float = 0.0
var is_ready: bool = true
var player: Player

func _ready():
	var base_data: Dictionary = DataManager.skills.get(skill_id, {})
	skill_data = base_data.duplicate(true)
	
func set_player(p: Player):
	player = p

func update_cooldown(delta: float):
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown <= 0:
			current_cooldown = 0
			is_ready = true

func start_cooldown():
	current_cooldown = skill_data.get("cooldown", 0.0)
	is_ready = false

func get_cooldown_percent() -> float:
	if current_cooldown <= 0:
		return 0.0
	var total = skill_data.get("cooldown", 1.0)
	return current_cooldown / total

func get_cooldown_display() -> int:
	return ceil(current_cooldown)

func can_use() -> bool:
	return is_ready

func use(_param = null):
	pass

func show_indicator():
	pass

func hide_indicator():
	pass

func _process(delta):
	update_cooldown(delta)
	
func apply_upgrades(damage_bonus: float, cooldown_bonus: float):
	# 子类可重写此方法
	pass
