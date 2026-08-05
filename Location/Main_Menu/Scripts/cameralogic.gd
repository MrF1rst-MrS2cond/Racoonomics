extends CharacterBody3D

@export var speedmultiplier := 1.0 ## Множитель скорости
@export var speed := 50.0 ## Скорость

#@export var mi_max_scale: Vector2 = Vector2(2, 30) ## Мин/макс высота камеры
@export var distance_bounds := Vector2(100, 500)
@export var zoom_step: float = 25 # Сделал еще больше, чтобы зум чувствовался
@export var pan_speed : float = 0.04

@onready var camera: Camera3D = $Camera3D
@onready var cam_target : float = camera.position.z

var mouse_pan : Vector2

func _process(delta: float) -> void:
	camera.position.z = lerp(camera.position.z, cam_target, 10.0 * delta)

func _physics_process(_delta: float) -> void:
	var rot = Input.get_axis("e", "q")
	rotation.y += 0.05 * rot

	if Input.is_action_pressed("shift"):
		speedmultiplier = 2.5
	else :
		speedmultiplier = 1.0

	var input_dir = Input.get_vector("a", "d", "w", "s") * speed * speedmultiplier
	input_dir += mouse_pan * pan_speed * camera.position.z
	mouse_pan = Vector2.ZERO
	var move_dir = Vector3(input_dir.x, 0, input_dir.y)

	velocity = move_dir.rotated(Vector3.UP, rotation.y)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouseScrollDown"):
		cam_target = clamp(cam_target + zoom_step, distance_bounds.x, distance_bounds.y)
	elif event.is_action_pressed("mouseScrollUp"):
		cam_target = clamp(cam_target - zoom_step, distance_bounds.x, distance_bounds.y)

	if event is InputEventMouseMotion and Input.is_action_pressed("pan"):
		mouse_pan -= event.relative
