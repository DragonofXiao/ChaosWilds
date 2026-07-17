extends Area2D
class_name Bullet

var speed: float = 240.0
var damage: int = 12
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var attack_type: String = "physical"
var pierce_remaining: int = 0
var hit_targets: Array[int] = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
	match attack_type:
		"fire":
			scale = Vector2(1.2, 1.2)
		"ice":
			pierce_remaining = 1
		_:
			pass
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	var enemy: Node = null
	
	if area.is_in_group("enemies"):
		enemy = area
	elif area.get_parent() and area.get_parent().is_in_group("enemies"):
		enemy = area.get_parent()
	
	if enemy == null:
		return
	
	var enemy_id: int = enemy.get_instance_id()
	if hit_targets.has(enemy_id):
		return
	
	hit_targets.append(enemy_id)
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	if pierce_remaining > 0:
		pierce_remaining -= 1
		return
	
	queue_free()
