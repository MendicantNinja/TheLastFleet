using Godot;
using InfluenceMap;
using Globals;
using System.Collections.Generic;
using System.Linq;
using Vector2 = System.Numerics.Vector2;
using System.Numerics;

// We need to remove friendly reuse of group names for the sake of simplicity gathering sample data 
public struct GroupData
{
	public string GroupName;
	public float Strength;
	public Goal GroupGoal;
	public Vector2I ClusterCentroid;
	public Vector2 Velocity;
	public Vector2 TargetPosition;
	public RigidBody2D EliminateUnit;
	public RigidBody2D EscortUnit;
}

public struct DiscreteSample
{
	public List<GroupData> PlayerGroups;
    public List<Godot.Collections.Array<Vector2I>> PlayerClusters;
    public List<Godot.Collections.Array<Vector2I>> UnitClusters;
    public Godot.Collections.Dictionary<Vector2I, float> PlayerVulnerability;
    public Godot.Collections.Dictionary<Vector2I, float> EnemyVulnerability;
    public List<Vector2I> TensionCells;
	public float PlayerStrength;
	public float AdmiralStrength;
	public float SomeArbitraryMetric;
    public int SampleTick;

    public DiscreteSample(bool initialize)
    {
        PlayerGroups = new List<GroupData>();
        PlayerClusters = new List<Godot.Collections.Array<Vector2I>>();
        UnitClusters = new List<Godot.Collections.Array<Vector2I>>();
        PlayerVulnerability = new Godot.Collections.Dictionary<Vector2I, float>();
        EnemyVulnerability = new Godot.Collections.Dictionary<Vector2I, float>();
        TensionCells = new List<Vector2I>();
		PlayerStrength = 0f;
		AdmiralStrength = 0.0f;
        SampleTick = 0;
		SomeArbitraryMetric = 0.0f;
    }
}
// CellMerit
// A data container for assessing the significance of areas in the combat map.
// 
public struct CellMerit
{
	public int CellX, CellY;
	public float FriendlyPresence; // Sum of friendly approximate influence
	public float EnemyPresence;	// Sum of enemy approximate influence
	public float StrategicValue; // Strategic importance
	public float Weight; // Dynamic, computed per objective
}


public partial class Admiral : Node2D
{
	BehaviorTreeRoot AdmiralAI;
	Node GD_global = null;

	public Objective HeuristicObjective { get; private set; }
	public float PlayerStrength { get; set; } = 0.0f;
	public float AdmiralStrength { get; set; } = 0.0f;
	public int NumDeployedUnits { get; private set; } = 0;
	public int GoalRadius = 0;

	public List<Godot.Collections.Array<Vector2I>> UnitClusters; // RegistryMap cell
	public List<Godot.Collections.Array<Vector2I>> PlayerClusters; // RegistryMap cell
	//public Dictionary<string, Goal> PlayerGoals;
	public List<Vector2I> VulnerableCells;
	public List<Vector2I> IsolatedCells;
	public List<Vector2I> ControlPoints;

	[Export]
	public Godot.Collections.Dictionary<Vector2I, float> PlayerVulnerability = new();
	[Export]
	public Godot.Collections.Dictionary<Vector2I, float> EnemyVulnerability = new();

