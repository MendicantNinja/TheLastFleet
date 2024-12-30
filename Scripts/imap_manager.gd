extends Object
class_name ImapManager

enum MapType {
	OCCUPANCY_MAP,
	THREAT_MAP,
	TENSION_MAP,
}

var current_maps: Dictionary = {}

func register_map(map: Imap) -> void:
	current_maps[map.map_type] = map

func register_agents(agents: Array) -> void:
	for agent: Ship in agents:
		agent.update_agent_influence.connect(_on_agent_influence_changed.bind(agent))
		agent.destroyed.connect(_on_agent_destroyed.bind(agent))

func _on_agent_influence_changed(agent: Ship, prev_position: Vector2) -> void:
	var agent_position: Vector2 = agent.global_position
	for imap_type in current_maps:
		var agent_template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = current_maps[imap_type]
		var prev_cell_index: Vector2 = map.find_cell_index_from_position(prev_position)
		var current_cell_index: Vector2 = map.find_cell_index_from_position(agent_position)
		if prev_cell_index == current_cell_index: # until i calculate edges and nearest neighor cells
			continue
		agent_template_map.add_map(map, prev_cell_index.x, prev_cell_index.y, -1.0)
		agent_template_map.add_map(map, current_cell_index.x, current_cell_index.y, 1.0)

func _on_agent_destroyed(agent: Ship) -> void:
	var agent_position: Vector2 = agent.global_position
	for imap_type in current_maps:
		var agent_template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = current_maps[imap_type]
		var cell_index: Vector2 = map.find_cell_index_from_position(agent_position)
		agent_template_map.add_map(map, cell_index.x, cell_index.y, -1.0)
