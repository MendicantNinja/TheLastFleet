using Godot;
using InfluenceMap;
using Globals;
using System;
using System.Collections.Generic;
using System.Linq;

[GlobalClass]
public partial class ImapManager : Node
{
	public static ImapManager Instance { get; private set; }

	private List<ImapTemplate> OccupancyTemplates;
	private List<ImapTemplate> ThreatTemplates;
	private List<ImapTemplate> InverseOccupancyTemplates;
	private List<ImapTemplate> InverseThreatTemplates;

	public Dictionary<ImapType, Imap> AgentMaps = new Dictionary<ImapType, Imap>();
	[Export]
	public Godot.Collections.Dictionary<Vector2I, Godot.Collections.Array<RigidBody2D>> RegistryMap = new Godot.Collections.Dictionary<Vector2I, Godot.Collections.Array<RigidBody2D>>();
	//public Imap ArenaInfluenceMap;
	public Imap VulnerabilityMap;
	//public Imap InverseTensionMap;
	public Imap TensionMap;
	public Imap WeightedImap;
	public Imap GoalMap;

	public List<Godot.Collections.Array<Vector2I>> FriendlyClusters;
	public List<Godot.Collections.Array<Vector2I>> EnemyClusters;
	public Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float> WeightedEnemy = new Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float>();
	public Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float> WeightedFriendly = new Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float>();
	public int DefaultRadius = 5;
	public int ArenaWidth = 17000;
	public int ArenaHeight = 20000;
	public int DefaultCellSize = 250;
	public int MaxCellSize = 2250;

	public override void _Ready()
	{
		int longest_range = 2250 / DefaultCellSize;
		OccupancyTemplates = InitOccupancyMapTemplates(DefaultRadius, ImapType.OccupancyMap, 1.0f);
		ThreatTemplates = InitThreatMapTemplates(longest_range, ImapType.ThreatMap, 1.0f);
		InverseOccupancyTemplates = InitOccupancyMapTemplates(DefaultRadius, ImapType.OccupancyMap, -1.0f);
		InverseThreatTemplates = InitThreatMapTemplates(longest_range, ImapType.ThreatMap, -1.0f);
		Instance = this;
	}

	public void RegisterMap(Imap map)
	{
		AgentMaps[map.Type] = map;
	}

	public void InitializeArenaMaps()
	{
		Imap ArenaInfluenceMap = new Imap(ArenaWidth, ArenaHeight, 0.0f, 0.0f, DefaultCellSize, ImapType.InfluenceMap);
		VulnerabilityMap = new Imap(ArenaWidth, ArenaHeight, 0.0f, 0.0f, DefaultCellSize, ImapType.VulnerabilityMap);
		Imap InverseTensionMap = new Imap(ArenaWidth, ArenaHeight, 0.0f, 0.0f, DefaultCellSize, ImapType.TensionMap);
		TensionMap = new Imap(ArenaWidth, ArenaHeight, 0.0f, 0.0f, DefaultCellSize, ImapType.TensionMap);
		WeightedImap = new Imap(ArenaWidth, ArenaHeight, 0.0f, 0.0f, DefaultCellSize, ImapType.InfluenceMap);
		GoalMap = new Imap(ArenaWidth, ArenaHeight, 0.0f, 0.0f, DefaultCellSize, ImapType.InfluenceMap);
		RegisterMap(ArenaInfluenceMap);
		RegisterMap(InverseTensionMap);
	}

	public void RegisterAgents(Godot.Collections.Array<RigidBody2D> agents, int goal = 0)
	{
		foreach (RigidBody2D n_agent in agents)
		{
			n_agent.Connect("update_agent_influence", Callable.From(() => OnUpdateAgentInfluence(n_agent)));
			n_agent.Connect("destroyed", Callable.From(() => OnAgentDestroyed(n_agent)));
			n_agent.Connect("update_registry_cell", Callable.From(() => OnUpdateRegistryCell(n_agent)));
			n_agent.Set("combat_goal", goal);
		}
	}

	public Imap GetAgentMap(int value)
	{
		if (value == 0)
		{
			return AgentMaps[ImapType.InfluenceMap];
		}
		else
		{
			return AgentMaps[ImapType.TensionMap];
		}
	}
	public void OnUpdateAgentInfluence(RigidBody2D agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		Vector2I current_cell_idx = new Vector2I((int)agent.GlobalPosition.Y / DefaultCellSize, (int)agent.GlobalPosition.X / DefaultCellSize);
		foreach (ImapType type in AgentMaps.Keys)
		{
			Imap map = AgentMaps[type];
			
			Imap template_map = ship_wrapper.TemplateMaps[type];
			if (Vector2I.Zero != ship_wrapper.ImapCell)
			{
				map.AddMap(template_map, ship_wrapper.ImapCell.X, ship_wrapper.ImapCell.Y, -1.0f);
			}

			map.AddMap(template_map, current_cell_idx.X, current_cell_idx.Y, 1.0f);
		}

		WeightedImap.AddMap(ship_wrapper.WeighInfluence, ship_wrapper.ImapCell.X, ship_wrapper.ImapCell.Y, -1.0f);
		WeightedImap.AddMap(ship_wrapper.WeighInfluence, current_cell_idx.X, current_cell_idx.Y, 1.0f);
	}

