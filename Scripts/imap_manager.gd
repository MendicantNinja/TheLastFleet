extends Node
class_name ImapManager

var arena_width: int = 17000
var arena_height: int = 20000
var max_cell_size: int = 250

enum MapType {
	OCCUPANCY_MAP,
	THREAT_MAP,
	TENSION_MAP,
}

var template_maps: Dictionary = {}
var current_maps: Dictionary = {}

func _init():
	var occupancy_templates: ImapTemplate = ImapTemplate.new()
	var threat_templates: ImapTemplate = ImapTemplate.new()
	occupancy_templates.init_occupancy_map_templates(5)
	threat_templates.init_threat_map_templates(5)
	template_maps[occupancy_templates.type] = occupancy_templates
	template_maps[threat_templates.type] = threat_templates

func register_map(map: Imap) -> void:
	current_maps[map.map_type] = map

func register_agents(agents: Array) -> void:
	for agent: Ship in agents:
		agent.update_agent_influence.connect(_on_agent_influence_changed.bind(agent))
		agent.destroyed.connect(_on_agent_destroyed.bind(agent))

func _on_agent_influence_changed(prev_position: Vector2, agent: Ship) -> void:
	for imap_type in current_maps:
		var template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = current_maps[imap_type]
		var prev_cell_index: Vector2 = map.find_cell_index_from_position(prev_position)
		var current_cell_index: Vector2 = map.find_cell_index_from_position(agent.global_position)
		#var adjust_imap: Imap = map.correct_influence(template_map, current_cell_index, agent.global_position)
		if prev_position == Vector2.ZERO:
			map.add_map(template_map, current_cell_index.x, current_cell_index.y, 1.0)
			continue
		map.add_map(template_map, prev_cell_index.x, prev_cell_index.y, -1.0)
		map.add_map(template_map, current_cell_index.x, current_cell_index.y, 1.0)

func _on_agent_destroyed(agent: Ship) -> void:
	var agent_position: Vector2 = agent.global_position
	for imap_type in current_maps:
		var template_map: Imap = agent.template_maps[imap_type]
		var map: Imap = current_maps[imap_type]
		var cell_index: Vector2 = map.find_cell_index_from_position(agent_position)
		template_map.add_map(map, cell_index.x, cell_index.y, -1.0)
