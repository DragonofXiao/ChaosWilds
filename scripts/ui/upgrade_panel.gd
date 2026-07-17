extends Control

@onready var card_container: HBoxContainer = $Panel/CardContainer
@onready var floor_label: Label = $Panel/FloorLabel
@onready var title_label: Label = $Panel/TitleLabel

var selected_upgrades: Array = []
var on_selected: Callable

func _ready() -> void:
	title_label.text = Localization.t("upgrade_title")
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_upgrades(upgrades: Array, floor: int, callback: Callable) -> void:
	selected_upgrades = upgrades
	on_selected = callback
	
	floor_label.text = Localization.t("floor") + " " + str(floor)
	
	for child in card_container.get_children():
		child.queue_free()
	
	for i in range(upgrades.size()):
		var card: Control = create_card(upgrades[i], i + 1)
		card_container.add_child(card)
	
	show()
	get_tree().paused = true

func create_card(upgrade_data: Dictionary, index: int) -> Control:
	var card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")
	var card: Control = card_scene.instantiate()
	card.setup(upgrade_data, index)
	card.card_selected.connect(_on_card_selected)
	return card

func _on_card_selected(upgrade_data: Dictionary) -> void:
	hide()
	get_tree().paused = false
	if on_selected.is_valid():
		on_selected.call(upgrade_data)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		var key_index: int = -1
		match event.keycode:
			KEY_1: key_index = 0
			KEY_2: key_index = 1
			KEY_3: key_index = 2
			KEY_4: key_index = 3
		
		if key_index >= 0 and key_index < card_container.get_child_count():
			var card: Node = card_container.get_child(key_index)
			if card and card.has_method("select"):
				card.select()
