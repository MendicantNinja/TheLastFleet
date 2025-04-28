using Godot;
using Globals;
using InfluenceMap;
using System;
using System.Collections.Generic;
using Vector2 = System.Numerics.Vector2;

public partial class ShipWrapper : Node
{
	[Export]
	public string GroupName { get; private set; }
	[Export]
	public bool GroupLeader { get; private set; }
	[Export]
	public bool IsFriendly { get; private set; }
	[Export]
	public bool FluxOverload { get; private set; }
	[Export]
	public bool VentFluxFlag { get; private set; }
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
	public Dictionary<ImapType, Vector2I> TemplateCellIndices { get; set; } = new Dictionary<ImapType, Vector2I>();
	public Dictionary<ImapType, Imap> TemplateMaps { get; private set; } = new Dictionary<ImapType,Imap>();
	public Imap WeighInfluence { get; set; }
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

	public void InitializeAgentImaps(ImapManager imap_manager, RigidBody2D agent, float acceleration, float bonus_acceleration, float zero_flux_bonus, float longest_weapon_range)
	{
		// Compute influence-related parameters using ShipWrapper’s properties.
		int occupancy_radius = (int)(acceleration + bonus_acceleration + zero_flux_bonus) / 60 + 1;
		int threat_radius = (int)(longest_weapon_range / imap_manager.DefaultCellSize) + 1;

		// Retrieve the proper templates from ImapManager based on agent allegiance.
		ImapTemplate occupancy_template;
		ImapTemplate threat_template;
		
		// Assume that the parent is our agent (a RigidBody2D) so we can check its collision layer.
		if (agent.CollisionLayer == 1)
		{
			occupancy_template = imap_manager.GetTemplate(ImapType.OccupancyMap, occupancy_radius);
			threat_template = imap_manager.GetTemplate(ImapType.ThreatMap, threat_radius);
		}
		else
		{
			occupancy_template = imap_manager.GetTemplate(ImapType.InverseOccupancyMap, occupancy_radius);
			threat_template = imap_manager.GetTemplate(ImapType.InverseThreatMap, threat_radius);
		}
		// Store these influence maps in the local dictionary.
		TemplateMaps[ImapType.OccupancyMap] = occupancy_template.Map;
		TemplateMaps[ImapType.ThreatMap] = threat_template.Map;

		Imap composite_influence = new Imap(threat_template.Map.Width, threat_template.Map.Height);
		Imap inverse_composite = new Imap(threat_template.Map.Width, threat_template.Map.Height);
		foreach (ImapType type in TemplateMaps.Keys)
		{
			int center = threat_radius;
			composite_influence.AddMap(TemplateMaps[type], center, center, 1.0f);
			inverse_composite.AddMap(TemplateMaps[type], center, center, -1.0f);
		}

		for (int m = 0; m < threat_template.Map.Height; m++)
		{
			for (int n = 0; n < threat_template.Map.Width; n++)
			{
				ApproxInfluence += composite_influence.MapGrid[m, n];
			}
		}

		TemplateMaps[ImapType.OccupancyMap] = composite_influence;
		if (IsFriendly == true)
		{
			TemplateMaps[ImapType.TensionMap] = composite_influence;
		}
		else
		{
			TemplateMaps[ImapType.TensionMap] = inverse_composite;
		}

		WeighInfluence = new Imap(threat_template.Map.Width, threat_template.Map.Height);
		GD.Print("Influence mapping initialized for agent: ", agent?.Name);
	}
	
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

	public void SetCombatGoal(int value)
	{
		Dictionary<int, Goal> MapGoal = new Dictionary<int, Goal>();
		MapGoal[0] = Goal.SKIRMISH;
		MapGoal[1] = Goal.MOTHERSHIP;
		MapGoal[2] = Goal.CONTROL;
		CombatGoal = MapGoal[value];
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

	public void SetTargetedUnits(Godot.Collections.Array<RigidBody2D> targeted_units)
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
