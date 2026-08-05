extends Control

var info_current_building: Building
var info_current_building_definition: BuildingDefinition
var is_permission_for_uprade = false

@export var start_build_definition: BuildingDefinition
var buy_build_definition: BuildingDefinition
signal unlockwall
var TabTween: Tween
var is_tab_open: bool = false
@export var all_buildings_catalog: Array[BuildingDefinition] = []
@export var tab_hotbar_purchase_options: Array[BuildingDefinition] = []
var first_visible_option_position: int = 0

var buttons_list: Array[PurchaseOption]

@onready var bar_loyalty: Control = $BarLoyalty
@onready var tab_hotbar: Control = $TabHotbar
@onready var money_manager: Node = $"../../MoneyManager"

@onready var open_hotbar: Button = $TabHotbar/OpenHotbar

@onready var description_popup: Control = $DescriptionPopup

@onready var building_icon: TextureRect = $DescriptionPopup/Building_icon
@onready var build_name: Label = $DescriptionPopup/Name
@onready var description: Label = $DescriptionPopup/Description
@onready var sell_price: Label = $DescriptionPopup/BtSell/Sell_price
@onready var upgrade_button: Button = $DescriptionPopup/BtUpgrade


@onready var world_grid: WorldGrid = $"../../WorldGrid"
@onready var build_mode_controller: Node = $"../../BuildModeController"

@onready var tab_purchase: Control = $TabPurchase
@onready var bt_close: Button = $TabPurchase/BtClose
@onready var TabPurchasetitle: Label = $TabPurchase/Title
@onready var TabPurchasedescription: Label = $TabPurchase/Description
@onready var TabPurchaseCostTitle: Label = $TabPurchase/BuyButton/Title
@onready var buy_button: Button = $TabPurchase/BuyButton

@onready var arrow_left: Button = $"TabHotbar/9Panel/HBC/ArrowLeft"
@onready var arrow_right: Button = $"TabHotbar/9Panel/HBC/ArrowRight"




func _ready() -> void:
	arrow_left.button_up.connect(TabHotbarUpdatePosition.bind(-1))
	arrow_right.button_up.connect(TabHotbarUpdatePosition.bind(1))
	buy_button.button_up.connect(TabPurchaseBuy)
	open_hotbar.button_up.connect(TabToggle)
	bt_close.pressed.connect(PurchaseTabClose)
	description_popup.hide()
	tab_purchase.hide()

	var buttons = get_tree().get_nodes_in_group("purchasebutton")
	for button in buttons:
		if button is PurchaseOption:
			buttons_list.append(button)
			button.PurchaseOptionPressed.connect(PurchaseTabOpen)
	
	refresh_unlocked_buildings()

func refresh_unlocked_buildings():
	tab_hotbar_purchase_options.clear()
	var current_hub_level = _get_current_hub_level()
	for build_def in all_buildings_catalog:
		if build_def:
			if build_def.required_hub_level <= current_hub_level:
				tab_hotbar_purchase_options.append(build_def)
	UpdatePurchases()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("bm_enter"):
		TabToggle()

	if event.is_action_pressed("bm_exit"):
		TabHotbarClose()
		closeDescription()
		PurchaseTabClose()

	if event.is_action_pressed("quick_sell"):
		sell_building()


func UpdatePurchases():
	var index = 0
	for button in buttons_list:
		var target_idx = index + first_visible_option_position
		if target_idx < tab_hotbar_purchase_options.size():
			var build_def = tab_hotbar_purchase_options[target_idx]
			if build_def:
				button.definition = build_def
				button.update_visuals()
				button.show()
		else:
			button.hide() 
		index += 1 

func _get_current_hub_level() -> int:
	for building in world_grid.buildings_cache:
		if is_instance_valid(building) and building is Hub:
			return building.Hublevel
	return 1

func TabHotbarUpdatePosition(change: int):
	var max_scroll = max(0, tab_hotbar_purchase_options.size() - buttons_list.size())
	var updated_pos = clamp(first_visible_option_position + change, 0, max_scroll)

	first_visible_option_position = updated_pos
	UpdatePurchases()

func openDescription(build_def: BuildingDefinition):
	info_current_building_definition = build_def
	build_name.text = build_def.title
	building_icon.texture = build_def.shop_icon
	description.text = build_def.description
	sell_price.text = "[Space]  Продать + " + str(build_def.purchase_cost) + "M"
	var sell_button_node = sell_price.get_parent() as Button
	if info_current_building is Hub:
		if sell_button_node:
			sell_button_node.hide()
		if Global.is_loyality_max:
			upgrade_button.show()
			upgrade_button.disabled = false
			upgrade_button.use_parent_material = true
			upgrade_button.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			upgrade_button.show()
			upgrade_button.use_parent_material = false
			upgrade_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description.text = build_def.description + "\nТекущий уровень: " + str(info_current_building.Hublevel)
	else:
		if sell_button_node: sell_button_node.show()
		upgrade_button.show()
		var current_hub_level := _get_current_hub_level()
		var building_upgrade_stage := 1
		if "upgrade_chek" in info_current_building:
			building_upgrade_stage = info_current_building.upgrade_chek
		var has_upgrade_tree := !!build_def.upgrades_to
		var is_hub_unlocked := current_hub_level >= 3
		var is_single_upgrade_allowed := (current_hub_level >= 7) or (building_upgrade_stage < 2)
		var can_upgrade := has_upgrade_tree and is_hub_unlocked and is_single_upgrade_allowed
		if can_upgrade:
			upgrade_button.disabled = false
			upgrade_button.use_parent_material = true
			upgrade_button.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			upgrade_button.show()
			upgrade_button.use_parent_material = false
			upgrade_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_popup.show()

