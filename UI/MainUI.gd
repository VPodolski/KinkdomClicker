extends Control

@onready var game = GameLogic  # если добавишь Game в AutoLoad

# UI элементы
@onready var gold_label = $TabContainer/MainTab/GoldLabel
@onready var gold_button = $TabContainer/MainTab/GoldButton

@onready var buildings_container = $TabContainer/MainTab/BuildingsContainer
@onready var upgrades_container = $TabContainer/ForgeTab/ScrollContainer/UpgradesContainer

var building_item_scene = preload("res://ui/BuildingItem.tscn")
var upgrade_item_scene = preload("res://ui/UpgradeItem.tscn")


func _ready():
	await get_tree().process_frame
	# подписки на события
	game.gold_changed.connect(update_gold)
	game.buildings_changed.connect(update_buildings_ui)
	game.upgrades_changed.connect(update_upgrades_ui)
	
	# первичная инициализация
	update_gold(game.economy.gold)
	create_buildings_ui()
	create_upgrades_ui()


# =========================
# 🖱️ INPUT
# =========================

func _on_gold_button_pressed():
	game.on_click()


func _on_building_pressed(index):
	game.buy_building(index)


func _on_upgrade_pressed(index):
	game.start_upgrade(index)


# =========================
# 💰 UI ОБНОВЛЕНИЕ
# =========================

func update_gold(value):
	gold_label.text = str(int(value))


# =========================
# 🏗️ BUILDINGS UI
# =========================

func create_buildings_ui():
	for child in buildings_container.get_children():
		child.queue_free()
	
	for i in range(game.buildings.buildings.size()):
		var b = game.buildings.buildings[i]
		
		var item = building_item_scene.instantiate()
		buildings_container.add_child(item)
		
		item.setup(b, i)
		item.buy_pressed.connect(_on_building_pressed)


func update_buildings_ui():
	for child in buildings_container.get_children():
		child.update_ui()


# =========================
# ⚙️ UPGRADES UI
# =========================

func create_upgrades_ui():
	for child in upgrades_container.get_children():
		child.queue_free()
	
	for i in range(game.upgrades.upgrades.size()):
		var u = game.upgrades.upgrades[i]
		
		var item = upgrade_item_scene.instantiate()
		upgrades_container.add_child(item)
		
		item.setup(u, i)
		item.craft_pressed.connect(_on_upgrade_pressed)


func update_upgrades_ui():
	for child in upgrades_container.get_children():
		child.update_ui()
	
	update_visibility()
	sort_upgrade_items()


# =========================
# 👁️ VISIBILITY
# =========================

func update_visibility():
	for child in upgrades_container.get_children():
		var u = child.upgrade
		
		if u.is_crafting:
			child.visible = true
			child.modulate.a = 1.0
			continue
		
		var max_cost = game.economy.gold * 5.0
		
		if u.cost > max_cost:
			child.visible = false
		else:
			child.visible = true
			
			if u.cost > game.economy.gold * 2:
				child.modulate.a = 0.5
			else:
				child.modulate.a = 1.0


# =========================
# 🔽 SORT
# =========================

func sort_upgrade_items():
	var items = upgrades_container.get_children()
	
	items.sort_custom(func(a, b):
		var a_can = a.upgrade.cost <= game.economy.gold
		var b_can = b.upgrade.cost <= game.economy.gold
		
		if a_can != b_can:
			return a_can
		
		return a.upgrade.cost < b.upgrade.cost
	)
	
	for i in range(items.size()):
		upgrades_container.move_child(items[i], i)
