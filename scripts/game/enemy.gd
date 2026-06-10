extends Area2D
class_name Enemy

@export var monster_id: int = 1

var hp: int
var max_hp: int
var attack_damage: int
var speed: float
var player: Player

# 持续伤害相关
var attack_cooldown: float = 0.0
var attack_interval: float = 0.5  # 每0.5秒造成一次伤害
var is_contacting_player: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HpBar

signal died

func _ready():
	var monster_data = DataManager.monsters.get(monster_id)
	if monster_data:
		max_hp = monster_data["hp"]
		hp = max_hp
		attack_damage = monster_data["attack"]
		speed = monster_data["speed"] * 16
	else:
		max_hp = 30
		hp = 30
		attack_damage = 5
		speed = 32.0
	
	update_hp_bar()
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)  # 添加离开信号

func _physics_process(delta):
	if not player:
		return
	
	var direction = (player.global_position - global_position).normalized()
	position += direction * speed * delta
	
	if direction.x != 0:
		sprite.scale.x = abs(sprite.scale.x) * (1 if direction.x > 0 else -1)
	
	# 持续伤害逻辑
	if is_contacting_player and player and is_instance_valid(player):
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			attack_cooldown = attack_interval
			player.take_damage(attack_damage)
			
			# 击退效果
			var knockback = (global_position - player.global_position).normalized() * 50
			player.velocity += knockback

func take_damage(amount: int):
	hp -= amount
	update_hp_bar()
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		die()

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
		is_contacting_player = true
		attack_cooldown = 0  # 立即造成第一次伤害

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		is_contacting_player = false
