using Godot;
using InfluenceMap;
using Globals;
using System;
using System.Collections.Generic;
using System.Numerics;

public partial class Admiral : Node2D
{
	BehaviorTreeRoot AdmiralAI;
	public Strategy HeuristicStrategy;

	public Goal HeuristicGoal { get; private set; }
	public float PlayerStrength { get; set; } = 0.0f;
	public float AdmiralStrength { get; set; } = 0.0f;
	public int NumDeployedUnits { get; private set; } = 0;
	public int GoalRadius = 0;

	public List<Vector2I> UnitClusters; // RegistryMap cell
	public List<Vector2I> PlayerClusters; // RegistryMap cell
	public List<Vector2I> VulnerableCells;
	public List<Vector2I> IsolatedCells;
	public List<Vector2I> ControlPoints;
	[Export]
	public Godot.Collections.Dictionary<Vector2I, float> PlayerVulnerability = new Godot.Collections.Dictionary<Vector2I, float>();
	public Dictionary<Vector2I, float> GoalValue;

	public StringName GroupKeyPrefix = new StringName("Enemy Group ");
	public StringName AssignNewLeaderGroup = new StringName("");
	public int Iterator = 0;

	public List<string> AvailableGroups = new List<string>();
	public List<string> AwaitingOrders = new List<string>();

	private int n_units_deployed = 0;

    public override void _Ready()
    {
        AdmiralAI = (BehaviorTreeRoot)GetNode("AdmiralAI");
		AdmiralAI.ToggleRoot(false);
    }

	public void SetGoal(int value)
	{
		Dictionary<int, Goal> MapGoal = new Dictionary<int, Goal>();
		MapGoal[0] = Goal.SKIRMISH;
		MapGoal[1] = Goal.MOTHERSHIP;
		MapGoal[2] = Goal.CONTROL;
		HeuristicGoal = MapGoal[value];
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
			GD.Print("enemy units deployed");
			GetTree().CallGroup("stringbean", "set_deploy_flag", true);
			GetTree().CallGroup("stringbean", "group_remove", "stringbean");
			if (AdmiralAI.enabled == false)
			{
				AdmiralAI.ToggleRoot(true);
			}
		}
	}
}
