using Godot;
using InfluenceMap;
using Globals;
using System;
using System.Collections.Generic;
using System.Numerics;

public partial class Admiral : Node2D
{
    public Strategy HeuristicStrategy;
    public Goal HeuristicGoal;


    public float PlayerStrength = 0.0f;
    public float AdmiralStrength = 0.0f;
    public int GoalRadius = 0;

    public List<Vector2I> UnitClusters; // RegistryMap cell
    public List<Vector2I> PlayerClusters; // RegistryMap cell
    public List<Vector2I> VulnerableCells;
    public List<Vector2I> IsolatedCells;
    public Dictionary<Vector2I, float> PlayerVulnerability;
    public Dictionary<Vector2I, float> GoalValue;

	public StringName GroupKeyPrefix = new StringName("Enemy Group ");
	public StringName AssignNewLeaderGroup = new StringName("");
	public int Iterator = 0;

    public List<string> AvailableGroups;
    public List<string> AwaitingOrders;
}
