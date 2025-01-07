extends Node
class_name ImapManager

var arena_width: int = 17000
var arena_height: int = 20000
var default_cell_size: int = 250
var max_cell_size: int = 1500

enum TemplateType {
	OCCUPANCY_TEMPLATE, # Occupancy indicates the space a unit occupies and its zone of influence.
	THREAT_TEMPLATE, # Threat denotes its attack abilities such as the strength of its weapons and accuracy.
	INVERT_OCCUPANCY_TEMPLATE,
	INVERT_THREAT_TEMPLATE,
}

enum MapType {
	OCCUPANCY_MAP,
	THREAT_MAP,
	INFLUENCE_MAP,
	TENSION_MAP,
	VULNERABILITY_MAP,
}

var agent_registry: Dictionary = {}
var template_maps: Dictionary = {}
var current_maps: Dictionary = {}
var registry_map: Dictionary = {}

func _init():
	var occupancy_templates: ImapTemplate = ImapTemplate.new()
	var threat_templates: ImapTemplate = ImapTemplate.new()
	var invert_occupancy_templates: ImapTemplate = ImapTemplate.new()
	var invert_threat_templates: ImapTemplate = ImapTemplate.new()
	occupancy_templates.init_occupancy_map_templates(5)
	threat_templates.init_threat_map_templates(5)
	invert_occupancy_templates.init_occupancy_map_templates(5, -1.0)
	invert_threat_templates.init_threat_map_templates(5, -1.0)
	occupancy_templates.type = TemplateType.OCCUPANCY_TEMPLATE
	threat_templates.type = TemplateType.THREAT_TEMPLATE
	invert_occupancy_templates.type = TemplateType.INVERT_OCCUPANCY_TEMPLATE
	invert_threat_templates.type = TemplateType.INVERT_THREAT_TEMPLATE
	template_maps[occupancy_templates.type] = occupancy_templates
	template_maps[threat_templates.type] = threat_templates
	template_maps[invert_occupancy_templates.type] = invert_occupancy_templates
	template_maps[invert_threat_templates.type] = invert_threat_templates

func register_map(map: Imap) -> void:
	current_maps[map.map_type] = map

func register_agents(agents: Array) -> void:
	for agent: Ship in agents:
		agent.update_agent_influence.connect(_on_agent_influence_changed.bind(agent))
		agent.destroyed.connect(_on_agent_destroyed.bind(agent))

@warning_ignore("narrowing_conversion", "integer_division")
func _on_agent_influence_changed(prev_position: Vector2, agent: Ship) -> void:
	var registered_cells: Dictionary = {}
	for imap_type in current_maps:
		var template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = current_maps[imap_type]
		var cell_column: int = agent.global_position.x / map.cell_size
		var cell_row: int = agent.global_position.y / map.cell_size
		var current_cell_index: Vector2i = Vector2i(cell_row, cell_column)
		#var adjust_imap: Imap = map.correct_influence(template_map, current_cell_index, agent.global_position)
		var prev_cell_index: Vector2i = Vector2i.ZERO
		var distance_to: float = 0.0
		if agent.template_cell_indices.has(imap_type):
			prev_cell_index = agent.template_cell_indices[imap_type]
			var center_cell_pos: Vector2 = Vector2(prev_cell_index.y, prev_cell_index.x) * map.cell_size
			center_cell_pos.x = center_cell_pos.x + map.cell_size / 2.0
			center_cell_pos.y = center_cell_pos.y + map.cell_size / 2.0
			distance_to = center_cell_pos.distance_to(agent.global_position)
		
		var start_index: Vector2i = Vector2i(cell_row - template_map.width / 2, cell_column - template_map.height / 2)
		var end_index: Vector2i = Vector2i(cell_row + template_map.width / 2, cell_column + template_map.height / 2)
		registered_cells[imap_type] = [start_index, end_index]
		
		if distance_to < map.cell_size / 2.0 and prev_position != Vector2.ZERO:
			continue
		
		if agent.template_cell_indices.has(imap_type):
			map.add_map(template_map, prev_cell_index.x, prev_cell_index.y, -1.0)
		map.add_map(template_map, current_cell_index.x, current_cell_index.y,  1.0)
		agent.template_cell_indices[imap_type] = current_cell_index
	
	var prev_registry_index: Vector2i = Vector2i(prev_position.y / max_cell_size, prev_position.x / max_cell_size)
	var current_registry_index: Vector2i = Vector2i(agent.global_position.y / max_cell_size, agent.global_position.x / max_cell_size)
	var registered_agents: Array = []
	if registry_map.has(prev_registry_index):
		registered_agents = registry_map[prev_registry_index]
	
	if prev_registry_index != current_registry_index and agent in registered_agents:
		registered_agents.erase(agent)
		registry_map[prev_registry_index] = registered_agents
		if registered_agents.is_empty():
			registry_map.erase(prev_registry_index)
		registered_agents = []
	
	if registry_map.has(current_registry_index):
		registered_agents = registry_map[current_registry_index]
	
	if not agent in registered_agents:
		registered_agents.push_back(agent)
	
	registry_map[current_registry_index] = registered_agents
	agent_registry[agent] = registered_cells

@warning_ignore("narrowing_conversion")
func _on_agent_destroyed(agent: Ship) -> void:
	for imap_type in current_maps:
		var template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = current_maps[imap_type]
		var cell_column: int = agent.global_position.x / map.cell_size
		var cell_row: int = agent.global_position.y / map.cell_size
		var cell_index: Vector2i = Vector2i(cell_column, cell_row)
		agent_registry.erase(agent)
		map.add_map(template_map, cell_index.x, cell_index.y, -1.0)
