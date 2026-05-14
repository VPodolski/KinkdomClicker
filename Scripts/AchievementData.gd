class_name AchievementData

var id: String
var title: String
var description: String
var unlocked: bool = false

func _init(_id: String, _title: String, _description: String):
	id = _id
	title = _title
	description = _description
