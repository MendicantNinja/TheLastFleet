extends Node
class_name ImapManager

var arena_width: int = 17000
var arena_height: int = 20000
var default_cell_size: int = 250
var max_cell_size: int = 2250

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

var default_radius: int = 5
var registry_map: Dictionary = {}
var template_maps: Dictionary = {}
var agent_maps: Dictionary = {}
var vulnerability_map: Imap
var tension_map: Imap
var weighted_imap: Imap
var weighted_friendly: Dictionary = {}
var weighted_enemy: Dictionary = {}
var working_maps: Dictionary = {}
var visited: Array = []

func _init():
	var occupancy_templates: ImapTemplate = ImapTemplate.new()
	var threat_templates: ImapTemplate = ImapTemplate.new()
	var invert_occupancy_templates: ImapTemplate = ImapTemplate.new()
	var invert_threat_templates: ImapTemplate = ImapTemplate.new()
	occupancy_templates.init_occupancy_map_templates(default_radius)
	threat_templates.init_threat_map_templates(default_radius)
	invert_occupancy_templates.init_occupancy_map_templates(default_radius, -1.0)
	invert_threat_templates.init_threat_map_templates(default_radius, -1.0)
	occupancy_templates.type = TemplateType.OCCUPANCY_TEMPLATE
	threat_templates.type = TemplateType.THREAT_TEMPLATE
	invert_occupancy_templates.type = TemplateType.INVERT_OCCUPANCY_TEMPLATE
	invert_threat_templates.type = TemplateType.INVERT_THREAT_TEMPLATE
	template_maps[occupancy_templates.type] = occupancy_templates
	template_maps[threat_templates.type] = threat_templates
	template_maps[invert_occupancy_templates.type] = invert_occupancy_templates
	template_maps[invert_threat_templates.type] = invert_threat_templates

func register_map(map: Imap) -> void:
	agent_maps[map.map_type] = map

func register_agents(agents: Array) -> void:
	for agent: Ship in agents:
		agent.update_agent_influence.connect(_on_agent_influence_changed.bind(agent))
		agent.destroyed.connect(_on_agent_destroyed.bind(agent))
		agent.update_registry_cell.connect(_on_agent_registry_changed.bind(agent))

@warning_ignore("narrowing_conversion", "integer_division")
func _on_agent_influence_changed(registered_cell: Vector2i, current_cell_idx: Vector2i, agent: Ship) -> void:
	for imap_type in agent_maps:
		var template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = agent_maps[imap_type]
		#var adjust_imap: Imap = map.correct_influence(template_map, agent_cell, agent.global_position)
		
		var distance_to: float = 0.0
		if agent.template_cell_indices.has(imap_type):
			var center_cell_pos: Vector2 = Vector2(registered_cell.y, registered_cell.x) * map.cell_size
			center_cell_pos.x = center_cell_pos.x + map.cell_size / 2.0
			center_cell_pos.y = center_cell_pos.y + map.cell_size / 2.0
			distance_to = center_cell_pos.distance_to(agent.global_position)
		if distance_to < map.cell_size / 2.0 and registered_cell != Vector2i.ZERO:
			continue
		
		if agent.template_cell_indices.has(imap_type):
			map.add_map(template_map, registered_cell.x, registered_cell.y,  -1.0)
		
		map.add_map(template_map, current_cell_idx.x, current_cell_idx.y,  1.0)
		agent.template_cell_indices[imap_type] = current_cell_idx
	
	weighted_imap.add_map(agent.weigh_influence, registered_cell.x, registered_cell.y, -1.0)
	weighted_imap.add_map(agent.weigh_influence, current_cell_idx.x, current_cell_idx.y, 1.0)

func _on_agent_registry_changed(prev_registry_cell, registry_cell, agent: Ship) -> void:
	var agents_registered: Array = []
	if registry_map.has(prev_registry_cell):
		agents_registered = registry_map[prev_registry_cell]
	
	if agent in agents_registered:
		agents_registered.erase(agent)
		registry_map[prev_registry_cell] = agents_registered
		agents_registered = []
	
	if registry_map.has(registry_cell):
		agents_registered = registry_map[registry_cell]
	
	if agent not in agents_registered:
		agents_registered.push_back(agent)
	
	registry_map[registry_cell] = agents_registered
	
	var remove_cells: Array = []
	for cell in registry_map:
		if registry_map[cell].is_empty():
			remove_cells.push_back(cell)
	
	for cell in remove_cells:
		registry_map.erase(cell)

