extends Node

const SAVE_PATH = "user://savegame.json"

var last_played_time: float = 0.0

var save_timer: float = 0.0
var save_interval: float = 10.0 # Auto-save every 10 seconds periodically
var pending_save: bool = false

func _ready():
	# Инициализируем last_played_time на случай первого запуска
	last_played_time = Time.get_unix_time_from_system()
	call_deferred("_connect_signals")

func _connect_signals():
	GameLogic.gold_changed.connect(_on_any_changed)
	GameLogic.buildings_changed.connect(_on_any_changed)
	GameLogic.upgrades_changed.connect(_on_any_changed)
	GameLogic.war.troops_changed.connect(_on_any_changed)
	GameLogic.expeditions.camp_updated.connect(_on_any_changed)
	GameLogic.archeology.archeologists_changed.connect(_on_any_changed)
	GameLogic.archeology.artifacts_changed.connect(_on_any_changed)

func _on_any_changed(arg1=null, arg2=null, arg3=null, arg4=null):
	request_save()


func _process(delta):
	if pending_save:
		save_timer += delta
		if save_timer >= save_interval:
			_perform_save()

# Вызывать при любых значимых действиях (покупка здания, апгрейда, завершение боя)
func request_save():
	pending_save = true

# Принудительное сохранение (при выходе)
func force_save():
	_perform_save()

func _perform_save():
	save_timer = 0.0
	pending_save = false
	
	var data = {
		"last_played_time": Time.get_unix_time_from_system(),
		"economy": GameLogic.economy.to_dict(),
		"buildings": GameLogic.buildings.to_dict(),
		"upgrades": GameLogic.upgrades.to_dict(),
		"war": GameLogic.war.to_dict(),
		"expeditions": GameLogic.expeditions.to_dict(),
		"archeology": GameLogic.archeology.to_dict(),
		"ascension": GameLogic.ascension.to_dict(),
		"achievements": GameLogic.achievements.to_dict()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
	else:
		print("SaveManager: Failed to open save file for writing.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: No save file found.")
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_string)
	if err == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			last_played_time = data.get("last_played_time", Time.get_unix_time_from_system())
			
			if data.has("economy"): GameLogic.economy.from_dict(data["economy"])
			if data.has("buildings"): GameLogic.buildings.from_dict(data["buildings"])
			if data.has("upgrades"): GameLogic.upgrades.from_dict(data["upgrades"])
			if data.has("war"): GameLogic.war.from_dict(data["war"])
			if data.has("expeditions"): GameLogic.expeditions.from_dict(data["expeditions"])
			if data.has("archeology"): GameLogic.archeology.from_dict(data["archeology"])
			if data.has("ascension"): GameLogic.ascension.from_dict(data["ascension"])
			if data.has("achievements"): GameLogic.achievements.from_dict(data["achievements"])
			
			GameLogic.buildings.update_synergies(GameLogic.upgrades.active_upgrades)
			GameLogic.recalculate_income()
			GameLogic.war.update_troops_multipliers()
			GameLogic.war.recalculate_power()
			
			print("SaveManager: Game loaded successfully.")
			return true
	
	print("SaveManager: Failed to parse save file.")
	return false

func wipe_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().quit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		force_save()
