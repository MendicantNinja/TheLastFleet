extends LeafAction

var visited_units: Array = []
var strength_modifier: float = 1.0

func tick(agent: Admiral, blackboard: Blackboard) -> int:
	if Engine.get_physics_frames() % 240 != 0:
		return FAILURE
	
	var player_total_strength: float = 0.0
	var admiral_total_strength: float = 0.0
	var battle_agents: Array = get_tree().get_nodes_in_group(&"agent")
	var available_player_units: int = 0
	var available_enemy_units: int = 0
	for unit: Ship in battle_agents:
		if unit == null:
			print("The destroyed unit %s still persists in memory in group_units.gd." % [unit.name])
			continue
		var floor_inf: float = floor(abs(unit.approx_influence))
		if unit.is_friendly == true:
			player_total_strength += floor_inf
			available_player_units += 1
		else:
			admiral_total_strength += floor_inf
			available_enemy_units += 1
	
	var relative_strength: float = admiral_total_strength / player_total_strength
	var unit_ratio: int = available_enemy_units / available_player_units
	var remainder: int = available_enemy_units % available_player_units
	var average_unit_strength: float = admiral_total_strength / available_enemy_units
	var strength_coefficient: float = strength_modifier
	var base_group_strength: float = relative_strength * average_unit_strength
	if remainder > 1 and remainder != available_enemy_units:
		var relative_group_size: int = (available_player_units - remainder) / unit_ratio
		strength_coefficient *= relative_group_size
	var adjusted_group_strength: float = base_group_strength * strength_coefficient
	return FAILURE
