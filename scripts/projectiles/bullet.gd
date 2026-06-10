extends Area2D
class_name Bullet

var speed: float = 240.0
var damage: int = 12
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# 用代码连接信号
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area: Area2D):

	
	# 直接检查 area 本身是否在 enemies 组
	if area.is_in_group("enemies"):

		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()
		return
	
	# 如果 area 不是敌人，检查它的父节点
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):

		if parent.has_method("take_damage"):
			parent.take_damage(damage)
		queue_free()
		return
	
