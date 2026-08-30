@tool
extends FarmsClass

# Загружаем сцену таблички
var label_scene: PackedScene = preload("res://UI/scenes/clikfarm.tscn") # Укажите ваш путь к ClickLabel.tscn
var current_label: Node3D = null

var world_grid : WorldGrid
#var produce_buffer := 0
var animation_speed: float = 1.0


@onready var animation_player: AnimationPlayer = $Anim_Farm_Apple_lvl1/Anim_Farm_Apple_lvl1/AnimationPlayer

func _extends_ready() -> void:
	var parent_grid := get_parent() as WorldGrid
	if parent_grid:
		world_grid = parent_grid

	if !is_ghost:
		pass
		#animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking", -1, animation_speed)
	animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleIdle",-1,animation_speed)


func on_click_harvest():
	# Управление спавном / удалением таблички при клике
	_toggle_click_label()

	click_queue += 1
	if !animation_player.is_playing() or animation_player.current_animation != &"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking":
		_process_queue()


## Переключение состояния таблички (спавн / удаление)
func _toggle_click_label() -> void:
	# Если режим призрака (постройка) или редактор — не спавним UI
	if is_ghost or Engine.is_editor_hint():
		return

	# Если табличка уже открыта — удаляем её при повторном клике
	if is_instance_valid(current_label):
		current_label.queue_free()
		current_label = null
		return

	# Инстанцируем и добавляем в глобальную сцену
	current_label = label_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(current_label)
	
	# Передаем ссылку на текущую ферму
	if "building_owner" in current_label:
		current_label.building_owner = self


func _process_queue() -> void:
	while click_queue > 0:
		animation_player.play(&"Anim_Farm_Apple_lvl1|Anim_Farm_Apple_lvl1|AppleTaking", -1, animation_speed)
		await animation_player.animation_finished
		storage[&"apples_out"].put(Global.get_type("apples"), 9)
		click_queue -= 1


## Удаляем табличку с карты, если само здание удаляют/продают
func _exit_tree() -> void:
	if is_instance_valid(current_label):
		current_label.queue_free()
