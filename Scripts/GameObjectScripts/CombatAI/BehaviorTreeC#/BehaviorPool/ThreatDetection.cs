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
        Node globals = GetTree().Root.GetNode("globals");
        if (Engine.GetPhysicsFrames() % 120 != 0 || ship_wrapper.RegistryCell == Godot.Vector2I.One || steer_data.TargetPosition != Vector2.Zero)
        {
            return NodeState.FAILURE;
        }
        else if (ship_wrapper.CombatFlag || ship_wrapper.VentFluxFlag || ship_wrapper.FallbackFlag || ship_wrapper.RetreatFlag)
        {
            return NodeState.FAILURE;
        }

          // Initialize group names based on the ship's friendly status
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
        // Ported
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

        // You will need to know this is how we currently access globals
		// Node globals = GetTree().Root.GetNode("globals");
		// Call its functions like this
		// globals.Call("generate_group_target_positions", agent);


        if (ship_wrapper.GroupName.Count() == 0 && available_neighbor_groups.Count == 0 && idle_neighbors.Count > 0)
        {   // I had to use Godot's Vector2 to compare to the ships global_position property. 
            Dictionary<Godot.Variant, RigidBody2D> unit_positions = new Dictionary<Variant, RigidBody2D>();
            foreach (RigidBody2D ship in idle_neighbors)
            {
                ship.AddToGroup(tmp_name);
                unit_positions[ship.Get("global_position")] = ship;
            }

            Vector2 geo_median = globals.Call("geometric_median_of_objects", unit_positions.Keys.ToList());
            ShipWrapper leader = globals.find_unit_nearest_to_median(geo_median, unit_positions);
            string new_group_name = true_name + agent.Name;
            GetTree().CallGroup(tmp_name, "group_add", new_group_name);
            GetTree().CallGroup(tmp_name, "group_remove", tmp_name);
            leader.SetGroupLeader(true);
        }
















        Dictionary<float, string> nearby_group_strength = new Dictionary<float, string>();
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
