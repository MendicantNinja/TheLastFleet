using Godot;
using System.Collections.Generic;
using Vector2 = System.Numerics.Vector2;

public partial class IdentifyNearbyUnits : Action
{
	public override NodeState Tick(Node agent)
	{   
		if (Engine.GetPhysicsFrames() % 120 != 0) return NodeState.FAILURE;

		ShipWrapper ship_wrapper = (ShipWrapper) agent.Get("ShipWrapper");

		List<string> nearby_enemy_groups = new List<string>();
		List<RigidBody2D> idle_neighbors = new List<RigidBody2D>();
		List<string> neighbor_groups = new List<string>();

		foreach (Vector2I cell in ship_wrapper.RegistryNeighborhood)
		{
			if (!ImapManager.Instance.RegistryMap.ContainsKey(cell)) continue; // Fair idea, do not check a registry cell that contains no agents

			foreach (RigidBody2D ship in ImapManager.Instance.RegistryMap[cell])
			{ 
				if (!IsInstanceValid(ship) || ship.IsQueuedForDeletion()) continue;

				ShipWrapper unit_wrapper = (ShipWrapper) ship.Get("ShipWrapper");
				if (unit_wrapper.GroupName == ship_wrapper.GroupName && unit_wrapper.GroupName.Length > 0 && ship_wrapper.GroupName.Length > 0)
				{
					continue;
				}
					
				if (unit_wrapper.IsFriendly == ship_wrapper.IsFriendly && unit_wrapper.GroupName.Length == 0)
				{
					idle_neighbors.Add(ship);
				}
				else if (unit_wrapper.IsFriendly != ship_wrapper.IsFriendly && unit_wrapper.GroupName.Length > 0 && !nearby_enemy_groups.Contains(unit_wrapper.GroupName))
				{
					nearby_enemy_groups.Add(unit_wrapper.GroupName);
				}
				else if (unit_wrapper.IsFriendly == ship_wrapper.IsFriendly && unit_wrapper.GroupName.Length > 0 && !neighbor_groups.Contains(unit_wrapper.GroupName))
				{
					neighbor_groups.Add(unit_wrapper.GroupName);
				}
			}
		}

		List<string> nearby_attackers = new List<string>();
		foreach (RigidBody2D ship in ship_wrapper.TargetedBy)
		{
			if (!IsInstanceValid(ship) || ship.IsQueuedForDeletion()) continue;

			ShipWrapper unit_wrapper = (ShipWrapper)ship.Get("ShipWrapper");
			if (!nearby_attackers.Contains(unit_wrapper.GroupName) && nearby_enemy_groups.Contains(unit_wrapper.GroupName))
			{
				nearby_attackers.Add(unit_wrapper.GroupName);
			}
		}

		// Really bad design oversight here since not all ships in a group will get targetted
		
		foreach (RigidBody2D ship in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			if (!IsInstanceValid(ship) || ship.IsQueuedForDeletion()) continue;

			ShipWrapper unit_wrapper = (ShipWrapper)ship.Get("ShipWrapper");
			foreach (RigidBody2D attacker_ship in unit_wrapper.TargetedBy)
			{
				if (!IsInstanceValid(attacker_ship) || attacker_ship.IsQueuedForDeletion()) continue;

				ShipWrapper attacker = (ShipWrapper)attacker_ship.Get("ShipWrapper");
				if (!nearby_attackers.Contains(attacker.GroupName) && nearby_enemy_groups.Contains(unit_wrapper.GroupName))
				{
					//GD.Print(attacker.GroupName, " is attacking ", ship_wrapper.GroupName);
					nearby_attackers.Add(attacker.GroupName);
				}
			}
		}

		List<string> available_neighbor_groups = new List<string>();
		foreach (string group_name in neighbor_groups)
		{
			int availability_count = 0;
			var group = GetTree().GetNodesInGroup(group_name);

			foreach (RigidBody2D ship in group)
			{
				if (!IsInstanceValid(ship) || ship.IsQueuedForDeletion()) continue;

				ShipWrapper unit_wrapper = (ShipWrapper)ship.Get("ShipWrapper");
				SteerData unit_steering = (SteerData)ship.Get("SteerData");

				if (unit_wrapper.TargetedUnits.Count == 0 && unit_steering.TargetPosition == Vector2.Zero && ship_wrapper.CombatFlag == false)
				{
					availability_count++;
				}
			}

			if (availability_count == group.Count)
			{
				available_neighbor_groups.Add(group_name);
			}
		}
		ship_wrapper.AvailableNeighborGroups = available_neighbor_groups;
		ship_wrapper.NearbyEnemyGroups = nearby_enemy_groups;
		ship_wrapper.IdleNeighbors = idle_neighbors;
		ship_wrapper.NeighborGroups = neighbor_groups;
		ship_wrapper.NearbyAttackers = nearby_attackers;

		return NodeState.FAILURE;
	}

}
