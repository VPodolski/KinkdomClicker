class_name TroopData

var id: String
var name: String
var description: String
var base_power: BigNum
var base_cost: BigNum
var upkeep: BigNum
var base_time: float
var required_building: String

var commander: CommanderData

# Нанятое количество и прогресс текущего найма
var count: int = 0
var is_training: bool = false
var training_progress: float = 0.0
var training_amount: int = 0 # сколько отрядов сейчас тренируется

# Множители для будущего возвышения
var power_multiplier: float = 1.0
var cost_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var upkeep_multiplier: float = 1.0

func _init(_id: String, _name: String, _desc: String, _power: float, _cost: float, _upkeep: float, _time: float, _req: String = ""):
	id = _id
	name = _name
	description = _desc
	base_power = BigNum.from(_power)
	base_cost = BigNum.from(_cost)
	upkeep = BigNum.from(_upkeep)
	base_time = _time
	required_building = _req

func _calc_cost(at_count: int) -> BigNum:
	var multiplier = BigNum.from(1.02).pow_num(float(at_count)).mul(cost_multiplier)
	return base_cost.mul(multiplier)

# Прогрессивная стоимость (множитель 1.02 для массового найма)
func get_cost_for(amount: int) -> BigNum:
	if amount <= 0: return BigNum.new(0.0)
	var start_pow = BigNum.from(1.02).pow_num(float(count + training_amount))
	var amount_pow = BigNum.from(1.02).pow_num(float(amount))
	var sum_factor = amount_pow.sub(1.0).mul(50.0)
	return base_cost.mul(cost_multiplier).mul(start_pow).mul(sum_factor)

func get_max_affordable(current_gold: BigNum, net_income: BigNum, upkeep_mult: float) -> int:
	var c_base = base_cost.mul(cost_multiplier).mul(BigNum.from(1.02).pow_num(float(count + training_amount))).mul(50.0)
	var max_gold = 0
	if c_base.is_greater_than(0.0):
		var factor = current_gold.div(c_base).add(1.0)
		if factor.is_greater_than(0.0):
			max_gold = int(floor(factor.log10() / (log(1.02) / log(10.0))))
			
	if max_gold < 0: max_gold = 0
	
	var max_upkeep = max_gold
	var current_upkeep_mult = upkeep_multiplier * upkeep_mult
	var current_upkeep_cost = upkeep.mul(current_upkeep_mult)
	if current_upkeep_cost.is_greater_than(0.0) and net_income != null and net_income.is_greater_than(0.0):
		var max_add_upkeep = net_income.mul(0.8)
		var factor = max_add_upkeep.div(current_upkeep_cost)
		max_upkeep = int(floor(factor.to_float()))
		
	if max_upkeep < 0: max_upkeep = 0
	var affordable = min(max_gold, max_upkeep)
	
	var step = 100
	var valid = false
	while affordable > 0 and step > 0:
		var c = get_cost_for(affordable)
		valid = true
		if c.is_greater_than(current_gold):
			valid = false
		elif current_upkeep_cost.is_greater_than(0.0):
			var additional_upkeep = current_upkeep_cost.mul(float(affordable))
			if additional_upkeep.is_greater_than(net_income.mul(0.8)):
				valid = false
		if valid:
			break
		affordable -= 1
		step -= 1
		
	if not valid:
		affordable = 0
		
	return affordable

# Общая сила этого типа войск
func get_total_power() -> BigNum:
	var power = base_power.mul(power_multiplier * float(count))
	if commander != null and commander.is_unlocked:
		power = power.mul(commander.get_power_multiplier())
	return power

# Общее содержание этого типа войск
func get_total_upkeep() -> BigNum:
	return upkeep.mul(upkeep_multiplier * float(count))

# Начать тренировку
func start_training(amount: int) -> void:
	training_amount += amount
	is_training = true
	
# Завершить тренировку
func finish_training() -> void:
	count += training_amount
	training_amount = 0
	is_training = false
	training_progress = 0.0
