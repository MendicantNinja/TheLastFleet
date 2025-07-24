using Godot;
using InfluenceMap;
using Globals;
using System.Collections.Generic;
using System.Linq;
using Vector2 = System.Numerics.Vector2;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;

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
	//public float SomeArbitraryMetric;
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
		//SomeArbitraryMetric = 0.0f;
    }
}

public struct GoalDescriptor
{
    public Goal Type;           // e.g. MoveHold, Harass, Attack, etc.
    public Vector2I CenterCell;  	// propagation center
    public float BaseWeight;    // computed score before propagation
    public int Radius;        // how far the influence spreads
    //public float ExpirationTime; // timestamp or tick when this goal expires
	public int SampleTick;
	public int Index;
}

// CellMerit
// A data container for assessing the significance of areas in the combat map using
// registry cells as the abstract representation of these regions.
public struct CellMerit
{
	public Vector2I CellIndex;
	public float FriendlyPresence; // Average of friendly approx influence over total influence
	public float EnemyPresence;	// Average of enemy approx influence over total influence
	public float BaseStrategicValue; // Strategic importance (a flat 1.0 for neutral control points, an_idxthing else is assessed on different merits)
	public float ObjectiveWeight; // computed per objective
	public List<Vector2I> AdjacentCells;
	public CellMerit(bool initialize)
    {
		CellIndex.X = 0;
		CellIndex.Y = 0;
        FriendlyPresence = 0.0f;
		EnemyPresence = 0.0f;
		BaseStrategicValue = 0.0f;
		ObjectiveWeight = 0.0f;
		AdjacentCells = new();
    }
}

public partial class Admiral : Node2D
{
	BehaviorTreeRoot AdmiralAI;
	Node GD_global = null;

	public Objective HeuristicObjective { get; private set; }
	public float PlayerStrength { get; set; } = 0.0f;
	public float AdmiralStrength { get; set; } = 0.0f;
	public int NumDeployedUnits { get; private set; } = 0;
	public bool BattleOver {get; private set; } = true;
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

	public List<Vector2I> TensionCells = new();
	public List<DiscreteSample> RecentSamples = new();
	public Dictionary<Vector2I, CellMerit> RegistryCellsMerit = new();
	public List<GoalDescriptor> CurrentGoalEvaluation = new();
	public List<GoalDescriptor> GoalHistory = new();
	public ulong SampleBuffer = 15;
	public int CurrentSampleTick = 0;
	public int sample_limit = 4;

	//float SomeArbitraryMetric = 0.0f;

	private int n_units_deployed = 0;

    public override void _Ready()
    {
        AdmiralAI = (BehaviorTreeRoot)GetNode("AdmiralAI");
		AdmiralAI.ToggleRoot(false);

		//List<CellMerit> polled_cells = new();
		int columns = ImapManager.Instance.ArenaWidth / ImapManager.Instance.MaxCellSize;
		int rows = ImapManager.Instance.ArenaHeight / ImapManager.Instance.MaxCellSize;
		for (int m = 0; m < rows; m++)
		{
			for (int n = 0; n < columns; n++)
			{
                CellMerit cell = new(true){};
				cell.CellIndex.X = m;
				cell.CellIndex.Y = n;
				RegistryCellsMerit[cell.CellIndex] = cell;
			}
			
		}

		// assume: rows = # of rows, columns = # of columns
		foreach (Vector2I cell_idx in RegistryCellsMerit.Keys)
		{
			var cell = RegistryCellsMerit[cell_idx];

			// offset loops [-1..+1]
			for (int m = -1; m <= 1; m++)
			{
				int m_idx = cell.CellIndex.X + m;
				if (m_idx < 0 || m_idx >= rows) continue;

				for (int n = -1; n <= 1; n++)
				{
					int n_idx = cell.CellIndex.Y + n;
					if (n_idx < 0 || n_idx >= columns) continue;

					// skip the cell itself
					if (m == 0 && n == 0) continue;

					cell.AdjacentCells.Add(new Vector2I(m_idx, n_idx));
				}
			}

			RegistryCellsMerit[cell.CellIndex] = cell;
		}

		//RegistryCellsMerit = polled_cells;
    }

