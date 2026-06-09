class_name ExpeditionManager
extends Node

signal camp_spawned(camp)
signal camp_updated(camp)
signal combat_resolved(camp, won, casualties_percent, log_message)
signal expedition_returned(log_message)
signal expedition_finished(result_data: Dictionary)

var game: Node
var camps: Array[CampData] = []
var next_camp_id: int = 1

var commander_xp: float = 0.0
var commander_level: int = 1

# Глобальный бонус от рабов/пленников
var total_captives: int = 0

func _init(_game: Node):
	game = _game
	spawn_initial_camps()

const BARBARIAN_CAMPAIGN = [
	{"name": "Варварский дозор", "power": 500.0, "time": 30.0, "is_boss": false},
	{"name": "Лагерь наемников", "power": 1500.0, "time": 45.0, "is_boss": false},
	{"name": "Застава у реки", "power": 4000.0, "time": 60.0, "is_boss": false},
	{"name": "Укрепленный форт", "power": 10000.0, "time": 90.0, "is_boss": false},
	{"name": "Перевал дикарей", "power": 25000.0, "time": 120.0, "is_boss": false},
	{"name": "Город изгоев", "power": 60000.0, "time": 150.0, "is_boss": false},
	{"name": "Осада крепости", "power": 150000.0, "time": 180.0, "is_boss": false},
	{"name": "Гвардия вождя", "power": 400000.0, "time": 240.0, "is_boss": false},
	{"name": "Врата Бездны", "power": 1000000.0, "time": 300.0, "is_boss": false},
	{"name": "Король Варваров", "power": 3000000.0, "time": 600.0, "is_boss": true}
]

var current_stage_index: int = 0

func spawn_initial_camps():
	# Координаты для красивого пути на карте (зиг-заг снизу вверх)
	var positions = [
		Vector2(0.1, 0.80), Vector2(0.3, 0.72),
		Vector2(0.1, 0.64), Vector2(0.3, 0.56),
		Vector2(0.1, 0.48), Vector2(0.3, 0.40),
		Vector2(0.1, 0.32), Vector2(0.3, 0.24),
		Vector2(0.1, 0.16), Vector2(0.3, 0.08)
	]
	
	for i in range(BARBARIAN_CAMPAIGN.size()):
		var stage = BARBARIAN_CAMPAIGN[i]
		var is_boss = stage.get("is_boss", false)
		var is_unlocked = (i <= current_stage_index)
		var camp = CampData.new("camp_" + str(i), stage["name"], positions[i], stage["power"], stage["time"], is_boss, is_unlocked)
		generate_enemy_army(camp)
		camps.append(camp)
		camp_spawned.emit(camp)


func generate_enemy_army(camp: CampData):
	var remaining_power = camp.exact_power.to_float()
	var available_troops = game.war.troops.duplicate()
	available_troops.shuffle()
	
	camp.enemy_troops.clear()
	for t in available_troops:
		if remaining_power <= 0:
			break
		var power_for_this = randf_range(0.2, 0.8) * remaining_power
		var count = int(power_for_this / t.base_power.to_float())
		if count > 0:
			camp.enemy_troops[t.id] = count
			remaining_power -= count * t.base_power.to_float()
			
	if remaining_power > 0:
		var militia = game.war.get_troop_by_id("militia")
		if militia:
			var count = max(1, int(remaining_power / militia.base_power.to_float()))
			camp.enemy_troops["militia"] = camp.enemy_troops.get("militia", 0) + count
			
	var new_power = 0.0
	for troop_id in camp.enemy_troops.keys():
		var t = game.war.get_troop_by_id(troop_id)
		new_power += camp.enemy_troops[troop_id] * t.base_power.to_float()
	camp.exact_power = BigNum.from(new_power)
	if camp.is_boss:
		camp.gold_reward = camp.exact_power.mul(25000.0)
		camp.captives_reward = max(500, int(camp.exact_power.to_float() / 0.2))
	else:
		camp.gold_reward = camp.exact_power.mul(2500.0)
		camp.captives_reward = max(50, int(camp.exact_power.to_float() / 2.0))
	
	camp.enemy_scouts_count = 0
	if camp.exact_power.is_greater_than(2000.0):
		camp.enemy_scouts_count = int(camp.exact_power.to_float() / 1000.0) + randi_range(0, 5)

func start_expedition(camp: CampData, army: ArmyGroup):
	if camp.status == CampData.Status.IDLE:
		camp.player_army = army
		if army.is_scouting_mission:
			camp.status = CampData.Status.SCOUTING
			camp.timer = camp.distance_time * 0.5
		else:
			camp.status = CampData.Status.TRAVELING
			camp.timer = camp.distance_time
		camp_updated.emit(camp)

