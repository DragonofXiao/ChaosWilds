extends Area2D
class_name Enemy

@export var monster_id: int = 1

var hp: int
var max_hp: int
var attack_damage: int
var speed: float
var player: Player
var buffs: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HpBar

signal died

func _ready():
	var monster_data = DataManager.monsters.get(monster_id)
	if monster_data:
		max_hp = monster_data["hp"]
		hp = max_hp
		attack_damage = monster_data["attack"]
		speed = monster_data["speed"]
	else:
		max_hp = 30
		hp = 30
		attack_damage = 5
		speed = 32.0
	
	update_hp_bar()
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not player:
		return
	
	update_buffs(delta)
	
	var direction = (player.global_position - global_position).normalized()
	var actual_speed = speed
	
	for buff in buffs.values():
		if buff.get("speed_down", 0) > 0:
			actual_speed *= (1.0 - float(buff["speed_down"]) / 100.0)
	
	position += direction * actual_speed * delta
	
	if direction.x != 0:
		sprite.scale.x = abs(sprite.scale.x) * (1 if direction.x > 0 else -1)

func take_damage(amount: int):
	hp -= amount
	update_hp_bar()
	
	show_floating_damage(amount)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		die()
		
func show_floating_damage(damage: int):
	var damage_label = preload("res://scenes/ui/floating_damage.tscn").instantiate()
	damage_label.setup(damage, global_position - Vector2(0, 20))
	get_tree().current_scene.add_child(damage_label)
	
func apply_buff(buff_data: Dictionary):
	var buff_id = buff_data["buff_id"]
	buffs[buff_id] = {
		"type": buff_data["type"],
		"per_damage": buff_data["per_damage"],
		"duration": buff_data["during"],
		"remaining": buff_data["during"],
		"speed_down": buff_data["speed_down"]
	}

func update_buffs(delta: float):
	var to_remove = []
	for buff_id in buffs:
		var buff = buffs[buff_id]
		buff["remaining"] -= delta
		
		# 造成持续伤害（灼烧类型 type == 1）
		if buff.get("type") == 1:
			var per_damage = buff.get("per_damage", 0)
			# 每秒造成一次伤害
			var last_damage_time = buff.get("last_damage_time", 0.0)
			last_damage_time -= delta
			if last_damage_time <= 0:
				take_damage(per_damage)
				buff["last_damage_time"] = 1.0
			else:
				buff["last_damage_time"] = last_damage_time
		
		if buff["remaining"] <= 0:
			to_remove.append(buff_id)
	
	for buff_id in to_remove:
		buffs.erase(buff_id)

func update_hp_bar():
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_bar.visible = hp < max_hp

func die():
	died.emit()
	queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		var knockback = (global_position - body.global_position).normalized() * 50
		body.velocity += knockback