    public override void _PhysicsProcess(double delta)
    {
		if (GD_global is null)
		{
			GD_global = GetTree().Root.GetNode("globals");
		}

		// Everything after this should only ever happen when enemy units are fully deployed
		// i.e. when the AdmiralAI is enabled
		if (AdmiralAI.enabled == false || BattleOver == true) return;

		if (Engine.GetPhysicsFrames() % (30 * SampleBuffer) == 0)
		{
			UpdateMaps();
		}

		if (Engine.GetPhysicsFrames() % (60 * (SampleBuffer - 5)) == 0)
		{
			PlayerVulnerability = NormalizeSampleCells(PlayerVulnerability);
            EnemyVulnerability = NormalizeSampleCells(EnemyVulnerability);
		}

		if (Engine.GetPhysicsFrames() % (60 * (SampleBuffer - 2)) == 0)
		{
			PollRegistryCells();
		}
	
		if (Engine.GetPhysicsFrames() % (60 * SampleBuffer) == 0)
		{
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
			PollStrength();
		}
    }

	public void UpdateMaps()
	{
		Imap weighted_imap = ImapManager.Instance.WeightedImap;
		Imap influence_map = ImapManager.Instance.AgentMaps[ImapType.InfluenceMap];
		Imap inverse_tension_map = ImapManager.Instance.AgentMaps[ImapType.TensionMap];
		Imap tension_map = ImapManager.Instance.TensionMap;
		Imap vulnerability_map = ImapManager.Instance.VulnerabilityMap;
		//Imap goal_map = ImapManager.Instance.GoalMap;

		//float lambda = -0.16f;
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
				/*
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
				*/

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
		if (sample_cells.Count == 0) return sample_cells;
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
			if (normalized_cells[cell] == norm_max || normalized_cells[cell] == norm_min)
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

	public void PollRegistryCells()
	{
		foreach (Vector2I cell_index in RegistryCellsMerit.Keys)
		{
			ref CellMerit cell = ref CollectionsMarshal.GetValueRefOrNullRef(RegistryCellsMerit, cell_index);
			if (Unsafe.IsNullRef(ref cell)) continue;
			
			float enemy_influence = 0.0f;
			float player_influence = 0.0f;
			if (ImapManager.Instance.RegistryMap.ContainsKey(cell.CellIndex))
			{
				List<RigidBody2D> registered_units = ImapManager.Instance.RegistryMap[cell.CellIndex];
				foreach (RigidBody2D unit in registered_units)
				{
					float approx_influence = (float)unit.Get("approx_influence");

					if (approx_influence < 0.0f) enemy_influence += Mathf.Abs(approx_influence);
					else if (approx_influence > 0.0f) player_influence += approx_influence;
				}
			}
			cell.BaseStrategicValue = 0.0f;
			cell.ObjectiveWeight = 0.0f;
			if (enemy_influence < 0.0f && player_influence == 0 && HeuristicObjective == Objective.SKIRMISH)
			{
				cell.BaseStrategicValue = 1.0f;
			}
			else if (enemy_influence == 0.0f && player_influence > 0 && HeuristicObjective == Objective.SKIRMISH)
			{
				cell.BaseStrategicValue = -1.0f;
			}
			// if cell index contains a neutral control point, change its base strategic value to 1.0f
			/*
			else if (HeuristicObjective == Objective.CONTROL)
			{
			}
			*/
			float total_influence = enemy_influence + player_influence;
			if (total_influence == 0.0f)
			{
				cell.EnemyPresence = 0.0f;
				cell.FriendlyPresence = 0.0f;
			}
			else
			{
				cell.EnemyPresence = enemy_influence / total_influence;
				cell.FriendlyPresence = player_influence / total_influence;
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

	public void SetBattleOver(bool value)
	{
		BattleOver = value;
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
