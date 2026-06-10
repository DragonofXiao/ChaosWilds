extends Node2D
class_name GameManager

@onready var player: Player = $Player
@onready var enemies_container: Node2D = $Enemies
@onready var victory_ui: Control = $UI/VictoryUI
@onready var defeat_ui: Control = $UI/DefeatUI
@onready var kill_counter: Label = $UI/KillCounter

var enemies_killed: int = 0
var enemies_needed: int = 3

# 写死的怪物刷新点
var spawn_points: Array[Vector2] = [
	Vector2(80, 80),
	Vector2(240, 80),
	Vector2(160, 240)
]

func _ready():
	if player:
		player.player_died.connect(_on_player_died)
	
	spawn_enemies()
	update_ui()

func spawn_enemies():
	var enemy_scene = preload("res://scenes/game/enemy.tscn")

	for spawn_pos in spawn_points:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_pos
		enemy.died.connect(_on_enemy_died)
		enemies_container.add_child(enemy)

func _on_enemy_died():
	enemies_killed += 1
	update_ui()
	
	if enemies_killed >= enemies_needed:
		victory()

func update_ui():
	if kill_counter:
		kill_counter.text = "击杀: %d / %d" % [enemies_killed, enemies_needed]

func victory():
	
	# 不要暂停整个树，只暂停游戏世界
	get_tree().paused = true
	
	# 让胜利界面所在的 CanvasLayer 继续处理输入
	victory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_ui.set_process(true)
	victory_ui.set_physics_process(true)
	victory_ui.set_process_input(true)
	
	victory_ui.visible = true


func _on_player_died():
	defeat_ui.visible = true

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()
