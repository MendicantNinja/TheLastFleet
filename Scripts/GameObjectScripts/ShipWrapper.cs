using Godot;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Threading;
using Vector2 = System.Numerics.Vector2;

public partial class ShipWrapper : Node
{
	public enum Strategy
	{
		NEUTRAL,
		DEFENSIVE,
		OFFENSIVE,
		EVASIVE
	}

	public enum Goal
	{
		SKIRMISH,
		MOTHERSHIP,
		CONTROL
	}

	[Export]
	public String GroupName { get; private set; }
	[Export]
	public bool GroupLeader { get; private set; }
	[Export]
	public bool IsFriendly { get; private set; }
	[Export]
	public bool FluxOverload { get; private set; }
	[Export]
	public bool VentFluxFlag { get; private set; }
	[Export]
	public Goal CombatGoal { get; private set; }
	[Export]
	public bool TargetInRange { get; private set; }
	[Export]
	public bool GoalFlag { get; private set; }
	[Export]
	public bool AvoidFlag { get; private set; }
	[Export]
	public bool RetreatFlag { get; private set; }
	[Export]
	public bool FallbackFlag { get; private set; }
	[Export]
	public bool CombatFlag { get; private set; }
	[Export]
	public bool SuccessfulDeploy { get; private set; }
	[Export]
	public bool MatchVelocityFlag { get; private set; }
	[Export]
	public bool ShieldFlag { get; private set; }
	public float ApproxInfluence { get; private set; }
	public float TotalFlux { get; private set; }
	public float SoftFlux { get; private set; }
	public float HardFlux { get; private set; }
	public float HullIntegrity { get; private set; }
	public float Armor { get; private set; }
	public List<Node2D> AllWeapons { get; private set; } = new List<Node2D>();
	public Strategy Posture { get; private set; }
	public List<RigidBody2D> TargetedUnits { get; private set; } = new List<RigidBody2D>();
	[Export]
	public RigidBody2D TargetUnit { get; set; }
	public Godot.Collections.Array<RigidBody2D> NeighborUnits { get; private set; } = new Godot.Collections.Array<RigidBody2D>();
	[Export]
	public Godot.Collections.Array<RigidBody2D> SeparationNeighbors { get; private set; } = new Godot.Collections.Array<RigidBody2D>();
	public Vector2I ImapCell { get; private set; }
	public Vector2I RegistryCell { get; private set; }
	public Vector2I[] RegistryNeighborhood { get; private set; }
	public float DefaultCellSize { get; private set; }
	public float MaxCellSize { get; private set; }
	[Export]
	public float AverageWeaponRange { get; private set; }
	public List<string> AvailableNeighborGroups { get; set; }
	public List<string> NearbyEnemyGroups { get; set; }
	public List<string> NeighborGroups { get; set; }
	public List<string> NearbyAttackers { get; set; }
	public List<RigidBody2D> IdleNeighbors { get; set; }
	public List<RigidBody2D> TargetedBy { get; set; }

	public void SetGroupName(string newGroupName)
	{
		GroupName = newGroupName ?? throw new ArgumentNullException(nameof(newGroupName), "Group name cannot be null.");
	}

	public void SetGroupLeader(bool value)
	{
		GroupLeader = value;
	}

	public void SetIsFriendly(bool value)
	{
		IsFriendly = value;
	}

	public void SetFluxOverload(bool value)
	{
		FluxOverload = value;
	}

	public void SetVentFluxFlag(bool value)
	{
		VentFluxFlag = value;
	}

	public void SetCombatGoal(Goal value)
	{
		CombatGoal = value;
	}

	public void SetTargetInRange(bool value)
	{
		TargetInRange = value;
	}

	public void SetGoalFlag(bool value)
	{
		GoalFlag = value;
	}

	public void SetAvoidFlag(bool value)
	{
		AvoidFlag = value;
	}

	public void SetRetreatFlag(bool value)
	{
		RetreatFlag = value;
	}

	public void SetFallbackFlag(bool value)
	{
		FallbackFlag = value;
	}

	public void SetCombatFlag(bool value)
	{
		CombatFlag = value;
	}

	public void SetDeployFlag(bool value)
	{
		SuccessfulDeploy = value;
	}

	public void SetMatchVelocityFlag(bool value)
	{
		MatchVelocityFlag = value;
	}

	public void SetShieldFlag(bool value)
	{
		ShieldFlag = value;
	}

	public void SetApproxInfluence(float value)
	{
		ApproxInfluence = value;
	}

	public void SetPosture(Strategy value)
	{
		Posture = value;
	}

	public void SetAllWeapons(Godot.Collections.Array all_weapons)
	{
		foreach (Node2D weapon in all_weapons)
		{
			AllWeapons.Add(weapon);
		}
	}

	public void SetTargetedUnits(List<RigidBody2D> targeted_units)
	{
		TargetedUnits.Clear();
		foreach (RigidBody2D target in targeted_units)
		{
			if (target == null) continue;
			TargetedUnits.Add(target);
		}
	}

	public void SetTargetedBy(Godot.Collections.Array<RigidBody2D> attackers)
	{
		TargetedBy.Clear();
		foreach(RigidBody2D n_attacker in attackers)
		{
			if (n_attacker == null) continue;
			TargetedBy.Add(n_attacker);
		}
	}

	public void SetNeighborUnits(Godot.Collections.Array<RigidBody2D> neighbors)
	{
		NeighborUnits = neighbors;
	}

	public void SetSeparationNeighbors(Godot.Collections.Array<RigidBody2D> neighbors)
	{
		SeparationNeighbors = neighbors;
	}

	public void SetTotalFlux(float value)
	{
		TotalFlux = value;
	}

	public void SetSoftFlux(float value)
	{
		SoftFlux = value;
	}

	public void SetHardFlux(float value)
	{
		HardFlux = value;
	}

	public void SetHullIntegrity(float value)
	{
		HullIntegrity = value;
	}

	public void SetArmor(float value)
	{
		Armor = value;
	}


	public void SetImapCell(Vector2I cell)
	{
		ImapCell = cell;
	}

	public void SetRegistryCell(Vector2I cell)
	{
		RegistryCell = cell;
	}

	public void SetRegistryNeighborhood(Godot.Collections.Array<Vector2I> neighborhood)
	{
		int size = neighborhood.Count;
		RegistryNeighborhood = new Vector2I[size];
		int idx = 0;
		foreach (Vector2I cell in neighborhood)
		{
			RegistryNeighborhood[idx] = cell;
		}
	}

	public void SetDefaultCellSize(float size)
	{
		DefaultCellSize = size;
	}

	public void SetMaxCellSize(float size)
	{
		MaxCellSize = size;
	}

	public void SetAvgWeaponRange(float avg)
	{
		AverageWeaponRange = avg;
	}

	public void SetTargetUnit(RigidBody2D target)
	{
		TargetUnit = target;
	}
}
