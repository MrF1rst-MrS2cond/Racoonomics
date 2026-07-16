#extends Control

#@onready var bar_loyalty_progress: TextureProgressBar = $BarLoyalty_Progress


#func _ready():
#	Global.update_bar.connect(change_progress_bar)
#	
#func change_progress_bar(new_loyalty: int):
#	bar_loyalty_progress.value = new_loyalty
#	#print(bar_loyalty_progress.value)

extends Control

@onready var bar_loyalty_progress: TextureProgressBar = $BarLoyalty_Progress

@export_group("Animation Durations")

@export var rise_duration: float = 0.7

@export var fall_duration: float = 0.4

@export_group("Tween Behavior")

@export var transition_type: Tween.TransitionType = Tween.TRANS_CUBIC

@export var ease_type: Tween.EaseType = Tween.EASE_OUT


var current_tween: Tween


func _ready():
	Global.update_bar.connect(change_progress_bar)
	

func change_progress_bar(new_loyalty: int):
	var current_value = bar_loyalty_progress.value
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		
	var duration: float
	if new_loyalty > current_value:
		duration = rise_duration # Подъем (медленнее)
	else:
		duration = fall_duration # Падение (быстрее)
		
	current_tween = create_tween()
	current_tween.set_trans(transition_type)
	current_tween.set_ease(ease_type)
	
	current_tween.tween_property(bar_loyalty_progress, "value", new_loyalty, duration)
