
func _on_commander_equip_requested(troop_id):
	var am = game.archeology
	var troop = game.war.get_troop_by_id(troop_id)
	if not troop or not troop.commander: return
	
	if troop.commander.equipped_artifact_level > 0:
		am.unequip_commander_artifact(troop_id)
	elif selected_inventory_index != -1:
		am.equip_commander_artifact(troop_id, selected_inventory_index)
		selected_inventory_index = -1
	
	update_artifacts_ui()
	update_commanders_ui()