@warning_ignore("narrowing_conversion")
func _on_agent_destroyed(agent: Ship) -> void:
	var cell_column: int = agent.global_position.x / default_cell_size
	var cell_row: int = agent.global_position.y / default_cell_size
	for imap_type in agent_maps:
		var template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = agent_maps[imap_type]
		map.add_map(template_map, cell_row, cell_column, -1.0)

func _on_CombatArena_exiting() -> void:
	var available_agents: Array = get_tree().get_nodes_in_group(&"agent")
	for agent: Ship in available_agents:
		agent.remove_from_group(&"agent")
		agent.update_agent_influence.disconnect(_on_agent_influence_changed)
		agent.destroyed.disconnect(_on_agent_destroyed)
		agent.update_registry_cell.disconnect(_on_agent_registry_changed)
	registry_map = {}
	vulnerability_map.clear_map()
	tension_map.clear_map()
	for map in agent_maps:
		agent_maps[map].clear_map()

func weigh_force_density() -> void:
	var friendly_cluster: Dictionary = {}
	var enemy_cluster: Dictionary = {}
	for cell in registry_map:
		var registered_agents: Array = registry_map[cell]
		var enemy_density: float = 0.0
		var friendly_density: float = 0.0
		for agent in registered_agents:
			if agent.is_friendly:
				friendly_density += agent.approx_influence
			elif not agent.is_friendly:
				enemy_density += agent.approx_influence
		if friendly_density != 0.0:
			friendly_cluster[cell] = friendly_density
		if enemy_density != 0.0:
			enemy_cluster[cell] = enemy_density
	
	
	var enemy_neighborhood_density: Dictionary = {}
	visited = []
	for cell in enemy_cluster:
		var cluster: Array = []
		if cell not in visited:
			cluster = flood_fill(cell, visited, cluster, enemy_cluster)
		var density: float = 0.0
		for n_cluster in cluster:
			density += enemy_cluster[n_cluster]
		if density < 0.0:
			enemy_neighborhood_density[cluster] = density
	
	var friendly_neighborhood_density: Dictionary = {}
	
	for cell in friendly_cluster:
		var cluster: Array = []
		if cell not in visited:
			cluster = flood_fill(cell, visited, cluster, friendly_cluster)
		var density: float = 0.0
		for n_cluster in cluster:
			density += friendly_cluster[n_cluster]
		if density > 0.0:
			friendly_neighborhood_density[cluster] = density
	
	var max_fren_density: float = 0.0
	if friendly_neighborhood_density.is_empty():
		var index: Vector2i = friendly_cluster.keys()[0]
		max_fren_density = friendly_cluster[index]
	else:
		max_fren_density = friendly_neighborhood_density.values().max()
	
	for cell in friendly_neighborhood_density:
		var weight_density: float = friendly_neighborhood_density[cell] / max_fren_density
		friendly_neighborhood_density[cell] = weight_density
	
	var max_enemy_density: float = 0.0
	if friendly_neighborhood_density.is_empty():
		var index: Vector2i = enemy_cluster.keys()[0]
		max_enemy_density = enemy_cluster[index]
	else:
		max_fren_density = enemy_neighborhood_density.values().max()
	
	for cell in enemy_neighborhood_density:
		var weight_density: float = enemy_neighborhood_density[cell] / max_enemy_density
		enemy_neighborhood_density[cell] = weight_density
	
	if weighted_enemy.values() != enemy_neighborhood_density.values() or weighted_enemy.keys() != enemy_neighborhood_density.keys():
		get_tree().call_group(&"enemy", "weigh_composite_influence", enemy_neighborhood_density)
		weighted_enemy = enemy_neighborhood_density
	if weighted_friendly.values() != friendly_neighborhood_density.values() or weighted_friendly.keys() != friendly_neighborhood_density.keys():
		get_tree().call_group(&"friendly", "weigh_composite_influence", friendly_neighborhood_density)
		weighted_friendly = friendly_neighborhood_density

func flood_fill(cell, visited, cluster, object_presence) -> Array: 
	if cell in visited: 
		return cluster
	 
	visited.append(cell) 
	cluster.append(cell) 
	for n_cell in object_presence: 
		if cell.distance_squared_to(n_cell) == 1: 
			flood_fill(n_cell, visited, cluster, object_presence)
	return cluster