	// Q = Question, A = Answer, O = Observation / Analysis
	// TensionCells is a list of all grid‐cells where tension is over a threshold.
	// We can leverage these to drive both global awareness and skirmish tactics.
	//
	// -----------------------------------------------------------------------------
	// Tension Cells – General Use Cases / Observations
	// -----------------------------------------------------------------------------
	//
	// Q1. Is there combat anywhere on the map?
	//	O1. TensionCells.Count == 0, no significant contest
	// 		A1. Admiral switches to non‐combat analysis
	//	O2. TensionCells.Count > 0
	//		A2. Admiral switches to combat analysis
	//
	// Q2. Where is combat happening and how intense is it?
	//	O1. Partition TensionCells into contiguous clusters (e.g., flood‐fill).
	//		- For each cluster, compute geometric median → main engagement point.
	//		- Get rough radius to outermost cell and introduce a buffer value to retrieve more local data.
	//		- Sum tension values in the cluster → engagement intensity metric.
	//		- Compare aggregated vulnerability for player vs. enemy in this zone.
	//
	// -----------------------------------------------------------------------------
	// Tension Cells – Skirmish (Objective‐Driven) Use Cases
	// -----------------------------------------------------------------------------
	//	Assume combat...
	//	Q2 → O1.
	//		O2. If player_vuln > enemy_vuln and desperation low
	//			A1. Opportunity to direct units here to attack via Move and Hold, Probe, etc.
	//		O3. If player_vuln < enemy_vuln and desperation high
	//			A2. Fallback, Reinforce, etc.
	//
	// -----------------------------------------------------------------------------
	// Next Steps / To‐Do:
	//
	// 1. Implement clustering of TensionCells into discrete regions as TensionClusters.
	// 2. Feed Clusters into behavior‐tree nodes as inputs to analyze (Move and Hold, Fallback, Attack, etc.).
	// 3. Tune thresholds for “significant tension” vs. noise.
	// 4. Visualize Region data in debug overlay to validate logic.
	public List<Vector2I> TensionCells = new();
	public List<DiscreteSample> RecentSamples = new();
	public int SampleBuffer = 7;
	public double SampleCounter = 0;
	public int CurrentSampleTick = 0;
	public int sample_limit = 4;

	float SomeArbitraryMetric = 0.0f;

	public List<string> AvailableGroups = new();

	private int n_units_deployed = 0;

    public override void _Ready()
    {
        AdmiralAI = (BehaviorTreeRoot)GetNode("AdmiralAI");
		AdmiralAI.ToggleRoot(false);
    }

    public override void _PhysicsProcess(double delta)
    {
		if (GD_global is null)
		{
			GD_global = GetTree().Root.GetNode("globals");
		}

		// Moving this out of ChooseStrategy
		// Not going to throw this away until I know it is absolutely useless
		/*
		if (Engine.GetPhysicsFrames() % 240 == 0)
		{
			PollStrength();
		}
		*/

		// Everything after this should only ever happen when enemy units are fully deployed
		// i.e. when the AdmiralAI is enabled
		if (AdmiralAI.enabled == false) return;

		/*
		if (Engine.GetPhysicsFrames() % 240 == 0)
		{
			PlayerVulnerability = NormalizeSampleCells(PlayerVulnerability);
			EnemyVulnerability = NormalizeSampleCells(EnemyVulnerability);
		}
		*/
		if (SampleCounter > SampleBuffer - 3)
		{
			UpdateMaps();
		}

		if (SampleCounter > SampleBuffer - 1)
		{
			PollStrength();
			PlayerVulnerability = NormalizeSampleCells(PlayerVulnerability);
            EnemyVulnerability = NormalizeSampleCells(EnemyVulnerability);
		}

		SampleCounter += delta;
		if (SampleCounter > SampleBuffer)
		{
			SampleCounter = 0.0;
			CurrentSampleTick++;

            DiscreteSample CurrentSample = new(true)
            {
                SampleTick = CurrentSampleTick,
                PlayerClusters = ImapManager.Instance.FriendlyClusters,
                UnitClusters = ImapManager.Instance.EnemyClusters,
                PlayerVulnerability = PlayerVulnerability,
                EnemyVulnerability = EnemyVulnerability,
                TensionCells = TensionCells,
				PlayerStrength = PlayerStrength,
				AdmiralStrength = AdmiralStrength,
            };

            CurrentSample = PollGroups(CurrentSample);
			RecentSamples.Add(CurrentSample);
		}

		if (RecentSamples.Count > sample_limit)
		{
			RecentSamples.RemoveAt(0);
		}
    }

