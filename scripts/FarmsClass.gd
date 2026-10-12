@tool
class_name FarmsClass
extends WorkBuilding
## База ферм. Уровень 1 - очередь кликов, 2 - пачка по 12, 3 - работает сама

var coefficient := 2
var click_queue := 0

var level := 1
var item_id: StringName # что производит, напр. &"apples"
var base_amount := 9

var out_key: StringName
var yield_amount: int


func _on_ready() -> void:
	out_key = StringName("%s_out" % item_id)
	yield_amount = base_amount * int(pow(coefficient, level - 1)) # 9 / 18 / 36
	play_anim(anim_idle)


func on_click_harvest() -> void:
	match level:
		1:
			click_queue += 1
			show_label(click_queue)
			if not running:
				_run_queue()
		2:
			worktime = 12
			show_label(worktime)
			if not running:
				_run_batch()
		_:
			if not running:
				_run_auto()


func _put() -> void:
	storage[out_key].put(Global.get_type(item_id), yield_amount)


func _run_queue() -> void:
	running = true
	while click_queue > 0:
		await play_wait(anim_work)
		_put()
		click_queue -= 1
		set_label_count(click_queue)
	hide_label()
	running = false


func _run_batch() -> void:
	running = true
	while worktime > 0:
		await play_wait(anim_work)
		_put()
		worktime -= 1
		set_label_count(worktime)
		if worktime == 0:
			hide_label()
			await play_wait(anim_sleep)
			if worktime == 0: # не кликнули во сне
				play_anim(anim_sleep_idle)
	running = false


func _run_auto() -> void:
	running = true
	while is_inside_tree():
		if not await play_wait(anim_work): # нет анимации - стоп
			break
		_put()
	running = false
