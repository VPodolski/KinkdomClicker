class_name ExpeditionManager
extends Node

signal camp_spawned(camp)
signal camp_removed(camp_id)
signal camp_updated(camp)
signal combat_resolved(camp, won, casualties_percent, log_message)
signal expedition_returned(log_message)

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

func spawn_initial_camps():
	spawn_camp(Vector2(0.2, 0.2), 1500.0, 30.0) # Близкий легкий
	spawn_camp(Vector2(0.7, 0.3), 5000.0, 60.0) # Средний
	spawn_camp(Vector2(0.4, 0.8), 15000.0, 120.0) # Дальний сложный

func spawn_camp(pos: Vector2, power: float, time: float):
	var camp = CampData.new("camp_" + str(next_camp_id), pos, power, time)
	next_camp_id += 1
	camps.append(camp)
	camp_spawned.emit(camp)

func start_scouting(camp: CampData):
	if camp.status == CampData.Status.IDLE:
		camp.status = CampData.Status.SCOUTING
		camp.timer = camp.distance_time * 0.5 # Разведчики идут быстрее
		camp_updated.emit(camp)

func start_expedition(camp: CampData, army: ArmyGroup):
	if camp.status == CampData.Status.IDLE or camp.status == CampData.Status.SCOUTING:
		camp.status = CampData.Status.TRAVELING
		camp.player_army = army
		camp.timer = camp.distance_time
		camp_updated.emit(camp)

func update(delta: float):
	for camp in camps:
		if camp.status == CampData.Status.SCOUTING:
			camp.timer -= delta
			if camp.timer <= 0:
				camp.is_scouted = true
				camp.status = CampData.Status.IDLE
				camp_updated.emit(camp)
				
		elif camp.status == CampData.Status.TRAVELING:
			camp.timer -= delta
			if camp.timer <= 0:
				resolve_combat(camp)
				
		elif camp.status == CampData.Status.RETURNING:
			camp.timer -= delta
			if camp.timer <= 0:
				finish_return(camp)

func resolve_combat(camp: CampData):
	var army = camp.player_army
	var base_power = army.base_power
	
	# Бонус полководца (+2% за уровень)
	var commander_mult = 1.0 + (commander_level * 0.02)
	
	# RNG от 0.85 до 1.15
	var rng = randf_range(0.85, 1.15)
	
	var final_power = base_power * commander_mult * army.morale_multiplier * rng
	var enemy_power = camp.exact_power
	
	var won = final_power > enemy_power
	var casualties_pct = 0.0
	
	var msg = ""
	
	if won:
		var ratio = final_power / enemy_power
		if ratio > 3.0:
			casualties_pct = randf_range(0.01, 0.05)
		elif ratio > 1.5:
			casualties_pct = randf_range(0.1, 0.25)
		else:
			casualties_pct = randf_range(0.3, 0.6)
		
		msg = "Победа! Враг разбит. Вы потеряли %d%% войска." % int(casualties_pct * 100)
		camp.is_defeated = true
		camp.status = CampData.Status.RETURNING
		camp.timer = camp.distance_time # Идем обратно
	else:
		# Поражение
		casualties_pct = randf_range(0.8, 1.0)
		msg = "Поражение. Ваши войска были разбиты. Выжило только %d%%." % int((1.0 - casualties_pct) * 100)
		
		if casualties_pct >= 1.0:
			camp.player_army = null
			camp.status = CampData.Status.IDLE
		else:
			camp.status = CampData.Status.RETURNING
			camp.timer = camp.distance_time
			
	apply_casualties(army, casualties_pct)
	
	combat_resolved.emit(camp, won, casualties_pct, msg)
	camp_updated.emit(camp)

func apply_casualties(army: ArmyGroup, pct: float):
	for troop_id in army.troops.keys():
		var amount = army.troops[troop_id]
		var survived = int(amount * (1.0 - pct))
		army.troops[troop_id] = survived

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
		game.economy.add_gold(camp.gold_reward)
		total_captives += camp.captives_reward
		commander_xp += camp.exact_power * 0.1
		check_commander_level()
		
		msg += "Добыто %s золота и %d пленников." % [game.format_number(camp.gold_reward), camp.captives_reward]
		
		camps.erase(camp)
		camp_removed.emit(camp.id)
		
		# Спавним новый лагерь
		spawn_camp(Vector2(randf_range(0.1, 0.8), randf_range(0.1, 0.8)), camp.exact_power * 1.2, camp.distance_time * 1.1)
	else:
		camp.player_army = null
		camp.status = CampData.Status.IDLE
		camp_updated.emit(camp)
	
	expedition_returned.emit(msg)
	game.war.troops_changed.emit()

func check_commander_level():
	var needed = commander_level * 1000.0
	if commander_xp >= needed:
		commander_xp -= needed
		commander_level += 1
