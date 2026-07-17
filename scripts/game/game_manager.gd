extends Node2D
class_name GameManager

const TARGET_KILLS: int = 100
const SPAWN_INTERVAL: float = 3.0
const MAX_SLIMES: int = 8
const MAX_FLOORS: int = 5

var spawn_points: Array[Vector2] = [
	Vector2(16, 16),
	Vector2(304, 16),
	Vector2(160, 304)
]

var kill_count: int = 0
var spawn_timer: float = 0.0
var current_floor: int = 1
var is_paused: bool = false
var current_parts: Dictionary = {}
var upgrades: Dictionary = {
	"attack_speed": 0.0,
	"attack_damage": 0.0,
	"skill_damage": {},
	"skill_cooldown": {}
}

@onready var player: Player = $World/Player
@onready var enemies_container: Node2D = $World/Enemies
@onready var projectiles_container: Node2D = $World/Projectiles
@onready var game_ui: GameUI = $UI/GameUI
@onready var victory_ui: Control = $UI/VictoryUI
@onready var defeat_ui: Control = $UI/DefeatUI
@onready var pause_menu: Control = $UI/PauseMenu
@onready var upgrade_panel: Control = $UI/UpgradePanel
@onready var tutorial_panel: Control = $UI/TutorialPanel
@onready var world: Node2D = $World

func _ready() -> void:
	if player:
		player.hp_changed.connect(_on_hp_changed)
		player.player_died.connect(_on_player_died)
		player.parts_applied.connect(_on_parts_applied)
		player.set_upgrades(upgrades)
	
	_apply_new_floor(false)
	spawn_initial_enemies()
	update_ui()
	if player:
		game_ui.update_hp(player.current_hp, player.max_hp)
	_show_tutorial_if_needed()

func _randomize_parts() -> Dictionary:
	var all_parts: Array = DataManager.get_body_parts()
	all_parts.shuffle()
	
	var result: Dictionary = {}
	for part in all_parts:
		var pos: int = part.get("position", 0)
		if not result.has(pos) and result.size() < 4:
			result[pos] = part
		if result.size() >= 4:
			break
	return result

func _apply_new_floor(increment_floor: bool) -> void:
	if increment_floor:
		current_floor += 1
		EventBus.floor_changed.emit(current_floor)
	
	var parts: Dictionary = _randomize_parts()
	current_parts = parts
	if player:
		player.apply_parts(parts)

func _on_parts_applied(parts: Dictionary, attack_type: String) -> void:
	game_ui.update_skills(player.get_skill_display_data())
	game_ui.update_attack_type(attack_type)
	game_ui.update_parts(parts)

func _show_tutorial_if_needed() -> void:
	if SettingsManager.has_seen_tutorial():
		return
	if tutorial_panel and tutorial_panel.has_method("show_tutorial"):
		tutorial_panel.show_tutorial()
	SettingsManager.set_tutorial_seen()

func toggle_pause() -> void:
	get_tree().paused = !get_tree().paused
	if pause_menu:
		pause_menu.visible = get_tree().paused

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	
	if kill_count >= TARGET_KILLS:
		return
	
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		if enemies_container.get_child_count() < MAX_SLIMES:
			spawn_enemy()

func spawn_initial_enemies() -> void:
	for i in range(3):
		spawn_enemy()

func spawn_enemy() -> void:
	var enemy_scene: PackedScene = preload("res://scenes/game/enemy.tscn")
	var enemy: Node = enemy_scene.instantiate()
	
	var spawn_point: Vector2 = spawn_points[randi() % spawn_points.size()]
	enemy.global_position = spawn_point
	enemy.died.connect(_on_enemy_died)
	
	if current_floor >= 2:
		enemy.set_hp_multiplier(2.0)
	
	enemies_container.add_child(enemy)

func _on_enemy_died() -> void:
	kill_count += 1
	update_ui()
	
	if kill_count >= TARGET_KILLS and enemies_container.get_child_count() == 0:
		if current_floor >= MAX_FLOORS:
			victory()
		else:
			show_upgrade_panel()

func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	game_ui.update_hp(current_hp, max_hp)

func update_ui() -> void:
	game_ui.update_kill_count(kill_count, TARGET_KILLS)
	game_ui.update_floor(current_floor)

func show_upgrade_panel() -> void:
	var selected_upgrades: Array = []
	for group_id in range(1, 5):
		var upgrade: Dictionary = DataManager.get_random_upgrade_from_group(group_id)
		if not upgrade.is_empty():
			selected_upgrades.append(upgrade)
	
	if upgrade_panel and upgrade_panel.has_method("show_upgrades"):
		upgrade_panel.show_upgrades(selected_upgrades, current_floor, _on_upgrade_selected)

func _on_upgrade_selected(upgrade_data: Dictionary) -> void:
	var upgrade_type: int = upgrade_data.get("type", 0)
	var value: float = upgrade_data.get("value", 0.0)
	
	match upgrade_type:
		1:
			upgrades["attack_speed"] += value
		2:
			upgrades["attack_damage"] += value
		3:
			if player and player.current_skill_slots.size() > 0:
				var random_skill: SkillBase = player.current_skill_slots.values()[randi() % player.current_skill_slots.size()]
				var skill_id: int = random_skill.skill_id
				upgrades["skill_damage"][skill_id] = upgrades["skill_damage"].get(skill_id, 0.0) + value
		4:
			if player and player.current_skill_slots.size() > 0:
				var random_skill: SkillBase = player.current_skill_slots.values()[randi() % player.current_skill_slots.size()]
				var skill_id: int = random_skill.skill_id
				upgrades["skill_cooldown"][skill_id] = upgrades["skill_cooldown"].get(skill_id, 0.0) + value
	
	if player:
		player.set_upgrades(upgrades)
	
	kill_count = 0
	update_ui()
	
	for enemy in enemies_container.get_children():
		enemy.queue_free()
	
	_apply_new_floor(true)
	spawn_initial_enemies()

func victory() -> void:
	get_tree().paused = true
	victory_ui.visible = true

func _on_player_died() -> void:
	get_tree().paused = true
	defeat_ui.visible = true

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func resume_game() -> void:
	toggle_pause()

func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu/start_menu.tscn")
