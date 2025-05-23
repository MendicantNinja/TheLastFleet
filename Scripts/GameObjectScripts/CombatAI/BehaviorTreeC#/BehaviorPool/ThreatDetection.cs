using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using Vector2 = System.Numerics.Vector2;

public partial class ThreatDetection : Action
{
	string true_name = "";
	string tmp_name = "threat detect ";

	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		
		if (Engine.GetPhysicsFrames() % 120 != 0 || ship_wrapper.RegistryCell == Godot.Vector2I.Zero || steer_data.TargetPosition != Vector2.Zero)
		{
			return NodeState.FAILURE;
		}
		else if (ship_wrapper.VentFluxFlag == true || ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true)
		{
			return NodeState.FAILURE;
		}
		
		if (true_name.Length == 0 && ship_wrapper.IsFriendly)
		{
			true_name = "Temporary Friendly Group ";
			tmp_name += "tmp friendly";
		}
		else if (true_name.Length == 0 && !ship_wrapper.IsFriendly)
		{
			true_name = "Temporary Enemy Group ";
			tmp_name += "tmp enemy";
		}

		Node globals = GetTree().Root.GetNode("globals");
		// Check if any unit in the group has a non-zero target position or is in combat
		foreach (RigidBody2D ship in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			if (!IsInstanceValid(ship)|| ship.IsQueuedForDeletion()) continue;
			ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
			SteerData unit_steering = (SteerData)ship.Get("SteerData");
			if (unit.CombatFlag == true) return NodeState.FAILURE;
		}

		List<string> attacker_groups = ship_wrapper.NearbyAttackers;
		if (attacker_groups.Count == 0) return NodeState.FAILURE;

		List<RigidBody2D> idle_neighbors = ship_wrapper.IdleNeighbors;
		List<string> available_neighbor_groups = ship_wrapper.AvailableNeighborGroups;
		// For handling cases where a unit for one reason or another never received an order and there are nearby units 
		// that also never received an order
		if (ship_wrapper.GroupName.Length == 0 && available_neighbor_groups.Count == 0 && idle_neighbors.Count > 0) 
		{   // I had to use Godot's Vector2/classes to compare to the ships global_position property/pass to the global methods. 
			Godot.Collections.Dictionary<Godot.Vector2, RigidBody2D> unit_positions = new Godot.Collections.Dictionary<Godot.Vector2, RigidBody2D>();
			foreach (RigidBody2D ship in idle_neighbors)
			{
				ship.AddToGroup(tmp_name);
				unit_positions[ship.GlobalPosition] = ship;
			}
			Godot.Collections.Array<Godot.Vector2> key_array = new Godot.Collections.Array<Godot.Vector2>(unit_positions.Keys);
			Godot.Vector2 geo_median = (Godot.Vector2)globals.Call("geometric_median_of_objects", key_array);
			RigidBody2D leader_body = (Godot.RigidBody2D)globals.Call("find_unit_nearest_to_median", geo_median, unit_positions);
			
			string new_group_name = true_name + agent.Name;
			GetTree().CallGroup(tmp_name, "group_add", new_group_name);
			GetTree().CallGroup(tmp_name, "group_remove", tmp_name);
			ShipWrapper leader_ship_wrapper = (ShipWrapper)leader_body.Get("ShipWrapper");
			leader_ship_wrapper.SetGroupLeader(true);
		}

		// If there are no idle neighbors (ie belongs to no group) and only groups, find a nearby group to join
		if (ship_wrapper.GroupName.Length == 0 && available_neighbor_groups.Count > 0)
		{
			// Pick a random group from available_neighbor_groups
			int pick_rand_group = (int)GD.RandRange(0, available_neighbor_groups.Count - 1);
			string group_name = available_neighbor_groups[pick_rand_group];

			// Pick the first member of that group to provide target units to
			RigidBody2D rand_group_member = (RigidBody2D)GetTree().GetFirstNodeInGroup(group_name);
			Godot.Collections.Array<RigidBody2D> targeted_units = (Godot.Collections.Array<RigidBody2D>)rand_group_member.Get("targeted_units");

			if (targeted_units.Count > 0)
			{
				agent.Set("targeted_units", targeted_units); 
			}

			agent.Call("group_add", group_name);
		}

		// If not assigned to any group just back out who cares
		if (ship_wrapper.GroupName.Length == 0)
		{
			return NodeState.FAILURE;
		}

		// Calculate agent group strength
		float group_strength = 0.0f;
		foreach (RigidBody2D unit_body in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			if (!IsInstanceValid(unit_body) || unit_body.IsQueuedForDeletion()) continue;

			ShipWrapper unit = (ShipWrapper)unit_body.Get("ShipWrapper");
			group_strength += unit.ApproxInfluence;
		}

		// Attackers and their total strength
		Godot.Collections.Array<RigidBody2D> attackers = new Godot.Collections.Array<RigidBody2D>();
		float total_attacker_strength = 0.0f;
		foreach (string group_name in attacker_groups)
		{
			float relative_group_strength = 0.0f;
			foreach (RigidBody2D ship in GetTree().GetNodesInGroup(group_name))
			{
				if (!IsInstanceValid(ship) || ship.IsQueuedForDeletion()) continue;
				attackers.Add(ship);

				ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
				relative_group_strength += unit.ApproxInfluence;
			}
			total_attacker_strength += relative_group_strength;
		}

		if (attackers.Count == 0)
		{
			return NodeState.FAILURE;
		}

		Godot.Collections.Dictionary<float, string> nearby_group_strength = new Godot.Collections.Dictionary<float, string>();
		foreach (string group_name in available_neighbor_groups)
		{
			float relative_group_strength = 0.0f;
			foreach (RigidBody2D ship in GetTree().GetNodesInGroup(group_name))
			{
				if (!IsInstanceValid(ship) || ship.IsQueuedForDeletion()) continue;

				ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
				relative_group_strength += unit.ApproxInfluence;
			}
			if (relative_group_strength == 0.0f) continue;

			nearby_group_strength[relative_group_strength + group_strength] = group_name;
		}

		float relative_strength = Mathf.Abs(group_strength / total_attacker_strength);
		if (relative_strength >= 1.0f)
		{
			GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", attackers);
		}
		else if (nearby_group_strength.Count > 0)
		{
			foreach (float strength in nearby_group_strength.Keys)
			{
				string group_name = nearby_group_strength[strength];
				float group_relative_strength = Mathf.Abs(strength / total_attacker_strength);
				if (relative_strength + group_relative_strength >= 1.0f)
				{
					GetTree().CallGroup(group_name, "group_add", ship_wrapper.GroupName);
					if (group_name != ship_wrapper.GroupName)
					{
						GetTree().CallGroup(group_name, "group_remove", group_name);
					}
					GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", attackers);
				}
			}
		}
		
		return NodeState.FAILURE;
	}

}
