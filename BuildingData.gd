class_name BuildingData

var id: String
var name: String
var base_cost: BigNum
var cost: BigNum

# Базовый доход одного здания
var income: BigNum
var prayer_income: BigNum
var gold_upkeep: BigNum

# Количество купленных зданий
var count: int = 0

# Множители
var income_multiplier: float = 1.0
var synergy_bonus: float = 0.0
var cost_multiplier: float = 1.0

var has_been_seen: bool = false
var is_masked: bool = false

func _init(_id: String, _name: String, _base_cost: float, _income: float, _prayer_income: float = 0.0, _gold_upkeep: float = 0.0):
	id = _id
	name = _name
	base_cost = BigNum.from(_base_cost)
	cost = BigNum.from(_base_cost)
	income = BigNum.from(_income)
	prayer_income = BigNum.from(_prayer_income)
	gold_upkeep = BigNum.from(_gold_upkeep)


func buy() -> void:
	buy_multiple(1)

func buy_multiple(amount: int) -> void:
	count += amount
	cost = _calc_cost(count)

func _calc_cost(at_count: int) -> BigNum:
	var multiplier = BigNum.from(1.2).pow_num(float(at_count)).mul(cost_multiplier)
	return base_cost.mul(multiplier)

func get_cost_for(amount: int) -> BigNum:
	if amount <= 0: return BigNum.new(0.0)
	var start_pow = BigNum.from(1.2).pow_num(float(count))
	var amount_pow = BigNum.from(1.2).pow_num(float(amount))
	var sum_factor = amount_pow.sub(1.0).mul(5.0)
	return base_cost.mul(cost_multiplier).mul(start_pow).mul(sum_factor)

func get_max_affordable(current_gold: BigNum, net_income, upkeep_mult: float = 1.0) -> int:
	var c_base = base_cost.mul(cost_multiplier).mul(BigNum.from(1.2).pow_num(float(count))).mul(5.0)
	var max_gold = 0
	if c_base.is_greater_than(0.0):
		var factor = current_gold.div(c_base).add(1.0)
		if factor.is_greater_than(0.0):
			max_gold = int(floor(factor.log10() / (log(1.2) / log(10.0))))
			
	if max_gold < 0: max_gold = 0
	
	var max_upkeep = max_gold
	if gold_upkeep.is_greater_than(0.0) and net_income != null and net_income.is_greater_than(0.0):
		var u_base = gold_upkeep.mul(upkeep_mult).mul(BigNum.from(1.2).pow_num(float(count))).mul(5.0)
		if u_base.is_greater_than(0.0):
			var factor = net_income.div(u_base).add(1.0)
			if factor.is_greater_than(0.0):
				max_upkeep = int(floor(factor.log10() / (log(1.2) / log(10.0))))
			else:
				max_upkeep = 0
				
	if max_upkeep < 0: max_upkeep = 0
	
	var affordable = min(max_gold, max_upkeep)
	
	var step = 100
	var valid = false
	while affordable > 0 and step > 0:
		var c = get_cost_for(affordable)
		valid = true
		if c.is_greater_than(current_gold):
			valid = false
		elif gold_upkeep.is_greater_than(0.0) and net_income != null:
			var u = get_upkeep_for(affordable).mul(upkeep_mult)
			if u.is_greater_equal(net_income):
				valid = false
		if valid:
			break
		affordable -= 1
		step -= 1
		
	if not valid:
		affordable = 0
		
	return affordable


# Доход одного здания с учётом всех бонусов
func get_income_per_unit() -> BigNum:
	return income.mul(income_multiplier + synergy_bonus)


# Общий доход всех купленных зданий
func get_income() -> BigNum:
	return get_income_per_unit().mul(count)

# Доход молитв с одного здания
func get_prayer_income_per_unit() -> BigNum:
	return prayer_income

# Общий доход молитв
func get_prayer_income() -> BigNum:
	return get_prayer_income_per_unit().mul(count)

# Стоимость обслуживания одного (следующего) здания
func get_upkeep_per_unit() -> BigNum:
	return gold_upkeep.mul(BigNum.from(1.2).pow_num(float(count)))

func get_upkeep_for(amount: int) -> BigNum:
	if amount <= 0: return BigNum.new(0.0)
	var start_pow = BigNum.from(1.2).pow_num(float(count))
	var amount_pow = BigNum.from(1.2).pow_num(float(amount))
	var sum_factor = amount_pow.sub(1.0).mul(5.0)
	return gold_upkeep.mul(start_pow).mul(sum_factor)

# Общая стоимость обслуживания
func get_total_upkeep() -> BigNum:
	if count <= 0: return BigNum.new(0.0)
	var amount_pow = BigNum.from(1.2).pow_num(float(count))
	var sum_factor = amount_pow.sub(1.0).mul(5.0)
	return gold_upkeep.mul(sum_factor)
