class_name UpgradeManager

var upgrades = [
	# 50
	UpgradeData.new(
		"Острые инструменты",
		"Увеличивает золото за клик на 1.",
		50,
		3.0,
		"click_bonus",
		1.0
	),

	# 150
	UpgradeData.new(
		"Тяжёлый молот",
		"Увеличивает золото за клик на 3.",
		150,
		5.0,
		"click_bonus",
		3.0
	),

	# 200
	UpgradeData.new(
		"Удобрения",
		"Доход ферм увеличивается на 50%.",
		200,
		6.0,
		"income_multiplier",
		0.5,
		"Ферма"
	),

	# 400
	UpgradeData.new(
		"Острые пилы",
		"Доход лесопилок увеличивается на 50%.",
		400,
		6.0,
		"income_multiplier",
		0.5,
		"Лесопилка"
	),

	# 500
	UpgradeData.new(
		"Золотое касание",
		"Клик приносит дополнительно 1% от текущего дохода.",
		500,
		8.0,
		"click_from_income",
		0.01
	),

	# 600
	UpgradeData.new(
		"Железные плуги",
		"Доход ферм увеличивается на 100%.",
		600,
		8.0,
		"income_multiplier",
		1.0,
		"Ферма"
	),

	# 800
	UpgradeData.new(
		"Угольная печь",
		"Ускоряет работу кузницы на 20%.",
		800,
		8.0,
		"forge_speed",
		0.20
	),

	# 1000
	UpgradeData.new(
		"Инструменты фермеров",
		"Каждая кузница увеличивает доход ферм на 2%.",
		1000,
		10.0,
		"building_synergy",
		0.02,
		"Ферма",
		"Кузница"
	),

	# 1200
	UpgradeData.new(
		"Фермерская кооперация",
		"Каждая ферма усиливает другие фермы на 1%.",
		1200,
		10.0,
		"building_synergy",
		0.01,
		"Ферма",
		"Ферма"
	),

	UpgradeData.new(
		"Массовая заготовка",
		"Доход лесопилок увеличивается на 100%.",
		1200,
		10.0,
		"income_multiplier",
		1.0,
		"Лесопилка"
	),

	# 1500
	UpgradeData.new(
		"Деревянные конструкции",
		"Каждая лесопилка увеличивает доход кузниц на 1.5%.",
		1500,
		10.0,
		"building_synergy",
		0.015,
		"Кузница",
		"Лесопилка"
	),

	# 2000
	UpgradeData.new(
		"Жадность короля",
		"Клик приносит дополнительно 3% от текущего дохода.",
		2000,
		12.0,
		"click_from_income",
		0.03
	),

	UpgradeData.new(
		"Мастера кузнецы",
		"Каждая кузница увеличивает доход ферм на 2%.",
		2000,
		12.0,
		"building_synergy",
		0.02,
		"Ферма",
		"Кузница"
	),

	# 2500
	UpgradeData.new(
		"Древесные контракты",
		"Общий доход увеличивается на 10%.",
		2500,
		12.0,
		"global_multiplier",
		0.10
	),

	# 3000
	UpgradeData.new(
		"Торговые пути",
		"Общий доход увеличивается на 10%.",
		3000,
		10.0,
		"global_multiplier",
		0.10
	),

	# 5000
	UpgradeData.new(
		"Гильдия кузнецов",
		"Общий доход увеличивается на 15%.",
		5000,
		15.0,
		"global_multiplier",
		0.15
	),

	# 7000
	UpgradeData.new(
		"Городская экономика",
		"Каждый рынок увеличивает доход ферм на 1%.",
		7000,
		15.0,
		"building_synergy",
		0.01,
		"Ферма",
		"Рынок"
	),

	# 8000
	UpgradeData.new(
		"Королевские налоги",
		"Общий доход увеличивается на 25%.",
		8000,
		15.0,
		"global_multiplier",
		0.25
	)
]
var active_upgrades = []

var economy
var buildings

func _init(_economy, _buildings):
	economy = _economy
	buildings = _buildings

func apply_upgrade(upgrade):
	match upgrade.effect_type:
		"click_bonus":
			economy.gold_per_click += upgrade.effect_value
		
		"click_from_income":
			economy.click_income_ratio += upgrade.effect_value
		
		"income_multiplier":
			var b = buildings.get_building_by_name(upgrade.target)
			if b:
				b.income_multiplier += upgrade.effect_value
		
		"global_multiplier":
			economy.global_income_multiplier += upgrade.effect_value

func update_crafting(delta, forge_speed):
	for upgrade in upgrades:
		if upgrade.is_crafting:
			upgrade.progress += delta * forge_speed
			
			if upgrade.progress >= upgrade.base_time:
				complete_upgrade(upgrade)


func complete_upgrade(upgrade):
	apply_upgrade(upgrade)
	active_upgrades.append(upgrade)
	upgrades.erase(upgrade)
