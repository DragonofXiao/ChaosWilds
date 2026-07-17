extends Panel

@onready var name_label: Label = $NameLabel
@onready var desc_label: Label = $DescLabel
@onready var key_label: Label = $KeyLabel
@onready var icon: ColorRect = $Icon

var upgrade_data: Dictionary
var index: int = 0

signal card_selected(upgrade_data: Dictionary)

func setup(data: Dictionary, idx: int):
	upgrade_data = data
	index = idx
	
	var name_key = data.get("name_key", "")
	name_label.text = Localization.t(name_key)
	
	var type = data.get("type", 0)
	var value = data.get("value", 0.0)
	var desc = ""
	match type:
		1: desc = Localization.t("upgrade_desc_attack_speed") + (" +%d%%" % int(value * 100))
		2: desc = Localization.t("upgrade_desc_attack_damage") + (" +%d%%" % int(value * 100))
		3: desc = Localization.t("upgrade_desc_skill_damage") + (" +%d%%" % int(value * 100))
		4: desc = Localization.t("upgrade_desc_cooldown") + (" +%d%%" % int(value * 100))
	desc_label.text = desc
	
	key_label.text = str(index)
	
	match type:
		1: icon.color = Color(0.2, 0.8, 1.0)
		2: icon.color = Color(1.0, 0.3, 0.3)
		3: icon.color = Color(1.0, 0.6, 0.1)
		4: icon.color = Color(0.3, 1.0, 0.3)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func get_icon_name(type: int) -> String:
	match type:
		1: return "speed"
		2: return "damage"
		3: return "skill"
		4: return "cooldown"
	return "default"

func _on_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	modulate = Color.WHITE

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select()

func select():
	card_selected.emit(upgrade_data)
