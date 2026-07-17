extends CanvasLayer
class_name GameUI

const SKILL_ACTION_MAP: Dictionary = {
	"q": "skill_q",
	"e": "skill_e",
	"r": "skill_r",
	"space": "skill_space"
}

@onready var hp_label: Label = $HpPanel/HpLabel
@onready var hp_bar: ProgressBar = $HpPanel/HpBar
@onready var kill_label: Label = $KillPanel/KillLabel
@onready var attack_type_label: Label = $HpPanel/AttackTypeLabel
@onready var floor_label: Label = $FloorPanel/FloorLabel
@onready var parts_label: Label = $PartsPanel/PartsLabel

@onready var skill_slots: Dictionary = {
	"q": $SkillPanel/SkillSlot1,
	"e": $SkillPanel/SkillSlot2,
	"r": $SkillPanel/SkillSlot3,
	"space": $SkillPanel/SkillSlot4
}

func _ready() -> void:
	setup_skill_slots()
	if not EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.connect(_on_language_changed)

func setup_skill_slots() -> void:
	var slot_configs: Dictionary = {
		"q": {"key": "Q", "name": t("skill_aura")},
		"e": {"key": "E", "name": t("skill_breath")},
		"r": {"key": "R", "name": t("skill_burst")},
		"space": {"key": "SPACE", "name": t("skill_dash")}
	}
	
	for action in slot_configs:
		var slot: SkillSlot = skill_slots.get(action)
		if slot:
			slot.setup(slot_configs[action]["key"], slot_configs[action]["name"])

func t(key: String) -> String:
	return Localization.t(key)

func update_hp(current: int, max_val: int) -> void:
	hp_label.text = "%s: %d/%d" % [t("hp"), current, max_val]
	hp_bar.value = float(current) / max_val * 100.0

func update_kill_count(current: int, target: int) -> void:
	kill_label.text = "%s: %d / %d" % [t("kills"), current, target]

func update_skill_cooldown(action: String, percent: float, display: int) -> void:
	var slot: SkillSlot = skill_slots.get(action)
	if slot:
		slot.update_cooldown(percent, display)

func update_skills(skill_info: Dictionary) -> void:
	for ui_action in skill_slots:
		var mapped_action: String = SKILL_ACTION_MAP.get(ui_action, ui_action)
		var slot: SkillSlot = skill_slots.get(ui_action)
		if slot and skill_info.has(mapped_action):
			var info: Dictionary = skill_info[mapped_action]
			slot.setup(info.get("key", ""), info.get("name", ""))

func update_attack_type(type: String) -> void:
	match type:
		"fire":
			attack_type_label.text = t("attack_type_fire")
			attack_type_label.modulate = Color(1.0, 0.5, 0.2)
		"ice":
			attack_type_label.text = t("attack_type_ice")
			attack_type_label.modulate = Color(0.4, 0.8, 1.0)
		_:
			attack_type_label.text = t("attack_type_physical")
			attack_type_label.modulate = Color(0.9, 0.9, 0.9)

func update_parts(parts: Dictionary) -> void:
	var names: PackedStringArray = []
	for pos in range(1, 5):
		var part: Dictionary = parts.get(pos, {})
		if not part.is_empty():
			names.append(part.get("name", ""))
	parts_label.text = "%s: %s" % [t("parts_title"), ", ".join(names)]

func update_floor(floor: int) -> void:
	floor_label.text = "%s %d" % [t("floor"), floor]

func _process(_delta: float) -> void:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("get_skill_cooldown"):
		for ui_action in skill_slots:
			var mapped_action: String = SKILL_ACTION_MAP.get(ui_action, ui_action)
			var cooldown_info: Dictionary = player_node.get_skill_cooldown(mapped_action)
			if cooldown_info:
				update_skill_cooldown(
					ui_action,
					cooldown_info["percent"],
					cooldown_info["display"]
				)

func _on_language_changed() -> void:
	setup_skill_slots()
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("get_skill_display_data"):
		update_skills(player_node.get_skill_display_data())
	if player_node and "attack_type" in player_node:
		update_attack_type(player_node.attack_type)
