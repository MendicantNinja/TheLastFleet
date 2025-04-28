using Godot;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Numerics;
using Vector2 = System.Numerics.Vector2;

public partial class IdentifyNearbyUnits : Action
{
	public override NodeState Tick(Node agent)
	{   
		
		if (Engine.GetPhysicsFrames() % 120 != 0)
			return NodeState.FAILURE;
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		ShipWrapper ship_wrapper = (ShipWrapper) agent.Get("ShipWrapper");

		
		List<String> nearby_enemy_groups = new List<String>();
		List<RigidBody2D> idle_neighbors = new List<RigidBody2D>();
		List<String> neighbor_groups = new List<String>();

		foreach (Vector2I cell in ship_wrapper.RegistryNeighborhood)
		{
			if (ImapManager.Instance.RegistryMap.ContainsKey(cell)) 
				continue;
			foreach (RigidBody2D ship in ImapManager.Instance.RegistryMap[cell])
			{ 
				ShipWrapper unit = (ShipWrapper) ship.Get("ShipWrapper");
			   
				if (unit == null)
					continue;
				if (unit.GroupName == ship_wrapper.GroupName && unit.GroupName.Count() != 0 && ship_wrapper.GroupName.Count() != 0)
					continue;
					if (unit.IsFriendly == ship_wrapper.IsFriendly && unit.GroupName.Count() == 0)
				{
					idle_neighbors.Add(ship);
				}
				if (unit.IsFriendly != ship_wrapper.IsFriendly && unit.GroupName.Count() != 0 && !nearby_enemy_groups.Contains(unit.GroupName))
				{
					nearby_enemy_groups.Add(unit.GroupName);
				}
				if (unit.IsFriendly == ship_wrapper.IsFriendly && unit.GroupName.Count() != 0 && !neighbor_groups.Contains(unit.GroupName))
				{
					neighbor_groups.Add(unit.GroupName);
				}
			}
		}
		List<string> nearby_attackers = new List<string>();
		foreach (RigidBody2D ship in ship_wrapper.TargetedBy)
		{
			if (ship == null)
				continue;

			ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
			if (!nearby_attackers.Contains(unit.GroupName))
			{
				nearby_attackers.Add(unit.GroupName);
			}
		}
		foreach (RigidBody2D ship in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
		{
			if (ship == null)
				continue;

			ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
			foreach (RigidBody2D attacker_ship in unit.TargetedBy)
			{
				if (attacker_ship == null)
					continue;

				ShipWrapper attacker = (ShipWrapper)attacker_ship.Get("ShipWrapper");
				if (!nearby_attackers.Contains(attacker.GroupName))
				{
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
				if (ship == null)
					continue;

				ShipWrapper unit = (ShipWrapper)ship.Get("ShipWrapper");
				SteerData unit_steering = (SteerData)ship.Get("SteerData");

				if (unit.TargetedUnits.Count() == 0 && unit_steering.TargetPosition == Vector2.Zero && ship_wrapper.CombatFlag == false)
				{
					availability_count += 1;
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
