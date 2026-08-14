@tool
extends Node3D

@onready var decal: Decal = $Decal
@onready var editor_label: Label3D = $Decal/Label3D

func _ready() -> void:
	if !Engine.is_editor_hint():
		if is_instance_valid(editor_label):
			editor_label.queue_free()

func set_is_output(value: bool) -> void:
	if value:
		decal.rotation.y = 0.0
		decal.modulate = Color("22e646")

		if Engine.is_editor_hint() and is_instance_valid(editor_label):
			editor_label.text = "OUT >>"
			editor_label.modulate = Color("22e646")
	else:
		decal.rotation.y = PI
		decal.modulate = Color("e64322")

		if Engine.is_editor_hint() and is_instance_valid(editor_label):
			editor_label.text = "IN >>"
			editor_label.modulate = Color("e64322")