func update(delta: float):
	for camp in camps:
		if camp.status == CampData.Status.SCOUTING:
			camp.timer -= delta
			if camp.timer <= 0:
				resolve_scouting(camp)
				
		elif camp.status == CampData.Status.TRAVELING:
			camp.timer -= delta
			if camp.timer <= 0:
				resolve_combat(camp)
				
		elif camp.status == CampData.Status.RETURNING:
			camp.timer -= delta
			if camp.timer <= 0:
				finish_return(camp)

func resolve_scouting(camp: CampData):
	var army = camp.player_army
	var player_scout_power = 0.0
	for t_id in army.troops.keys():
		var count = army.troops[t_id]
		if t_id == "scout":
			player_scout_power += count * 5.0
		else:
			player_scout_power += count * 0.5
			
	var enemy_scout_power = max(1.0, float(camp.enemy_scouts_count) * 5.0)
	var intel_gained = player_scout_power / (enemy_scout_power * 2.0)
	
	var player_troop_losses = {}
	var kills = int(enemy_scout_power / 10.0 * randf_range(0.5, 1.5))
	var remaining_kills = kills
	var new_troops = army.troops.duplicate()
	for t_id in new_troops.keys():
		var count = new_troops[t_id]
		if remaining_kills > 0 and count > 0:
			var dead = min(count, remaining_kills)
			new_troops[t_id] -= dead
			remaining_kills -= dead
			player_troop_losses[t_id] = {"dead": dead, "fled": 0}
			
	var p_kills = int(player_scout_power / 10.0 * randf_range(0.5, 1.5))
	var e_dead = min(camp.enemy_scouts_count, p_kills)
	camp.enemy_scouts_count -= e_dead
	army.troops = new_troops
	
	camp.last_combat_losses = player_troop_losses
	camp.last_enemy_killed = e_dead
	camp.add_intel(intel_gained)
	
	var msg = "Разведка завершена. Добыто %d%% информации." % int(min(intel_gained, 1.0) * 100)
	camp.status = CampData.Status.RETURNING
	camp.timer = camp.distance_time * 0.5
	combat_resolved.emit(camp, true, 0.0, msg)
	camp_updated.emit(camp)

func resolve_combat(camp: CampData):
	var army = camp.player_army
	
	var player_dict = army.troops.duplicate()
	var enemy_dict = camp.enemy_troops.duplicate()
	
	var player_alive = true
	var enemy_alive = true
	var rounds = 0
	
	while player_alive and enemy_alive and rounds < 20:
		rounds += 1
		
		var p_count = 0
		var p_power = 0.0
		for t_id in player_dict.keys():
			var count = player_dict[t_id]
			p_count += count
			var t = game.war.get_troop_by_id(t_id)
			p_power += count * t.base_power.to_float()
			
		var e_count = 0
		var e_power = 0.0
		for t_id in enemy_dict.keys():
			var count = enemy_dict[t_id]
			e_count += count
			var t = game.war.get_troop_by_id(t_id)
			e_power += count * t.base_power.to_float()
			
		if p_count == 0: player_alive = false
		if e_count == 0: enemy_alive = false
		if not player_alive or not enemy_alive:
			break
			
		# Mob effect (Эффект толпы)
		var p_mult = 1.0
		var e_mult = 1.0
		
		if p_count >= e_count * 10: p_mult = 1.5
		elif p_count >= e_count * 5: p_mult = 1.3
		elif p_count >= e_count * 2: p_mult = 1.1
		
		if e_count >= p_count * 10: e_mult = 1.5
		elif e_count >= p_count * 5: e_mult = 1.3
		elif e_count >= p_count * 2: e_mult = 1.1
		
		var commander_mult = 1.0 + (commander_level * 0.02)
		p_mult *= commander_mult * army.morale_multiplier
		
		var p_damage = p_power * p_mult * randf_range(0.8, 1.2)
		var e_damage = e_power * e_mult * randf_range(0.8, 1.2)
		
		_distribute_damage(enemy_dict, p_damage)
		_distribute_damage(player_dict, e_damage)
		
		p_count = 0
		for c in player_dict.values(): p_count += c
		if p_count <= 0: player_alive = false
		
		e_count = 0
		for c in enemy_dict.values(): e_count += c
		if e_count <= 0: enemy_alive = false

	var won = player_alive
	var player_troop_losses = {}
	var enemy_killed_total = 0
	
	# Подсчитываем потери игрока и сбежавших
	for t_id in army.troops.keys():
		var initial = army.troops[t_id]
		var survived = player_dict.get(t_id, 0)
		var lost = initial - survived
		var fled = 0
		var dead = 0
		
		if lost > 0:
			fled = int(lost * randf_range(0.03, 0.05)) # 3-5% сбежали
			dead = lost - fled
			
		player_troop_losses[t_id] = {"dead": dead, "fled": fled}
		
		# Сбежавшие возвращаются в замок мгновенно
		if fled > 0:
			var t = game.war.get_troop_by_id(t_id)
			if t: t.count += fled
			
		army.troops[t_id] = survived # В отряде остаются только выжившие
	
	# Подсчитываем потери врага
	for t_id in camp.enemy_troops.keys():
		var initial = camp.enemy_troops[t_id]
		var survived = enemy_dict.get(t_id, 0)
		enemy_killed_total += (initial - survived)
		camp.enemy_troops[t_id] = survived
		
	# Обновляем силу врага
	var new_enemy_power = 0.0
	for t_id in camp.enemy_troops.keys():
		var t = game.war.get_troop_by_id(t_id)
		new_enemy_power += camp.enemy_troops[t_id] * t.base_power.to_float()
	camp.exact_power = BigNum.from(new_enemy_power)
	
	var msg = ""
	
	if won:
		msg = "Победа! Враг разбит."
		camp.is_defeated = true
		camp.status = CampData.Status.RETURNING
		camp.timer = camp.distance_time
	else:
		msg = "Поражение. Ваши войска были разбиты."
		var has_survivors = false
		for c in army.troops.values():
			if c > 0: has_survivors = true
			
		if has_survivors:
			camp.status = CampData.Status.RETURNING
			camp.timer = camp.distance_time
			camp.improve_intel()
			msg += " Выжившие отступают и докладывают о численности врага."
		else:
			camp.status = CampData.Status.RETURNING
			camp.timer = camp.distance_time
			msg += " Никто не вернулся живым..."
			
	camp.last_combat_losses = player_troop_losses
	camp.last_enemy_killed = enemy_killed_total
	
	combat_resolved.emit(camp, won, 0.0, msg)
	camp_updated.emit(camp)

