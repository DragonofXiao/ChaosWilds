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
var current_floor: int = 1
var is_paused: bool = false
var upgrades: Dictionary = {
	"attack_speed": 0.0,
	"attack_damage": 0.0,
	"skill_damage": {},  # skill_id -> bonus
	"skill_cooldown": {}  # skill_id -> bonus
}

@onready var player: Player = $World/Player
@onready var enemies_container: Node2D = $World/Enemies
@onready var projectiles_container: Node2D = $World/Projectiles
@onready var game_ui: GameUI = $UI/GameUI
@onready var victory_ui: Control = $UI/VictoryUI
@onready var defeat_ui: Control = $UI/DefeatUI
@onready var pause_menu: Control = $UI/PauseMenu
@onready var world: Node2D = $World

func _ready():
	if player:
		player.hp_changed.connect(_on_hp_changed)
		player.player_died.connect(_on_player_died)
		player.set_upgrades(upgrades)
	
	spawn_initial_enemies()
	update_ui()
	
	EventBus.upgrade_selected.connect(_on_upgrade_selected)

func toggle_pause():
	get_tree().paused = !get_tree().paused
	pause_menu.visible = get_tree().paused
	if pause_menu:
		pause_menu.visible = get_tree().paused

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
		
	if kill_count >= TARGET_KILLS:
		return
	
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		if enemies_container.get_child_count() < MAX_SLIMES:
			spawn_enemy()

func spawn_initial_enemies():
	for i in range(3):
		spawn_enemy()

func spawn_enemy():
	var enemy_scene = preload("res://scenes/game/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	enemy.global_position = spawn_point
	enemy.died.connect(_on_enemy_died)
	
	# 第二层血量翻倍
	if current_floor >= 2:
		enemy.set_hp_multiplier(2.0)
	
	enemies_container.add_child(enemy)

func _on_enemy_died():
	kill_count += 1
	update_ui()
	
	if kill_count >= TARGET_KILLS and enemies_container.get_child_count() == 0:
		victory()

func _on_hp_changed(current_hp: int, max_hp: int):
	game_ui.update_hp(current_hp, max_hp)

func update_ui():
	game_ui.update_kill_count(kill_count, TARGET_KILLS)
	game_ui.update_floor(current_floor)

func show_upgrade_panel():
	# 从每个组随机选一个升级
	var selected_upgrades = []
	for group_id in range(1, 5):
		var upgrade = DataManager.get_random_upgrade_from_group(group_id)
		if not upgrade.is_empty():
			selected_upgrades.append(upgrade)
	
	game_ui.show_upgrade_panel(selected_upgrades)

func _on_upgrade_selected(upgrade_data: Dictionary):
	var upgrade_type = upgrade_data.get("type", 0)
	var value = upgrade_data.get("value", 0.0)
	var target_type = upgrade_data.get("target_type", 0)
	
	match upgrade_type:
		1:  # 攻速
			upgrades["attack_speed"] += value
		2:  # 攻击力
			upgrades["attack_damage"] += value
		3:  # 技能伤害
			if player and player.current_skill_slots.size() > 0:
				var random_skill = player.current_skill_slots.values()[randi() % player.current_skill_slots.size()]
				var skill_id = random_skill.skill_id
				upgrades["skill_damage"][skill_id] = upgrades["skill_damage"].get(skill_id, 0.0) + value
		4:  # 冷却速度
			if player and player.current_skill_slots.size() > 0:
				var random_skill = player.current_skill_slots.values()[randi() % player.current_skill_slots.size()]
				var skill_id = random_skill.skill_id
				upgrades["skill_cooldown"][skill_id] = upgrades["skill_cooldown"].get(skill_id, 0.0) + value
	
	if player:
		player.set_upgrades(upgrades)
	
	# 进入下一层
	current_floor += 1
	EventBus.floor_changed.emit(current_floor)
	
	# 重置击杀数，继续游戏
	kill_count = 0
	update_ui()
	
	# 清空剩余敌人
	for enemy in enemies_container.get_children():
		enemy.queue_free()

func victory():
	get_tree().paused = true
	victory_ui.visible = true

func _on_player_died():
	get_tree().paused = true
	defeat_ui.visible = true

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

func resume_game():
	toggle_pause()

func return_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu/start_menu.tscn")