	public void UpdateMaps()
	{
		Imap weighted_imap = ImapManager.Instance.WeightedImap;
		Imap influence_map = ImapManager.Instance.AgentMaps[ImapType.InfluenceMap];
		Imap inverse_tension_map = ImapManager.Instance.AgentMaps[ImapType.TensionMap];
		Imap tension_map = ImapManager.Instance.TensionMap;
		Imap vulnerability_map = ImapManager.Instance.VulnerabilityMap;
		Imap goal_map = ImapManager.Instance.GoalMap;

		float lambda = -0.16f;
		Godot.Collections.Dictionary<Vector2I, float> player_vulnerability = new();
		Godot.Collections.Dictionary<Vector2I, float> enemy_vulnerability = new();
		List<Vector2I> tension_cells = new();
		for (int m = 0; m < vulnerability_map.Height; m++)
		{
			for (int n = 0; n < vulnerability_map.Width; n++)
			{
				float imap_value = influence_map.MapGrid[m, n];
				float weighted_imap_value = weighted_imap.MapGrid[m, n];
				float tension_value = 0.0f;
				float vuln_value = 0.0f;
				float decay_goal_value = goal_map.MapGrid[m, n] * Mathf.Exp(lambda);
				if (goal_map.MapGrid[m, n] > 0.0f && decay_goal_value < 0.1f)
				{
					goal_map.MapGrid[m, n] = 0.0f;
				}
				else if (goal_map.MapGrid[m, n] < 0.0f && decay_goal_value > -0.1f)
				{
					goal_map.MapGrid[m, n] = 0.0f;
				}
				else
				{
					goal_map.MapGrid[m, n] = decay_goal_value;
				}

				if (inverse_tension_map.MapGrid[m, n] == 0.0f && imap_value == 0.0f)
				{
					tension_map.MapGrid[m, n] = tension_value;
					vulnerability_map.MapGrid[m, n] = vuln_value;
					vulnerability_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, vuln_value);
					weighted_imap.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, weighted_imap_value);
					tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, tension_value);
					inverse_tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, inverse_tension_map.MapGrid[m, n]);
					continue;
				}

				tension_value = Mathf.Max(0.0f, inverse_tension_map.MapGrid[m, n] - Mathf.Abs(imap_value));
				vuln_value = tension_value - Mathf.Abs(weighted_imap_value);
				tension_map.MapGrid[m, n] = tension_value;
				vulnerability_map.MapGrid[m, n] = vuln_value;
				if (imap_value > 0.0f)
				{
					player_vulnerability[new Vector2I(m, n)] = vuln_value;
				}
				else if (imap_value < 0.0f)
				{
					enemy_vulnerability[new Vector2I(m, n)]  = vuln_value;
				}
				
				
				if (tension_value > 0.1f)
				{
					tension_cells.Add(new Vector2I(m, n));
				}
				
				vulnerability_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, vuln_value);
				weighted_imap.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, weighted_imap_value);
				tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, tension_value);
				inverse_tension_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, inverse_tension_map.MapGrid[m,n]);
			}
		}

		PlayerVulnerability = player_vulnerability;
		EnemyVulnerability = enemy_vulnerability;
		TensionCells = tension_cells;
	}

	public static Godot.Collections.Dictionary<Vector2I, float> NormalizeSampleCells(Godot.Collections.Dictionary<Vector2I, float> sample_cells)
	{
		float min_value = sample_cells.Values.Min();
		float max_value = sample_cells.Values.Max();
		Godot.Collections.Dictionary<Vector2I, float> normalized_cells = new(); 
		foreach (Vector2I cell in sample_cells.Keys)
		{
			float value = sample_cells[cell];
			float norm_value = 2.0f * ((value - min_value) / (max_value - min_value)) - 1.0f;
			normalized_cells[cell] = norm_value;
		}

		Godot.Collections.Dictionary<Vector2I, float> target_cells = new();
		float norm_max = normalized_cells.Values.Max();
		float norm_min = normalized_cells.Values.Min();
		foreach (Vector2I cell in sample_cells.Keys)
		{
			if (target_cells[cell] == norm_max || target_cells[cell] == norm_min)
			{
				target_cells[cell] = normalized_cells[cell];
			}
        }

        return target_cells;
	}

	
	public DiscreteSample PollGroups(DiscreteSample n_sample)
	{
		List<string> passed_groups = new();
		Godot.Collections.Array<Node> agents = GetTree().GetNodesInGroup("friendly");
		foreach (RigidBody2D n_agent in agents.Cast<RigidBody2D>())
		{
			string group_name = (string)n_agent.Get("group_name");
			if (passed_groups.Contains(group_name)) continue;

			passed_groups.Add(group_name);
			Godot.Collections.Array<Node> group = GetTree().GetNodesInGroup(group_name);
			GroupData CurrentGroupData;
			CurrentGroupData.GroupName = group_name;
			ShipWrapper first_member_wrapper = (ShipWrapper)group[0].Get("ShipWrapper");
			CurrentGroupData.GroupGoal = first_member_wrapper.CombatGoal;

			Godot.Collections.Array<Godot.Vector2> unit_positions = new();
			Vector2 average_velocity = Vector2.Zero;
			float group_strength = 0.0f;
			foreach (RigidBody2D unit in group.Cast<RigidBody2D>())
			{
				unit_positions.Add(unit.GlobalPosition);
				float unit_strength = (float)unit.Get("approx_influence");
				group_strength += unit_strength;
				
				average_velocity += new Vector2(unit.LinearVelocity.X, unit.LinearVelocity.Y);
			}
			CurrentGroupData.Strength = group_strength;
			Godot.Vector2 geo_med = (Godot.Vector2)GD_global.Call("geometric_median_of_objects", unit_positions);
			Vector2I geo_med_cell = new((int)geo_med.Y / ImapManager.Instance.MaxCellSize, (int)geo_med.X / ImapManager.Instance.MaxCellSize);
			CurrentGroupData.ClusterCentroid = geo_med_cell;
			
			CurrentGroupData.Velocity = average_velocity / group.Count;
			
			if (CurrentGroupData.GroupGoal == Goal.MOVE_HOLD)
			{
				CurrentGroupData.EscortUnit = null;
				CurrentGroupData.EliminateUnit = null;
				CurrentGroupData.TargetPosition = first_member_wrapper.HoldCenter;
			}
			else if (CurrentGroupData.GroupGoal == Goal.ESCORT)
			{
				SteerData escort_unit_data = (SteerData)first_member_wrapper.EscortUnit.Get("SteerData");
				CurrentGroupData.EliminateUnit = null;
				CurrentGroupData.EscortUnit = first_member_wrapper.EscortUnit;
				CurrentGroupData.TargetPosition = escort_unit_data.TargetPosition;
			}
			else if (CurrentGroupData.GroupGoal == Goal.ELIMINATE)
			{
				CurrentGroupData.EliminateUnit = first_member_wrapper.TargetUnit;
				CurrentGroupData.EscortUnit = null;
				CurrentGroupData.TargetPosition = Vector2.Zero;
			}
			else
			{
				CurrentGroupData.EliminateUnit = null;
				CurrentGroupData.EscortUnit = null;
				CurrentGroupData.TargetPosition = Vector2.Zero;
			}
			n_sample.PlayerGroups.Add(CurrentGroupData);
		}

		return n_sample;
	}

	public void PollStrength()
	{
		Godot.Collections.Array<Node> available_agents = GetTree().GetNodesInGroup("agent");
		foreach (RigidBody2D unit in available_agents.Cast<RigidBody2D>())
		{
			if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion()) continue;

			float influence = (float)unit.Get("approx_influence");

			if (influence < 0.0f)
			{
				AdmiralStrength += influence;
			}
			else 
			{
				PlayerStrength += influence;
			}
		}
	}

	public void SetObjective(int value)
	{
        HeuristicObjective = value switch
        {
            0 => Objective.SKIRMISH,
            1 => Objective.MOTHERSHIP,
            2 => Objective.CONTROL,
            _ => Objective.SKIRMISH,
        };
    }

	public void SetNumDeployedUnits(int n_units)
	{
		NumDeployedUnits = n_units;
	}

	public void OnUnitDeployed()
	{
		n_units_deployed++;
		if (n_units_deployed == NumDeployedUnits)
		{
			//GD.Print("enemy units deployed");
			GetTree().CallGroup("stringbean", "set_deploy_flag", true);
			GetTree().CallGroup("stringbean", "group_remove", "stringbean");
			if (AdmiralAI.enabled == false)
			{
				AdmiralAI.ToggleRoot(true);
			}
		}
	}
}
