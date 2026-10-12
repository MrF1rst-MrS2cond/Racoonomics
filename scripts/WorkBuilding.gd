@tool
class_name WorkBuilding
extends Building
## База для зданий с анимацией работы: фермы, лавки, кухни

const LABEL_SCENE := preload("res://UI/scenes/clikfarm.tscn")

var world_grid: WorldGrid
var worktime := 0
var running := false # цикл работы запущен
var animation_speed := 1.0

var player_path: NodePath # путь к AnimationPlayer
var anim_start: StringName
var anim_idle: StringName
var anim_work: StringName
var anim_sleep: StringName
var anim_sleep_idle: StringName

var animation_player: AnimationPlayer
var current_label: Node3D


func _extends_ready() -> void:
	world_grid = get_parent() as WorldGrid
	if not player_path.is_empty():
		animation_player = get_node_or_null(player_path) as AnimationPlayer
	set_process(false) # включается вместе с плашкой
	_on_ready()


func _on_ready() -> void: # хук для наследников
	pass


func on_click_harvest() -> void: # хук: клик по зданию
	pass


func _process(_delta: float) -> void:
	if not is_instance_valid(current_label) or not animation_player.is_playing():
		return
	var length := animation_player.current_animation_length
	if length > 0.0:
		current_label.set_progress(animation_player.current_animation_position / length)


# --- Анимации ---

func _has_anim(anim: StringName) -> bool:
	if anim == &"" or not animation_player:
		return false
	if animation_player.has_animation(anim):
		return true
	push_warning("%s: нет анимации %s" % [name, anim])
	return false


func play_anim(anim: StringName) -> void:
	if _has_anim(anim):
		animation_player.play(anim, -1, animation_speed)


## Играет и ждёт конца. false, если анимации нет
func play_wait(anim: StringName) -> bool:
	if not _has_anim(anim):
		return false
	animation_player.play(anim, -1, animation_speed)
	await animation_player.animation_finished
	return true


## Конец работы: сон или простой
func rest(sleepy: bool) -> void:
	hide_label()
	if not sleepy:
		play_anim(anim_idle)
	elif animation_player and animation_player.current_animation != anim_sleep_idle:
		await play_wait(anim_sleep)
		play_anim(anim_sleep_idle)


# --- Плашка ---

func show_label(count: int) -> void:
	if is_ghost or Engine.is_editor_hint():
		return
	if not is_instance_valid(current_label):
		current_label = LABEL_SCENE.instantiate() as Node3D
		current_label.building_owner = self
		get_tree().current_scene.add_child(current_label)
		current_label.update_label_position()
		set_process(true)
	current_label.set_count(count)


func set_label_count(count: int) -> void:
	if is_instance_valid(current_label):
		current_label.set_count(count)


func hide_label() -> void:
	if is_instance_valid(current_label):
		current_label.queue_free()
	current_label = null
	set_process(false)


# --- Хранилище ---

func take_stack(input: ItemStorage, id: StringName, amount: int) -> void:
	input.stacks[id] -= amount
	if input.stacks[id] <= 0:
		input.stacks.erase(id)


func _exit_tree() -> void:
	hide_label()
