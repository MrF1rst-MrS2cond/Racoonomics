extends StaticBody3D

func _ready() -> void:
	%Main_UI.unlockwall.connect(unlockwall)
	$"../../Main_UI/Main_UI/CheatConsole".unlockwall_2.connect(unlockwall)

func unlockwall():
	queue_free()
