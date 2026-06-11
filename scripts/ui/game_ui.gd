extends CanvasLayer
class_name GameUI

@onready var hp_label: Label = $HpPanel/HpLabel
@onready var hp_bar: ProgressBar = $HpPanel/HpBar
@onready var kill_label: Label = $KillPanel/KillLabel

@onready var skill_slots = {
	"q": $SkillPanel/SkillSlot1,
	"e": $SkillPanel/SkillSlot2,
	"r": $SkillPanel/SkillSlot3,
	"space": $SkillPanel/SkillSlot4
}

func _ready():
	setup_skill_slots()

func setup_skill_slots():
	var slot_configs = {
		"q": {"key": "Q", "name": "skill_aura"},
		"e": {"key": "E", "name": "skill_breath"},
		"r": {"key": "R", "name": "skill_burst"},
		"space": {"key": "SPACE", "name": "skill_dash"}
	}
	
	for action in slot_configs:
		var slot = skill_slots.get(action)
		if slot:
			slot.setup(slot_configs[action]["key"], t(slot_configs[action]["name"]))

func t(key: String) -> String:
	return Localization.t(key)

func update_hp(current: int, max_val: int):
	hp_label.text = "%s: %d/%d" % [t("hp"), current, max_val]
	hp_bar.value = float(current) / max_val * 100

func update_kill_count(current: int, target: int):
	kill_label.text = "%s: %d / %d" % [t("kill_count"), current, target]

func update_skill_cooldown(action: String, percent: float, display: int):
	var slot = skill_slots.get(action)
	if slot:
		slot.update_cooldown(percent, display)

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_skill_cooldown"):
		for action in skill_slots:
			var cooldown_info = player.get_skill_cooldown(action)
			if cooldown_info:
				update_skill_cooldown(action, cooldown_info["percent"], cooldown_info["display"])
