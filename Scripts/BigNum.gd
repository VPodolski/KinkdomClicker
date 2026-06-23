class_name BigNum
extends RefCounted

var m: float = 0.0
var e: int = 0

func _init(mantissa: float = 0.0, exponent: int = 0):
	m = mantissa
	e = exponent
	_normalize()

func _normalize() -> void:
	if m == 0.0:
		e = 0
		return
		
	if is_nan(m) or is_inf(m):
		return

	var diff = floor(log(abs(m)) / log(10.0))
	if diff != 0.0:
		m /= pow(10.0, diff)
		e += int(diff)
		
	if abs(m) >= 10.0:
		m /= 10.0
		e += 1
	elif abs(m) < 1.0 and m != 0.0:
		m *= 10.0
		e -= 1

# Creating from variants
static func from(val) -> BigNum:
	if val is BigNum:
		return BigNum.new(val.m, val.e)
	elif val is String:
		if val.find("e") != -1 or val.find("E") != -1:
			var parts = val.split("e", false)
			if parts.size() < 2:
				parts = val.split("E", false)
			if parts.size() == 2:
				return BigNum.new(float(parts[0]), int(parts[1]))
		return BigNum.new(float(val), 0)
	else:
		return BigNum.new(float(val), 0)

# Math
func add(other) -> BigNum:
	var o = BigNum.from(other)
	var res = BigNum.new(0.0, 0)
	if m == 0.0:
		res.m = o.m
		res.e = o.e
		return res
	if o.m == 0.0:
		res.m = m
		res.e = e
		return res
		
	var diff = e - o.e
	if diff > 15:
		res.m = m
		res.e = e
	elif diff < -15:
		res.m = o.m
		res.e = o.e
	else:
		res.e = o.e
		res.m = m * pow(10.0, diff) + o.m
		res._normalize()
	return res

func sub(other) -> BigNum:
	var o = BigNum.from(other)
	var res = BigNum.new(0.0, 0)
	if m == 0.0:
		res.m = -o.m
		res.e = o.e
		return res
	if o.m == 0.0:
		res.m = m
		res.e = e
		return res
		
	var diff = e - o.e
	if diff > 15:
		res.m = m
		res.e = e
	elif diff < -15:
		res.m = -o.m
		res.e = o.e
	else:
		res.e = o.e
		res.m = m * pow(10.0, diff) - o.m
		res._normalize()
	return res

func mul(other) -> BigNum:
	var o = BigNum.from(other)
	var res = BigNum.new(m * o.m, e + o.e)
	return res

func add_mut_mul(other: BigNum, factor: float) -> void:
	if other.m == 0.0 or factor == 0.0:
		return
	var new_m = other.m * factor
	var new_e = other.e
	
	var diff_norm = floor(log(abs(new_m)) / log(10.0))
	if diff_norm != 0.0:
		new_m /= pow(10.0, diff_norm)
		new_e += int(diff_norm)
		
	if abs(new_m) >= 10.0:
		new_m /= 10.0
		new_e += 1
	elif abs(new_m) < 1.0 and new_m != 0.0:
		new_m *= 10.0
		new_e -= 1
		
	if m == 0.0:
		m = new_m
		e = new_e
		return
		
	var diff = e - new_e
	if diff > 15:
		return
	elif diff < -15:
		m = new_m
		e = new_e
	else:
		e = new_e
		m = m * pow(10.0, diff) + new_m
		_normalize()

func div(other) -> BigNum:
	var o = BigNum.from(other)
	if o.m == 0.0:
		push_error("BigNum divide by zero")
		return BigNum.new(0.0, 0)
	var res = BigNum.new(m / o.m, e - o.e)
	return res

func pow_num(power: float) -> BigNum:
	if m == 0.0:
		return BigNum.new(0.0, 0)
	# (m * 10^e)^power = m^power * 10^(e*power)
	var new_m = pow(m, power)
	var new_e = float(e) * power
	
	var res = BigNum.new(new_m, 0)
	# handle fractional exponent part
	var e_int = int(floor(new_e))
	var e_frac = new_e - float(e_int)
	res.m *= pow(10.0, e_frac)
	res.e += e_int
	res._normalize()
	return res

func log10() -> float:
	if m <= 0.0:
		return -INF
	return log(m) / log(10.0) + float(e)

# Comparisons
func is_greater_than(other) -> bool:
	var o = BigNum.from(other)
	if m == 0.0: return o.m < 0.0
	if o.m == 0.0: return m > 0.0
	if m > 0 and o.m < 0: return true
	if m < 0 and o.m > 0: return false
	if m > 0:
		if e > o.e: return true
		if e < o.e: return false
		return m > o.m
	else:
		if e > o.e: return false
		if e < o.e: return true
		return m > o.m

func is_less_than(other) -> bool:
	var o = BigNum.from(other)
	return o.is_greater_than(self)

func is_equal(other) -> bool:
	var o = BigNum.from(other)
	if m == 0.0 and o.m == 0.0: return true
	return e == o.e and abs(m - o.m) < 0.00001

func is_greater_equal(other) -> bool:
	return is_greater_than(other) or is_equal(other)

func is_less_equal(other) -> bool:
	return is_less_than(other) or is_equal(other)

func max(other) -> BigNum:
	var o = BigNum.from(other)
	if self.is_greater_than(o):
		return self
	return o

func min(other) -> BigNum:
	var o = BigNum.from(other)
	if self.is_less_than(o):
		return self
	return o

# To Float for minor conversions (danger of overflow)
func to_float() -> float:
	if e > 308: return INF
	if e < -308: return 0.0
	return m * pow(10.0, e)

# Formatting
func format() -> String:
	if e < 3:
		return "%.1f" % to_float()
	
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg"]
	
	var group = int(floor(float(e) / 3.0))
	if group < suffixes.size():
		var suffix = suffixes[group]
		var val_m = m * pow(10.0, e - group * 3)
		return "%.2f%s" % [val_m, suffix]
	else:
		return "%.2fe%d" % [m, e]

func _to_string() -> String:
	return str(m) + "e" + str(e)
