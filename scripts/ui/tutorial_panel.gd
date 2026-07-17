extends Control

@onready var label: Label = $Panel/Label

func show_tutorial() -> void:
	label.text = Localization.t("tutorial_welcome")
	visible = true
	modulate = Color(1, 1, 1, 1)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5).set_delay(3.0)
	tween.tween_callback(func() -> void: visible = false)