func _distribute_damage(army_dict: Dictionary, total_damage: float):
	var active_types = []
	for t_id in army_dict.keys():
		if army_dict[t_id] > 0:
			active_types.append(t_id)
			
	if active_types.is_empty(): return
	var damage_per_type = total_damage / active_types.size()
	
	for t_id in active_types:
		var count = army_dict[t_id]
		var t = game.war.get_troop_by_id(t_id)
		var kills = int(damage_per_type / t.base_power.to_float())
		army_dict[t_id] = max(0, count - kills)

func finish_return(camp: CampData):
	# Возвращаем войска в пул (WarManager)
	var army = camp.player_army
	var msg = "Поход завершен. "
	
	if army != null:
		for troop_id in army.troops.keys():
			var amount = army.troops[troop_id]
			if amount > 0:
				var t = game.war.get_troop_by_id(troop_id)
				if t:
					t.count += amount
	
	if camp.is_defeated:
		camp.status = CampData.Status.DEFEATED # предотвращает бесконечный цикл
		camp.player_army = null
		game.economy.add_gold(camp.gold_reward)
		total_captives += camp.captives_reward
		commander_xp += camp.exact_power.to_float() * 0.1
		check_commander_level()
		
		msg += "Добыто %s золота и %d пленников." % [game.format_number(camp.gold_reward), camp.captives_reward]
		
		var result = {
			"won": true,
			"casualties_percent": 0.0,
			"gold_reward": camp.gold_reward,
			"captives_reward": camp.captives_reward,
			"enemy_power": camp.exact_power,
			"player_losses": camp.last_combat_losses,
			"enemy_killed": camp.last_enemy_killed,
			"gathered_intel": false
		}
		expedition_finished.emit(result)
		
		# Открываем следующий лагерь
		if current_stage_index < BARBARIAN_CAMPAIGN.size() - 1:
			current_stage_index += 1
			var next_name = BARBARIAN_CAMPAIGN[current_stage_index].name
			for c in camps:
				if c.camp_name == next_name and not c.is_unlocked:
					c.is_unlocked = true
					camp_updated.emit(c)
	else:
		var has_survivors = false
		if camp.player_army != null:
			for c in camp.player_army.troops.values():
				if c > 0: has_survivors = true
				
		var is_scout_mission = false
		if camp.player_army != null and camp.player_army.is_scouting_mission:
			is_scout_mission = true

		var result = {
			"won": false,
			"is_scout_mission": is_scout_mission,
			"casualties_percent": 0.0,
			"gold_reward": 0.0,
			"captives_reward": 0,
			"enemy_power": camp.exact_power,
			"player_losses": camp.last_combat_losses,
			"enemy_killed": camp.last_enemy_killed,
			"gathered_intel": has_survivors
		}
		expedition_finished.emit(result)
		
		camp.player_army = null
		camp.status = CampData.Status.IDLE
		camp_updated.emit(camp)
	
	expedition_returned.emit(msg)
	game.war.recalculate_power()
	game.war.troops_changed.emit()

func check_commander_level():
	var needed = commander_level * 1000.0
	if commander_xp >= needed:
		commander_xp -= needed
		commander_level += 1