	public void OnAgentDestroyed(RigidBody2D agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		foreach (ImapType type in AgentMaps.Keys)
		{
			Imap template_map = ship_wrapper.TemplateMaps[type];
			Imap map = AgentMaps[type];
			map.AddMap(template_map, ship_wrapper.ImapCell.X, ship_wrapper.ImapCell.Y, -1.0f);
		}
	}

	public void OnUpdateRegistryCell(RigidBody2D agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		Godot.Collections.Array<RigidBody2D> agent_registry = new Godot.Collections.Array<RigidBody2D>();
		Vector2I current_cell_idx = new Vector2I((int)agent.GlobalPosition.Y / MaxCellSize, (int)agent.GlobalPosition.X / MaxCellSize);

		if (RegistryMap.ContainsKey(ship_wrapper.RegistryCell))
		{
			agent_registry = RegistryMap[ship_wrapper.RegistryCell];
		}

		if (agent_registry.Contains(agent))
		{
			agent_registry.Remove(agent);
			RegistryMap[ship_wrapper.RegistryCell] = agent_registry;
			agent_registry.Clear();
		}

		if (RegistryMap.ContainsKey(current_cell_idx))
		{
			agent_registry = RegistryMap[current_cell_idx];
		}

		if (!agent_registry.Contains(agent))
		{
			agent_registry.Add(agent);
		}

		RegistryMap[current_cell_idx] = agent_registry;

		List<Vector2I> remove_cells = new List<Vector2I>();
		foreach (Vector2I cell in RegistryMap.Keys)
		{
			if (RegistryMap[cell].Count == 0) remove_cells.Add(cell);
		}

		foreach (Vector2I cell in remove_cells)
		{
			RegistryMap.Remove(cell);
		}
		
		Godot.Collections.Array<Vector2I> registry_neighborhood = new Godot.Collections.Array<Vector2I>();
		int radius = 1;
		for (int m = -radius; m <= radius; m++)
		{
			for (int n = -radius; n <= radius; n++)
			{
				Vector2I cell = new Vector2I(current_cell_idx.X + m, current_cell_idx.Y + n);
				if (cell.X < 0 || cell.Y < 0) continue;
				registry_neighborhood.Add(cell);
			}
		}

		agent.Set("registry_neighborhood", registry_neighborhood);
	}

	public void WeighForceDensity()
	{
		Dictionary<Vector2I, float> friendly_cell_density = new Dictionary<Vector2I, float>();
		Dictionary<Vector2I, float> enemy_cell_density = new Dictionary<Vector2I, float>();
		foreach (Vector2I cell in RegistryMap.Keys)
		{
			Godot.Collections.Array<RigidBody2D> agent_registry = RegistryMap[cell];
			float enemy_density = 0.0f;
			float friendly_density = 0.0f;
			foreach (RigidBody2D agent in agent_registry)
			{
				float approx_influence = (float)agent.Get("approx_influence");
				if (approx_influence > 0.0f) friendly_density += approx_influence;
				if (approx_influence < 0.0f) enemy_density += approx_influence;
			}

			if (friendly_density > 0.0f) friendly_cell_density[cell] = friendly_density;
			if (enemy_density < 0.0f) enemy_cell_density[cell] = enemy_density;
		}

		if (friendly_cell_density.Keys.Count == 0 || enemy_cell_density.Keys.Count == 0) 
		{
			return;
		}
		

		Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float> enemy_neighborhood_density = new Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float>();
		List<Godot.Collections.Array<Vector2I>> n_cluster = new List<Godot.Collections.Array<Vector2I>>();
		float max_enemy_density = 0.0f;
		List<Vector2I> visited = new List<Vector2I>();
		foreach (Vector2I cell in enemy_cell_density.Keys)
		{
			Godot.Collections.Array<Vector2I> cluster = new Godot.Collections.Array<Vector2I>();
			if (!visited.Contains(cell))
			{
				cluster = RegistryFloodFill(cell, visited, cluster, enemy_cell_density);
				n_cluster.Add(cluster);
			}
			else
			{
				continue;
			}

			float density = 0.0f;
			foreach (Vector2I n_cell in cluster) density += enemy_cell_density[n_cell];

			if (density < 0.0f)
			{
				enemy_neighborhood_density[cluster] = density;
			}
			
			if (density < 0.0f && density < max_enemy_density)
			{
				max_enemy_density = density;
			}
		}
		EnemyClusters = n_cluster;
		n_cluster.Clear();

		Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float> friendly_neighborhood_density = new Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float>();
		float max_friendly_density = 0.0f;
		visited.Clear();
		foreach (Vector2I cell in friendly_cell_density.Keys)
		{
			Godot.Collections.Array<Vector2I> cluster = new Godot.Collections.Array<Vector2I>();
			if (!visited.Contains(cell))
			{
				cluster = RegistryFloodFill(cell, visited, cluster, friendly_cell_density);
				n_cluster.Add(cluster);
			}
			else
			{
				continue;
			}

			float density = 0.0f;
			foreach (Vector2I n_cell in cluster) density += friendly_cell_density[n_cell];

			if (density > 0.0f)
			{
				friendly_neighborhood_density[cluster] = density;
			}

			if (density > 0.0f && density > max_friendly_density)
			{
				max_friendly_density = density;
			}
		}
		FriendlyClusters = n_cluster;

		if (friendly_neighborhood_density.Keys.Count == 0)
		{
			Vector2I index = friendly_cell_density.Keys.First();
			max_friendly_density = friendly_cell_density[index];
		}

		if (enemy_neighborhood_density.Keys.Count == 0)
		{
			Vector2I index = enemy_cell_density.Keys.First();
			max_enemy_density = enemy_cell_density[index];
		}

		
		foreach (Godot.Collections.Array<Vector2I> cluster in friendly_neighborhood_density.Keys)
		{
			float weigh_density = (float)friendly_neighborhood_density[cluster] / max_friendly_density;
			friendly_neighborhood_density[cluster] = weigh_density;
		}

		foreach (Godot.Collections.Array<Vector2I> cluster in enemy_neighborhood_density.Keys)
		{
			float weigh_density = (float)enemy_neighborhood_density[cluster] / max_enemy_density;
			enemy_neighborhood_density[cluster] = weigh_density;
		}

		if (WeightedEnemy.Values != enemy_neighborhood_density.Values || WeightedEnemy.Keys != enemy_neighborhood_density.Keys)
		{
			GetTree().CallGroup("enemy", "weigh_composite_influence", enemy_neighborhood_density);
			WeightedEnemy = enemy_neighborhood_density;
		}

		if (WeightedFriendly.Values != friendly_neighborhood_density.Values || WeightedFriendly.Keys != friendly_neighborhood_density.Keys)
		{
			GetTree().CallGroup("friendly", "weigh_composite_influence", friendly_neighborhood_density);
			WeightedFriendly = friendly_neighborhood_density;
		}
	}

