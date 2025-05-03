using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class GroupUnits : Action
{   public float strength_modifier = 1.0f;
	public StringName tmp_name = new StringName("tmp");
	public override NodeState Tick(Node agent)
	{
		// Cast the agent to your Admiral class
		Admiral admiral = agent as Admiral;
		if (admiral == null)
			return NodeState.FAILURE;

		if (Engine.GetPhysicsFrames() % 240 != 0)
			return NodeState.FAILURE;

		Node globals = GetTree().Root.GetNode("globals");
		float player_strength = admiral.PlayerStrength;
		float admiral_strength = Mathf.Abs(admiral.AdmiralStrength);

		int n_player_units = GetTree().GetNodeCountInGroup("friendly");
		int n_units = GetTree().GetNodeCountInGroup("enemy");

		List<RigidBody2D> battle_agents = GetTree().GetNodesInGroup("enemy").OfType<RigidBody2D>().ToList();
		List<RigidBody2D> available_units = new List<RigidBody2D>();
		Dictionary<float, List<RigidBody2D>> units_ranked = new Dictionary<float, List<RigidBody2D>>();

		foreach (RigidBody2D ship in battle_agents)
		{
			if (ship == null)
			{
				GD.Print("[GroupUnits] A destroyed unit is still in memory.");
				continue;
			}
			ShipWrapper unit = (ShipWrapper) ship.Get("ShipWrapper");

			float floor_inf = Mathf.Floor(Mathf.Abs(unit.ApproxInfluence));
			if (string.IsNullOrEmpty(unit.GroupName))
			{
				available_units.Add(ship);
				if (!units_ranked.ContainsKey(floor_inf))
					units_ranked[floor_inf] = new List<RigidBody2D>();
				units_ranked[floor_inf].Add(ship);
			}
		}

		if (available_units.Count == 0 || (player_strength == 0 && admiral_strength == 0))
			return NodeState.SUCCESS;
		
		float relative_strength = admiral_strength / player_strength;
		int unit_ratio = n_units / n_player_units;
		unit_ratio = unit_ratio == 0 ? 1 : unit_ratio;

		int remainder = n_units % n_player_units;
		float average_unit_strength = admiral_strength / n_units;

		float strength_coefficient = strength_modifier;
		int relative_group_size = n_units / unit_ratio;

		if (remainder > 1 && remainder != n_units)
			relative_group_size = (n_units - remainder) / unit_ratio;
		else if (remainder == n_units)
			relative_group_size = n_units;

		strength_coefficient *= relative_group_size;
		float adj_group_strength = average_unit_strength * strength_coefficient;

		List<float> sort_ranks = units_ranked.Keys.ToList();
		sort_ranks.Sort();
		available_units.Clear();
		for (int i = sort_ranks.Count - 1; i >= 0; i--)
			available_units.AddRange(units_ranked[sort_ranks[i]]);
		
		var visited_units = new List<RigidBody2D>();
		int main_group_count = relative_group_size * unit_ratio;
		StringName previous_group = new StringName("");

		while (visited_units.Count != main_group_count)
		{
			List<RigidBody2D> local_group = new List<RigidBody2D>();
			float group_strength = 0.0f;
			Godot.Collections.Dictionary<Vector2, RigidBody2D> group_positions = new Godot.Collections.Dictionary<Vector2, RigidBody2D>();

			foreach (var ship in available_units)
			{
				if (visited_units.Contains(ship))
					continue;

				ShipWrapper unit = (ShipWrapper) ship.Get("ShipWrapper");
				float unit_strength = Mathf.Round(Mathf.Abs(unit.ApproxInfluence));

				if (group_strength < adj_group_strength)
				{
					ship.AddToGroup(tmp_name);
					local_group.Add(ship);
					visited_units.Add(ship);
					group_positions[ship.GlobalPosition] = ship;
					group_strength += unit_strength;
				}

				if (group_strength >= adj_group_strength || local_group.Count == available_units.Count)
				{
					StringName group_name = new StringName(admiral.GroupKeyPrefix + admiral.Iterator);
					GetTree().CallGroup(tmp_name, "group_add", group_name);
					GetTree().CallGroup(group_name, "group_remove", tmp_name);

					admiral.AvailableGroups.Add(group_name);
					admiral.AwaitingOrders.Add(group_name);
					RigidBody2D new_leader = null;
					if (local_group.Count > 1)
					{   
						Godot.Collections.Array<Vector2> position_array = new Godot.Collections.Array<Vector2>(group_positions.Keys);
						Godot.Vector2 median = (Godot.Vector2)globals.Call("geometric_median_of_objects", position_array);
						new_leader = (RigidBody2D)globals.Call("find_unit_nearest_to_median", median, group_positions);
						new_leader.Set("group_leader", true);
						ShipWrapper this_wrapper = (ShipWrapper) new_leader.Get("ShipWrapper");
						//this_wrapper.SetGroupLeader(true);
						previous_group = this_wrapper.GroupName;
						admiral.Iterator++;
					}

					break;
				}
			}

			if (visited_units.Count == available_units.Count)
				break;
		}

		// Leftovers
		var leftover_group = new StringName(admiral.GroupKeyPrefix + admiral.Iterator);
		foreach (var unit in available_units)
		{
			if (!visited_units.Contains(unit))
				unit.AddToGroup(tmp_name);
		}

		GetTree().CallGroup(tmp_name, "group_add", leftover_group);
		GetTree().CallGroup(leftover_group, "group_remove", tmp_name);

		admiral.AvailableGroups.Add(leftover_group);
		admiral.AwaitingOrders.Add(leftover_group);
		
		return NodeState.FAILURE;
	}

}
