using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using Vector2 = System.Numerics.Vector2;
using Godot.Collections;

public partial class ThreatDetection : Action
{
	string true_name = "";
	string tmp_name = "threat detect ";

	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		
		// You will need to know this is how we currently access globals
		// Node globals = GetTree().Root.GetNode("globals");
		// Call its functions like this
		// globals.Call("generate_group_target_positions", agent);

		Node globals = GetTree().Root.GetNode("globals");
		if (Engine.GetPhysicsFrames() % 120 != 0 || ship_wrapper.RegistryCell == Godot.Vector2I.One || steer_data.TargetPosition != Vector2.Zero)
		{
			return NodeState.FAILURE;
		}
		else if (ship_wrapper.CombatFlag || ship_wrapper.VentFluxFlag || ship_wrapper.FallbackFlag || ship_wrapper.RetreatFlag)
		{
			return NodeState.FAILURE;
		}

		if (true_name.Count() == 0 && ship_wrapper.IsFriendly)
		{
			true_name = "Temporary Friendly Group ";
			tmp_name += "tmp friendly";
		}
		else if (true_name.Count() == 0 && !ship_wrapper.IsFriendly)
		{
			true_name = "Temporary Enemy Group ";
			tmp_name += "tmp enemy";
		}

		// Check if any unit in the group has a non-zero target position or is in combat
		foreach (RigidBody2D ship in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
			SteerData unit_steering = (SteerData)ship.Get("SteerData");
			if (unit == null) continue;
			if (unit_steering.TargetPosition != Vector2.Zero || ship_wrapper.CombatFlag)
				return NodeState.FAILURE;
		}

		List<String> attacker_groups = ship_wrapper.NearbyAttackers;
		if (attacker_groups.Count == 0)
			return NodeState.FAILURE;

		List<RigidBody2D> idle_neighbors = ship_wrapper.IdleNeighbors;
		List<String> available_neighbor_groups = ship_wrapper.AvailableNeighborGroups;

		if (ship_wrapper.GroupName.Count() == 0 && available_neighbor_groups.Count == 0 && idle_neighbors.Count > 0)
		{   // I had to use Godot's Vector2/classes to compare to the ships global_position property/pass to the global methods. 
			Godot.Collections.Dictionary<Godot.Vector2, RigidBody2D> unit_positions = new Godot.Collections.Dictionary<Godot.Vector2, RigidBody2D>();
			foreach (RigidBody2D ship in idle_neighbors)
			{
				ship.AddToGroup(tmp_name);
				Variant global_position_to_cast = ship.Get("global_position");
				Godot.Vector2 ship_position = global_position_to_cast.As<Godot.Vector2>();
				unit_positions[ship_position] = ship;
			}
			Godot.Collections.Array<Godot.Vector2> key_array = new Godot.Collections.Array<Godot.Vector2>(unit_positions.Keys);
			Godot.Vector2 geo_median = (Godot.Vector2)globals.Call("geometric_median_of_objects", key_array);
			RigidBody2D leader_body = (Godot.RigidBody2D)globals.Call("find_unit_nearest_to_median", geo_median, key_array);
			
			string new_group_name = true_name + agent.Name;
			GetTree().CallGroup(tmp_name, "group_add", new_group_name);
			GetTree().CallGroup(tmp_name, "group_remove", tmp_name);
			ShipWrapper leader_ship_wrapper = (ShipWrapper)leader_body.Get("ShipWrapper");
			leader_ship_wrapper.SetGroupLeader(true);
		}

		if (ship_wrapper.GroupName.Count() == 0 && available_neighbor_groups.Count > 0)
		{
			// Pick a random group from available_neighbor_groups
			int pick_rand_group = (int)GD.RandRange(0, available_neighbor_groups.Count - 1);
			string group_name = available_neighbor_groups[pick_rand_group];

			// Pick a random member of that group
			RigidBody2D rand_group_member = (RigidBody2D)GetTree().GetFirstNodeInGroup(group_name);
			ShipWrapper rand_member_wrapper = (ShipWrapper)rand_group_member.Get("ShipWrapper");

			if (rand_member_wrapper != null)
			{
				ship_wrapper.SetTargetedUnits(rand_member_wrapper.TargetedUnits); 
			}

			agent.Call("group_add", group_name);
		}

		if (ship_wrapper.GroupName.Count() == 0)
		{
			return NodeState.FAILURE;
		}

		// Calculate agent group strength
		float agent_group_strength = 0.0f;
		foreach (RigidBody2D unit_body in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			if (unit_body == null)
				continue;

			ShipWrapper unit = (ShipWrapper)unit_body.Get("ShipWrapper");
			if (unit == null)
				continue;

			agent_group_strength += unit.ApproxInfluence;
		}

		// Attackers and their total strength
		Godot.Collections.Array<RigidBody2D> attackers = new Godot.Collections.Array<RigidBody2D>();
		float total_attacker_strength = 0.0f;
		foreach (string group_name in attacker_groups)
		{
			float relative_strength = 0.0f;
			foreach (RigidBody2D ship in GetTree().GetNodesInGroup(group_name))
			{
				if (ship == null)
					continue;

				attackers.Add(ship);

				ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
				if (unit != null)
				{
					relative_strength += unit.ApproxInfluence;
				}
			}
			total_attacker_strength += relative_strength;
		}

		if (attackers.Count == 0)
		{
			return NodeState.FAILURE;
		}

		Godot.Collections.Dictionary<float, string> nearby_group_strength = new Godot.Collections.Dictionary<float, string>();
		foreach (String group_name in available_neighbor_groups)
		{
			
			float relative_group_strength = 0.0f;
			foreach (RigidBody2D ship in GetTree().GetNodesInGroup(group_name))
			{
				ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
				if (unit == null) continue;
				relative_group_strength += unit.ApproxInfluence;
			}
			if (relative_group_strength == 0.0f)
				continue;
			nearby_group_strength[relative_group_strength + agent_group_strength] = group_name;
		}


		return NodeState.FAILURE;
	}

}