	public Godot.Collections.Array<Vector2I> RegistryFloodFill(Vector2I cell, List<Vector2I> visited, Godot.Collections.Array<Vector2I> cluster, Dictionary<Vector2I, float> cell_density)
	{
		if (visited.Contains(cell)) return cluster;

		visited.Add(cell);
		cluster.Add(cell);
		foreach (Vector2I n_cell in cell_density.Keys)
		{
			if (cell.DistanceSquaredTo(n_cell) == 1) RegistryFloodFill(n_cell, visited, cluster, cell_density);
		}
		return cluster;
	}

	public List<ImapTemplate> InitOccupancyMapTemplates(int max_radius, ImapType type, float magnitude = 1.0f)
	{
		List<ImapTemplate> new_templates = new List<ImapTemplate>();

		// Loop over each desired “radius” (which governs the grid’s half‐width)
		for (int r = 1; r <= max_radius; r++)
		{
			// Create a square grid whose side is 2*r+1.
			int size = (2 * r) + 1;
			Imap new_map = new Imap(size, size, 0.0f, 0.0f);
			new_map.PropagateInfluenceFromCenter(magnitude);
			new_templates.Add(new ImapTemplate(r, type, new_map));
		}

		return new_templates;
	}

	public List<ImapTemplate> InitThreatMapTemplates(int max_radius, ImapType type, float magnitude = 1.0f)
	{
		List<ImapTemplate> new_templates = new List<ImapTemplate>();

		for (int r = 1; r <= max_radius; r++)
		{
			int size = (2 * r) + 1;
			Imap new_map = new Imap(size, size, 0.0f, 0.0f);
			new_map.PropagateInfluenceAsRing(magnitude);
			new_templates.Add(new ImapTemplate(r, type, new_map));
		}

		return new_templates;
	}

	public ImapTemplate GetTemplate(ImapType type, int radius)
	{
		switch(type)
		{
			case ImapType.OccupancyMap:
				foreach (ImapTemplate n_template in OccupancyTemplates)
				{
					if (radius <= n_template.Radius) return n_template;
				}
				return OccupancyTemplates.Last(); 
			case ImapType.ThreatMap:
				foreach (ImapTemplate n_template in ThreatTemplates)
				{
					if (radius <= n_template.Radius) return n_template;
				}
				return ThreatTemplates.Last();
			case ImapType.InverseOccupancyMap:
				foreach (ImapTemplate n_template in InverseOccupancyTemplates)
				{
					if (radius <= n_template.Radius) return n_template;
				}
				return InverseOccupancyTemplates.Last();
			case ImapType.InverseThreatMap:
				foreach (ImapTemplate n_template in InverseThreatTemplates)
				{
					if (radius <= n_template.Radius) return n_template;
				}
				return InverseThreatTemplates.Last();
			default:
				throw new ArgumentOutOfRangeException(type.ToString(), type, null);
		}
	}
}
