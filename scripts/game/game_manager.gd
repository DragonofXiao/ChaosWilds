extends Node2D
class_name GameManager

const TARGET_KILLS: int = 100
const SPAWN_INTERVAL: float = 3.0
const MAX_SLIMES: int = 8

var spawn_points: Array[Vector2] = [
	Vector2(16, 16),
	Vector2(304, 16),
	Vector2(160, 304)
]

var kill_count: int = 0
var spawn_timer: float = 0.0

@onready var player: Player = $World/Player
@onready var enemies_container: Node2D = $World/Enemies
@onready var game_ui: GameUI = $UI/GameUI
@onready var victory_ui: Control = $UI/VictoryUI
@onready var defeat_ui: Control = $UI/DefeatUI

func _ready():
	
	print("当前节点: ", get_path())
	print("UI节点: ", $UI)
	print("GameUI节点: ", $UI/GameUI if $UI else "UI不存在")
	
	game_ui = $UI/GameUI
	print("game_ui: ", game_ui)
	
	if player:
		player.hp_changed.connect(_on_hp_changed)
		player.player_died.connect(_on_player_died)
	
	spawn_initial_enemies()
	update_ui()

func spawn_initial_enemies():
	for i in range(3):
		spawn_enemy()

func spawn_enemy():
	var enemy_scene = preload("res://scenes/game/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	enemy.global_position = spawn_point
	enemy.died.connect(_on_enemy_died)
	enemies_container.add_child(enemy)

func _process(delta):
	if kill_count >= TARGET_KILLS:
		return
	
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		if enemies_container.get_child_count() < MAX_SLIMES:
			spawn_enemy()

func _on_enemy_died():
	kill_count += 1
	update_ui()
	
	if kill_count >= TARGET_KILLS and enemies_container.get_child_count() == 0:
		victory()

func _on_hp_changed(current_hp: int, max_hp: int):
	game_ui.update_hp(current_hp, max_hp)

func update_ui():
	game_ui.update_kill_count(kill_count, TARGET_KILLS)

func victory():
	get_tree().paused = true
	victory_ui.visible = true

func _on_player_died():
	defeat_ui.visible = true

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()
	
	
