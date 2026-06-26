class_name UpgradeManager

var upgrades: Array[UpgradeData] = []
var active_upgrades: Array[UpgradeData] = []

var game: Node

func _init(_game: Node):
	game = _game
	_init_upgrades()

func _init_upgrades():
	var file = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			for u in data:
				var target = u.get("target", "")
				var source_building = u.get("source_building", "")
				var req_building = u.get("req_building", "")
				var req_count = u.get("req_count", 0)
				upgrades.append(UpgradeData.new(
					u["name"], u["description"], float(u["cost"]), float(u["base_time"]),
					u["effect_type"], float(u["effect_value"]), target, source_building, req_building, int(req_count)
				))
		else:
			print("Error parsing upgrades.json: ", json.get_error_message())
	else:
		print("Failed to open upgrades.json")

	var tiers = [
		{"count": 1, "metal_name": "Железные", "cost_mult": 10, "time": 15.0},
		{"count": 10, "metal_name": "Стальные", "cost_mult": 100, "time": 30.0},
		{"count": 50, "metal_name": "Чугунные", "cost_mult": 500, "time": 60.0},
		{"count": 100, "metal_name": "Кованые", "cost_mult": 2500, "time": 120.0},
		{"count": 200, "metal_name": "Титановые", "cost_mult": 10000, "time": 300.0},
		{"count": 300, "metal_name": "Мифриловые", "cost_mult": 50000, "time": 600.0},
		{"count": 400, "metal_name": "Адамантитовые", "cost_mult": 200000, "time": 1200.0},
		{"count": 500, "metal_name": "Метеоритные", "cost_mult": 1000000, "time": 2400.0}
	]

	var b_items = {
		"farm": ["Ферма", "I", "плуги", 30],
		"sawmill": ["Лесопилка", "I", "пилы", 150],
		"quarry": ["Каменоломня", "I", "кирки", 750],
		"forge": ["Кузница", "I", "молоты", 3000],
		"market": ["Рынок", "I", "весы", 12000],
		"scout_guild": ["Гильдия разведчиков", "N", "кинжалы", 30000],
		"barracks": ["Казармы", "N", "мечи", 150000],
		"tavern": ["Таверна", "I", "кружки", 300000],
		"chapel": ["Часовня", "N", "алтари", 1500000],
		"training_camp": ["Тренировочный лагерь", "N", "манекены", 6000000],
		"church": ["Церковь", "N", "колокола", 30000000],
		"guild": ["Гильдия", "I", "сейфы", 45000000],
		"armory": ["Оружейная", "N", "доспехи", 75000000],
		"bank": ["Банк", "I", "хранилища", 750000000],
		"temple": ["Храм", "N", "статуи", 1500000000],
		"archery_range": ["Стрельбище", "N", "наконечники стрел", 3000000000],
		"port": ["Порт", "I", "якоря", 15000000000],
		"cathedral": ["Собор", "N", "кресты", 30000000000],
		"stables": ["Конюшни", "N", "подковы", 150000000000],
		"shipyard": ["Верфь", "I", "гвозди", 300000000000],
		"grand_cathedral": ["Великий собор", "N", "врата", 1500000000000],
		"alchemy_lab": ["Лаборатория Алхимии", "I", "тигли", 6000000000000],
		"knight_order": ["Орден рыцарей", "N", "копья", 7500000000000],
		"mage_tower": ["Башня Магов", "I", "посохи", 150000000000000],
		"patriarchal_cathedral": ["Патриарший собор", "N", "реликвии", 300000000000000],
		"griffon_nest": ["Гнездо грифонов", "N", "цепи", 1500000000000000],
		"castle": ["Замок", "I", "решетки", 3000000000000000],
		"wonders": ["Чудеса Света", "I", "каркасы", 150000000000000000],
		"archeology_guild": ["Гильдия археологов", "N", "лопаты", 100000000]
	}

	for b_id in b_items.keys():
		var b_data = b_items[b_id]
		var b_name = b_data[0]
		var b_cat = b_data[1]
		var b_item = b_data[2]
		var b_base = float(b_data[3])
		
		for i in range(8):
			var t = tiers[i]
			var u_name = "%s %s (%s)" % [t["metal_name"], b_item, b_name]
			var u_cost = b_base * t["cost_mult"]
			var u_time = t["time"]
			var u_desc = ""
			var e_type = ""
			var e_val = 0.0
			var target = ""
			var source = ""
			
			if b_cat == "I":
				if i == 0:
					e_type = "income_multiplier"
					e_val = 0.5
					target = b_name
					u_desc = "Увеличивает доход здания %s на 50%%." % b_name
				elif i == 1:
					e_type = "global_multiplier"
					e_val = 0.05
					u_desc = "Общий доход увеличивается на 5%%."
				elif i == 2:
					e_type = "income_multiplier"
					e_val = 1.0
					target = b_name
					u_desc = "Увеличивает доход здания %s на 100%%." % b_name
				elif i == 3:
					e_type = "building_synergy"
					e_val = 0.02
					target = b_name
					source = "Кузница"
					u_desc = "Каждая Кузница увеличивает доход здания %s на 2%%." % b_name
				elif i == 4:
					e_type = "income_multiplier"
					e_val = 2.0
					target = b_name
					u_desc = "Увеличивает доход здания %s на 200%%." % b_name
				elif i == 5:
					e_type = "click_from_income"
					e_val = 0.01
					u_desc = "Клик приносит дополнительно 1%% от текущего дохода."
				elif i == 6:
					e_type = "building_discount"
					e_val = 0.1
					target = b_name
					u_desc = "Снижает цену на %s на 10%%." % b_name
				elif i == 7:
					e_type = "income_multiplier"
					e_val = 5.0
					target = b_name
					u_desc = "Увеличивает доход здания %s на 500%%." % b_name
			else:
				if i == 0:
					e_type = "building_discount"
					e_val = 0.05
					target = b_name
					u_desc = "Снижает цену на %s на 5%%." % b_name
				elif i == 1:
					e_type = "global_multiplier"
					e_val = 0.05
					u_desc = "Общий доход увеличивается на 5%%."
				elif i == 2:
					e_type = "forge_speed"
					e_val = 0.05
					u_desc = "Скорость кузницы увеличивается на 5%%."
				elif i == 3:
					e_type = "building_discount"
					e_val = 0.1
					target = b_name
					u_desc = "Снижает цену на %s на 10%%." % b_name
				elif i == 4:
					e_type = "click_from_income"
					e_val = 0.01
					u_desc = "Клик приносит дополнительно 1%% от текущего дохода."
				elif i == 5:
					e_type = "global_multiplier"
					e_val = 0.1
					u_desc = "Общий доход увеличивается на 10%%."
				elif i == 6:
					e_type = "building_discount"
					e_val = 0.15
					target = b_name
					u_desc = "Снижает цену на %s на 15%%." % b_name
				elif i == 7:
					e_type = "forge_speed"
					e_val = 0.1
					u_desc = "Скорость кузницы увеличивается на 10%%."
			
			upgrades.append(UpgradeData.new(
				u_name, u_desc, u_cost, u_time,
				e_type, e_val, target, source, b_id, t["count"]
			))
			
	upgrades.sort_custom(func(a, b): return a.cost.is_less_than(b.cost))

