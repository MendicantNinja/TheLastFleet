using Godot;
using Globals;
using InfluenceMap;
using System;
using System.Collections.Generic;
using System.Linq; // Quicker access?  Used in ThreatDetection.cs

public partial class DetectSkirmishUnits : Action
{
	public override NodeState Tick(Node agent)
	{
		if (Engine.GetPhysicsFrames() % 65 != 0)
			return NodeState.FAILURE;
		
		ShipWrapper ship_wrapper = (ShipWrapper) agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		
		if (ship_wrapper.CombatGoal != (int)Globals.Goal.SKIRMISH || ship_wrapper.GroupName.Length == 0 || 
			(ship_wrapper.RegistryCell.X < 0 && ship_wrapper.RegistryCell.Y < 0))
		{
			return NodeState.SUCCESS;
		}

		if (ship_wrapper.TargetedUnits.Count > 0)
		{
			return NodeState.SUCCESS;
		}

		Node globals = GetTree().Root.GetNode("globals");
		float group_strength = 0.0f;
		Godot.Collections.Array group_positions = new Godot.Collections.Array();
		foreach (RigidBody2D unit in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			if (unit == null) continue;
			ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
			group_strength += unit_wrapper.ApproxInfluence;
			group_positions.Add(unit.GlobalPosition);
		}
		Godot.Vector2 group_geo_median = (Godot.Vector2)globals.Call("geometric_median_of_objects", group_positions);

		Godot.Collections.Array player_registry_cells = new Godot.Collections.Array();
		Godot.Collections.Array player_agents = (Godot.Collections.Array)GetTree().GetNodesInGroup("friendly");

		Dictionary<Vector2I[], List<RigidBody2D>> registry_cluster = new Dictionary<Vector2I[], List<RigidBody2D>>();
		foreach (RigidBody2D unit in player_agents)
		{
			if (unit == null) continue;
			ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
			if (unit_wrapper.RegistryCell.X < 0 || unit_wrapper.RegistryCell.Y < 0) continue;
			if (!player_registry_cells.Contains(unit_wrapper.RegistryCell))
			{
				player_registry_cells.Add(unit_wrapper.RegistryCell);
			}

			if (!registry_cluster.ContainsKey(unit_wrapper.RegistryCluster))

			{
				registry_cluster[unit_wrapper.RegistryCluster] = new List<RigidBody2D>();
			}
			registry_cluster[unit_wrapper.RegistryCluster].Add(unit);
		}

		if (player_registry_cells.Count == 0)
			return NodeState.SUCCESS;
		
		Vector2I[] registry_neighborhood = ship_wrapper.RegistryNeighborhood;
		foreach (Godot.Vector2I cell in player_registry_cells)
		{
			if (ship_wrapper.RegistryNeighborhood.Contains(cell))
			{
				ship_wrapper.SetGoalFlag(true);
				break;
			}
		}

		if (!ship_wrapper.GoalFlag)
			return NodeState.SUCCESS;

		Dictionary<Vector2I[], float> target_strength = new Dictionary<Vector2I[], float>();
		Dictionary<Vector2I[], Godot.Vector2 > target_geo_median = new Dictionary<Vector2I[], Godot.Vector2>();
		foreach (KeyValuePair<Vector2I[], List<RigidBody2D>> pair in registry_cluster)
		{
			Vector2I[] cluster = pair.Key;
			List<RigidBody2D> agents_in_cluster = registry_cluster[cluster];
			float relative_strength = 0.0f;
			Godot.Collections.Array unit_positions = new Godot.Collections.Array();
			foreach (RigidBody2D unit in agents_in_cluster)
			{
				if (unit == null) continue;
				ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
				relative_strength += unit_wrapper.ApproxInfluence;
				unit_positions.Add(unit.GlobalPosition);
			}
			target_geo_median[cluster] = (Godot.Vector2)globals.Call("geometric_median_of_objects", unit_positions);
			target_strength[cluster] = relative_strength;
			
		}

		if (registry_cluster.Count == 1)
		{
			List<RigidBody2D> target_units = registry_cluster[registry_cluster.Keys.First()];
			GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", target_units.ToArray());
			GetTree().CallGroup(ship_wrapper.GroupName, "set_goal_flag", true);
			return NodeState.SUCCESS;
		}

		// Distance weighting
		List<float> dist_to_cell = new List<float>();
		foreach (KeyValuePair <Vector2I[], Godot.Vector2> pair in target_geo_median)
		{
			Vector2I[] cluster = pair.Key;
			Godot.Vector2 player_median = pair.Value;
			float distance_squared = group_geo_median.DistanceSquaredTo(player_median);
			dist_to_cell.Add(distance_squared); 
		}

		float min_distance = float.MaxValue;
		foreach (float distance in dist_to_cell)
		{
			if (distance < min_distance)
				min_distance = distance;
		}

		Dictionary<float, Vector2I[]> weigh_strength = new Dictionary<float, Vector2I[]>();
		float min_dist = dist_to_cell.Min();
		foreach (KeyValuePair<Vector2I[], float> pair in target_strength)
		{
			Vector2I[] cell = pair.Key;
			float relative_strength = pair.Value;
			Godot.Vector2 target_median = target_geo_median[cell];
			float dist_to = group_geo_median.DistanceSquaredTo(target_median);
			float weight = dist_to / min_dist;
			float reweighed_strength = group_strength + relative_strength * weight;
			weigh_strength[reweighed_strength] = cell;
			// reweighed strength is the key, pair is the value
		}

		float min_strength = weigh_strength.Keys.Min();
		float max_strength = weigh_strength.Keys.Max();

		// Select the cluster with minimum weighted strength
		Vector2I[] cluster_key = weigh_strength[min_strength];
		List<RigidBody2D> target_units_final = registry_cluster[cluster_key];
		GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", target_units_final.ToArray());
		GetTree().CallGroup(ship_wrapper.GroupName, "set_goal_flag", true);


		return NodeState.SUCCESS;
	}

}
