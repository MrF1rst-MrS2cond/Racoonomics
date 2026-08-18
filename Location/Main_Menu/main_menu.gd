extends Node2D

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Location/location.tscn")


func _on_authors_pressed() -> void:
	get_tree().change_scene_to_file("res://Location/Main_Menu/authors.tscn")

func _on_additional_pressed() -> void:
	get_tree().change_scene_to_file("res://Location/Main_Menu/Additional.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