func closeDescription():
	description_popup.hide()

func _on_bt_close_pressed() -> void:
	closeDescription()


func _on_bt_sell_pressed() -> void:
	sell_building()


func sell_building() -> void:
	if !info_current_building or info_current_building is Hub:
		return
	# Пока что возвращает только ценник ПОКУПКИ, ценник улучшений(upgrade_cost) пока что не возвращает

	# suggestion: add all previous upgrade costs to the current building's price in advance manually
	# i.e. lv1 ($10 to purchase, $5 to upgrade) -> lv2 ($(10 + 5 = 15) to purchase, $10 to upgrade) -> lv3 ($25P, $15U) -> sell lv3, get $25 back
	# since the player won't be purchasing a new building every time they upgrade i think this makes sense

	money_manager.money += info_current_building_definition.purchase_cost
	world_grid.buildings_cache.erase(info_current_building)
	var rect = Rect2i(info_current_building.origin_cell.x, info_current_building.origin_cell.y, info_current_building.dimensions.x, info_current_building.dimensions.y)
	world_grid._free_rect(rect)
	info_current_building.queue_free()
	info_current_building = null
	info_current_building_definition = null
	closeDescription()

func upgrade_building() -> void:
	if !info_current_building:
		return
	if info_current_building is Hub:
		if Global.is_loyality_max:
			info_current_building.Hublevel += 1
			Global.is_loyality_max = false
			Global.on_hub_level_changed()
			refresh_unlocked_buildings()
			if info_current_building.Hublevel >= 5:
				unlockwall.emit()
		if info_current_building_definition:
			description.text = info_current_building_definition.description + "\nТекущий уровень: " + str(info_current_building.Hublevel)
		return 
	if !info_current_building_definition or !info_current_building_definition.upgrades_to:
		return
	var current_hub_level := _get_current_hub_level()
	
	if current_hub_level < 3:
		return
	var building_upgrade_stage := 1
	if "upgrade_chek" in info_current_building:
		building_upgrade_stage = info_current_building.upgrade_chek
	if current_hub_level < 7 and building_upgrade_stage >= 2:
		return
	if money_manager.money < info_current_building_definition.upgrade_cost:
		return
	

	var old_origin := info_current_building.origin_cell
	#if current_hub_level >= 3 and current_hub_level <=6:
		#if info_current_building_definition.required_hub_level <2:
	if info_current_building.upgrade():
		money_manager.check_cost(info_current_building_definition.upgrade_cost)
		info_current_building = world_grid.get_building_at_cell(old_origin) as Building
		info_current_building_definition = info_current_building_definition.upgrades_to
		if "upgrade_chek" in info_current_building:
			info_current_building.upgrade_chek = building_upgrade_stage + 1
		closeDescription()

func PurchaseTabOpen(build_definition: BuildingDefinition):
	tab_purchase.show()
	buy_build_definition = build_definition
	TabPurchasetitle.text = build_definition.title
	TabPurchasedescription.text = build_definition.description
	TabPurchaseCostTitle.text = str(build_definition.purchase_cost) + "M"

func PurchaseTabClose():
	tab_purchase.hide()

func TabPurchaseBuy():
	PurchaseTabClose()
	build_mode_controller.enter_build_mode(buy_build_definition)

func TabToggle():
	if is_tab_open:
		TabHotbarClose()
	else:
		TabHotbarOpen()

func TabTweenCheck():
	if TabTween:
		TabTween.kill()

func TabHotbarOpen():
	TabTweenCheck()
	if buy_build_definition:
		build_mode_controller.enter_build_mode(buy_build_definition)
	else:
		build_mode_controller.enter_build_mode(start_build_definition)
	is_tab_open = true
	TabTween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	TabTween.tween_property(tab_hotbar,"position", Vector2(0.0,tab_hotbar.position.y), 0.5)

func TabHotbarClose():
	if build_mode_controller.current_building:
		build_mode_controller.exit_build_mode()
	TabTweenCheck()
	is_tab_open = false
	TabTween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	TabTween.tween_property(tab_hotbar,"position", Vector2(-1430.0,tab_hotbar.position.y), 0.3)
