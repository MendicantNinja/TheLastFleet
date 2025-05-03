using Godot;
using InfluenceMap;
using Globals;
using System;
using System.Collections.Generic;
using System.Numerics;

public partial class Admiral : Node2D
{
	public Strategy HeuristicStrategy;
	public Goal HeuristicGoal { get; private set; }


	public float PlayerStrength { get; set; } = 0.0f;
	public float AdmiralStrength { get; set; } = 0.0f;
	public int GoalRadius = 0;

	public List<Vector2I> UnitClusters; // RegistryMap cell
	public List<Vector2I> PlayerClusters; // RegistryMap cell
	public List<Vector2I> VulnerableCells;
	public List<Vector2I> IsolatedCells;
	public List<Vector2I> ControlPoints;
	[Export]
	public Godot.Collections.Dictionary<Vector2I, float> PlayerVulnerability;
	public Dictionary<Vector2I, float> GoalValue;

	public StringName GroupKeyPrefix = new StringName("Enemy Group ");
	public StringName AssignNewLeaderGroup = new StringName("");
	public int Iterator = 0;

	public List<string> AvailableGroups = new List<string>();
	public List<string> AwaitingOrders = new List<string>();

	public void SetGoal(int value)
	{
		Dictionary<int, Goal> MapGoal = new Dictionary<int, Goal>();
		MapGoal[0] = Goal.SKIRMISH;
		MapGoal[1] = Goal.MOTHERSHIP;
		MapGoal[2] = Goal.CONTROL;
		HeuristicGoal = MapGoal[value];
	}
}
