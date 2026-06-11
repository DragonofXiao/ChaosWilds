extends Panel
class_name SkillSlot

@onready var key_label: Label = $KeyLabel
@onready var name_label: Label = $NameLabel
@onready var cooldown_overlay: TextureRect = $CooldownOverlay
@onready var cooldown_timer: Label = $CooldownOverlay/CooldownTimer

func setup(key: String, skill_name: String):
	key_label.text = key
	name_label.text = skill_name

func update_cooldown(percent: float, display: int):
	if percent > 0:
		cooldown_overlay.visible = true
		cooldown_timer.text = str(display)
	else:
		cooldown_overlay.visible = false
