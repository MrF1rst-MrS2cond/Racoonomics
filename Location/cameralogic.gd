extends CharacterBody3D

@export var speedmultiplier := 1.0
@export var speed := 50.0

@export var distance_bounds := Vector2(100, 500)
@export var zoom_step: float = 25.0
@export var pan_speed : float = 0.04
@export var touch_pan_speed : float = 0.002 # Отдельная чувствительность для тачскрина

@onready var camera: Camera3D = $Camera3D
@onready var cam_target : float = camera.position.z

var mouse_pan : Vector2
var touches : Dictionary = {} # Хранит позиции активных касаний: { index: Vector2 }
var initial_touch_distance : float = 0.0


func _process(delta: float) -> void:
	camera.position.z = lerp(camera.position.z, cam_target, 10.0 * delta)


func _physics_process(_delta: float) -> void:
	var rot = Input.get_axis("e", "q")
	rotation.y += 0.05 * rot

	if Input.is_action_pressed("shift"):
		speedmultiplier = 2.5
	else:
		speedmultiplier = 1.0

	var input_dir = Input.get_vector("a", "d", "w", "s") * speed * speedmultiplier
	input_dir += mouse_pan * pan_speed * camera.position.z
	mouse_pan = Vector2.ZERO
	var move_dir = Vector3(input_dir.x, 0, input_dir.y)

	velocity = move_dir.rotated(Vector3.UP, rotation.y)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# 1. ПК-управление (Колесико и Зажатие мыши)
	if event.is_action_pressed("mouseScrollDown"):
		cam_target = clamp(cam_target + zoom_step, distance_bounds.x, distance_bounds.y)
	elif event.is_action_pressed("mouseScrollUp"):
		cam_target = clamp(cam_target - zoom_step, distance_bounds.x, distance_bounds.y)

	if event is InputEventMouseMotion and Input.is_action_pressed("pan"):
		mouse_pan -= event.relative

	# 2. Мобильное управление (Touch Events)
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			if touches.size() < 2:
				initial_touch_distance = 0.0

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() >= 2:
			mouse_pan -= event.relative * touch_pan_speed

			var touch_keys = touches.keys()
			var current_dist = touches[touch_keys[0]].distance_to(touches[touch_keys[1]])

			if initial_touch_distance > 0.0:
				var zoom_delta = initial_touch_distance - current_dist
				cam_target = clamp(cam_target + zoom_delta * 0.5, distance_bounds.x, distance_bounds.y)
			
			initial_touch_distance = current_dist