func reset():
	var seen_upgrades = []
	for u in upgrades:
		if u.has_been_seen:
			seen_upgrades.append(u.name)
	for u in active_upgrades:
		if u.has_been_seen:
			seen_upgrades.append(u.name)

	active_upgrades.clear()
	upgrades.clear()
	_init_upgrades()
	
	for u in upgrades:
		if u.name in seen_upgrades:
			u.has_been_seen = true

func apply_upgrade(upgrade):
	EffectSystem.apply(game, upgrade)

func update_crafting(delta, forge_speed):
	var completed_any = false
	var completed_list = []
	for i in range(upgrades.size() - 1, -1, -1):
		var upgrade = upgrades[i]
		if upgrade.is_crafting:
			upgrade.progress += delta * forge_speed
			
			if upgrade.progress >= upgrade.base_time:
				apply_upgrade(upgrade)
				active_upgrades.append(upgrade)
				completed_list.append(upgrade)
				upgrades.remove_at(i)
				completed_any = true

	if completed_any:
		if game.get("buildings"):
			game.buildings.update_synergies(active_upgrades)
		if game.has_method("recalculate_income"):
			game.recalculate_income()
		if game.has_signal("upgrades_changed"):
			game.upgrades_changed.emit()
			
		for upgrade in completed_list:
			if game.has_method("emit_upgrade_completed"):
				game.emit_upgrade_completed(upgrade)

func complete_upgrade(upgrade):
	apply_upgrade(upgrade)
	active_upgrades.append(upgrade)
	if game.get("buildings"):
		game.buildings.update_synergies(active_upgrades)
	if game.has_method("recalculate_income"):
		game.recalculate_income()
	if game.has_signal("upgrades_changed"):
		game.upgrades_changed.emit()
	if game.has_method("emit_upgrade_completed"):
		game.emit_upgrade_completed(upgrade)
	upgrades.erase(upgrade)

func to_dict() -> Dictionary:
	var pending_list = []
	for u in upgrades:
		pending_list.append({
			"name": u.name,
			"is_crafting": u.is_crafting,
			"progress": u.progress,
			"has_been_seen": u.has_been_seen,
			"is_masked": u.is_masked
		})
		
	var active_list = []
	for u in active_upgrades:
		active_list.append(u.name)
		
	return {
		"pending_upgrades": pending_list,
		"active_upgrades": active_list
	}

func from_dict(dict: Dictionary) -> void:
	if dict.has("active_upgrades"):
		var act_list = dict["active_upgrades"]
		var to_remove = []
		for u in upgrades:
			if u.name in act_list:
				active_upgrades.append(u)
				apply_upgrade(u)
				to_remove.append(u)
		for u in to_remove:
			upgrades.erase(u)
			
	if dict.has("pending_upgrades"):
		var pend_list = dict["pending_upgrades"]
		for u in upgrades:
			for data in pend_list:
				if u.name == data["name"]:
					u.is_crafting = data.get("is_crafting", false)
					u.progress = data.get("progress", 0.0)
					u.has_been_seen = data.get("has_been_seen", false)
					u.is_masked = data.get("is_masked", false)
					break
