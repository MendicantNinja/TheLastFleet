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
	public Goal CombatGoal { get; private set; }
	public Strategy Posture { get; private set; }

	// Flags and states
	[Export]
	public bool IsFriendly { get; private set; }
	[Export]
	public bool FluxOverload { get; private set; }
	[Export]
	public bool VentFluxFlag { get; private set; }
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
	public bool DeployFlag { get; private set; }
	[Export]
	public bool MatchVelocityFlag { get; private set; }
	[Export]
	public bool ShieldFlag { get; private set; }
	

	// Ship hull and stats data
	public float ApproxInfluence { get; private set; }
	public float TotalFlux { get; private set; }
	public float SoftFlux { get; private set; }
	public float HardFlux { get; private set; }
	public float HullIntegrity { get; private set; }
	public float Armor { get; private set; }
	public List<Node2D> AllWeapons { get; private set; } = new List<Node2D>();
	public float AverageWeaponRange { get; private set; }

	// Combat and influence map data
	public List<RigidBody2D> TargetedUnits { get; private set; } = new List<RigidBody2D>();
	[Export]
	public RigidBody2D TargetUnit { get; set; } = null;
	public Godot.Collections.Array<RigidBody2D> NeighborUnits { get; private set; } = new Godot.Collections.Array<RigidBody2D>();
	public Godot.Collections.Array<RigidBody2D> SeparationNeighbors { get; private set; } = new Godot.Collections.Array<RigidBody2D>();
	public Vector2I ImapCell { get; private set; }
	public Dictionary<ImapType, Imap> TemplateMaps { get; private set; } = new Dictionary<ImapType,Imap>();
	public Imap WeighInfluence { get; set; }
	public Vector2I RegistryCell { get; private set; }
	public Vector2I[] RegistryCluster { get; set; }
	public Vector2I[] RegistryNeighborhood { get; private set; }
	public float DefaultCellSize { get; private set; }
	public float MaxCellSize { get; private set; }
	public List<string> AvailableNeighborGroups { get; set; }
	public List<string> NearbyEnemyGroups { get; set; }
	public List<string> NeighborGroups { get; set; }
	public List<string> NearbyAttackers { get; set; }
	public List<RigidBody2D> IdleNeighbors { get; set; }
	public List<RigidBody2D> TargetedBy { get; private set; } = new List<RigidBody2D>();

	// Signals
	[Signal]
	public delegate void DeployedEventHandler();

	public void InitializeAgentImaps(RigidBody2D agent, ImapManager imap_manager, int occupancy_radius, int threat_radius, int collision_layer)
	{
		ImapTemplate occupancy_template;
		ImapTemplate threat_template;
		
		// Assume that the parent is our agent (a RigidBody2D) so we can check its collision layer.
		if (collision_layer == 1)
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
		TemplateMaps[ImapType.InfluenceMap] = occupancy_template.Map;
		TemplateMaps[ImapType.TensionMap] = threat_template.Map;
		
		
		Imap composite_influence = new Imap(threat_template.Map.Width, threat_template.Map.Height);
		Imap inverse_composite = new Imap(threat_template.Map.Width, threat_template.Map.Height);
		foreach (ImapType type in TemplateMaps.Keys)
		{
			composite_influence.AddMap(TemplateMaps[type], threat_radius, threat_radius, 1.0f);
			inverse_composite.AddMap(TemplateMaps[type], threat_radius, threat_radius, -1.0f);
		}

		for (int m = 0; m < composite_influence.Height; m++)
		{
			for (int n = 0; n < composite_influence.Width; n++)
			{
				ApproxInfluence += composite_influence.MapGrid[m, n];
			}
		}

		agent.Set("approx_influence", ApproxInfluence);
		
		TemplateMaps[ImapType.InfluenceMap] = composite_influence;
		if (collision_layer == 1)
		{
			TemplateMaps[ImapType.TensionMap] = composite_influence;
		}
		else
		{
			TemplateMaps[ImapType.TensionMap] = inverse_composite;
		}
		
		WeighInfluence = new Imap(composite_influence.Width, composite_influence.Height);
	}

	public void WeighCompositeInfluence(Godot.Collections.Dictionary<Godot.Collections.Array<Vector2I>, float> neighborhood_density)
	{
		if (WeighInfluence != null)
		{
			ImapManager.Instance.WeightedImap.AddMap(WeighInfluence, ImapCell.X, ImapCell.Y, -1.0f);
		}

		float weight = 0.0f;
		foreach (Godot.Collections.Array<Vector2I>cluster in neighborhood_density.Keys)
		{
			if (cluster.Contains(RegistryCell))
			{
				weight = 1.0f / neighborhood_density[cluster];
				SetRegistryCluster(cluster);
			}
		}

		float redux_comp_inf = 0.0f;
		Imap agent_comp_inf = TemplateMaps[ImapType.InfluenceMap];
		for (int m = 0; m < agent_comp_inf.Height; m++)
		{
			for (int n = 0; n < agent_comp_inf.Width; n++)
			{
				WeighInfluence.MapGrid[m, n] = agent_comp_inf.MapGrid[m, n] * weight;
				redux_comp_inf += agent_comp_inf.MapGrid[m, n] * weight;
			}
		}
		//GD.Print(redux_comp_inf);
		ImapManager.Instance.WeightedImap.AddMap(WeighInfluence, ImapCell.X, ImapCell.Y, 1.0f);
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

	public void SetTargetInRange(bool value, SteerData steer_data)
	{
		if (value == false)
		{
			TargetUnit = null;
			steer_data.TargetUnit = null;
			return;
		}
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
		DeployFlag = value;
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

	public void SetPosture(int value)
	{
		Posture = (Strategy)value;
	}

	public void SetAllWeapons(Godot.Collections.Array all_weapons)
	{
		foreach (Node2D weapon in all_weapons)
		{
			AllWeapons.Add(weapon);
		}
	}

	public void SetTargetedUnits(Godot.Collections.Array<RigidBody2D> targeted_units, SteerData steer_data, RigidBody2D agent)
	{
		TargetedUnits.Clear();
		if (targeted_units.Count == 0 && TargetUnit is not null) 
		{
			Godot.Collections.Array<RigidBody2D> target_whatever = (Godot.Collections.Array<RigidBody2D>)TargetUnit.Get("targeted_by");
			target_whatever.Remove(agent);
			TargetUnit.Set("targeted_by", target_whatever);
			agent.Call("set_target_unit", 0);
			return;
		}
		else if (targeted_units.Count == 0) return;

		foreach (RigidBody2D target in targeted_units)
		{
			if (!IsInstanceValid(target) || target is null) continue;
			TargetedUnits.Add(target);
		}
		
		if (!TargetedUnits.Contains(TargetUnit))
		{
			TargetUnit = null;
			steer_data.TargetUnit = null;
		}
	}

	public void SetTargetedBy(Godot.Collections.Array<RigidBody2D> attackers)
	{
		TargetedBy.Clear();
		if (attackers.Count == 0) return;
		
		foreach(RigidBody2D n_attacker in attackers)
		{
			if (!IsInstanceValid(n_attacker)) continue;
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

	public void SetRegistryCluster(Godot.Collections.Array<Vector2I> cluster)
	{
		int size = cluster.Count;
		RegistryCluster = new Vector2I[size];
		int idx = 0;
		foreach (Vector2I cell in cluster)
		{
			RegistryCluster[idx] = cell;
		}
	}

	public void SetRegistryNeighborhood(Godot.Collections.Array<Vector2I> neighborhood)
	{
		int size = neighborhood.Count;
		RegistryNeighborhood = new Vector2I[size];
		int idx = 0;
		foreach (Vector2I cell in neighborhood)
		{
			RegistryNeighborhood[idx] = cell;
			idx++;
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

	public void SetTargetUnit(GodotObject target)
	{
		TargetUnit = target as RigidBody2D;
	}
}
