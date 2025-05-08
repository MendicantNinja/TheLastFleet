using Godot;
using System;
using InfluenceMap;
using System.Collections.Generic;
using System.Security.Cryptography.X509Certificates;
using Vector2 = System.Numerics.Vector2;

public partial class FillGoalMap : Action
{
	public override NodeState Tick(Node agent)
	{
		Admiral admiral = agent as Admiral;
		if (Engine.GetPhysicsFrames() % 720 != 0 | admiral.GoalValue == null) return NodeState.FAILURE;

		if (admiral.AvailableGroups.Count == 0) 
		{
			return NodeState.FAILURE;
		}
		
		Imap goal_map = ImapManager.Instance.GoalMap;
		Dictionary<Vector2I, float> goal_value = admiral.GoalValue;
		
		float norm_val = 0.0f;
		foreach (Vector2I cell in goal_value.Keys)
		{
			if (goal_value[cell] < 0.0f) continue;
			norm_val += 1.0f;
		}
		
		if (admiral.IsolatedCells.Count == 0) norm_val = goal_value.Keys.Count;

		if (norm_val == 0.0f) return NodeState.FAILURE;

		goal_map.ClearMap();
		List<Vector2I> geo_mean_cell = new List<Vector2I>();
		Node globals = GetTree().Root.GetNode("globals");
		foreach (string group_name in admiral.AvailableGroups)
		{
			Godot.Collections.Array<Node> group = GetTree().GetNodesInGroup(group_name);
			Godot.Collections.Array<Godot.Vector2> positions = new Godot.Collections.Array<Godot.Vector2>();
			foreach (RigidBody2D unit in group)
			{
				positions.Add(new Godot.Vector2(unit.GlobalPosition.X, unit.GlobalPosition.Y));
			}
			Godot.Vector2 geo_median = (Godot.Vector2)globals.Call("geometric_median_of_objects", positions);
			Vector2I cell = new Vector2I((int)geo_median.Y / ImapManager.Instance.DefaultCellSize, (int)geo_median.X / ImapManager.Instance.DefaultCellSize);
			geo_mean_cell.Add(cell);
		}

		foreach (Vector2I goal_cell in goal_value.Keys)
		{
			Godot.Collections.Array<Vector2I> dist_to_goal_cell = new Godot.Collections.Array<Vector2I>();
			List<Vector2I> geo_mean_dist = new List<Vector2I>();
			float max_dist = 0.0f;
			int max_idx = 0;
			int idx = 0;
			foreach (Vector2I cell in geo_mean_cell)
			{
				float dist = cell.DistanceSquaredTo(goal_cell);
				if (dist > max_dist)
				{
					max_dist = dist;
					max_idx = idx;
				}
				idx++;
			}
			
			Vector2I max_cell = geo_mean_cell[max_idx];
			int radius = (int)max_cell.DistanceTo(goal_cell);
			goal_map = PropagateGoalValues(goal_map, radius, goal_cell, goal_value[goal_cell], norm_val);
		}

		ImapManager.Instance.GoalMap = goal_map;
		return NodeState.FAILURE;
	}

	public Imap PropagateGoalValues(Imap goal_map, int radius, Vector2I center, float magnitude = 1.0f, float norm_val = 1.0f)
	{
		int start_col = Math.Max(0, center.Y - radius);
		int end_col = Math.Min(center.Y + radius, goal_map.Width);
		int start_row = Math.Max(0, center.X - radius);
		int end_row = Math.Min(center.X + radius, goal_map.Height);
		float norm_mag = magnitude / norm_val;

		for (int m = start_row; m < end_row; m++)
		{
			for (int n = start_col; n < end_col; n++)
			{
				float distance = center.DistanceTo(new Vector2I(m, n));
				float value = 0.0f;
				if (goal_map.MapGrid[m, n] != 0.0f)
				{
					value = goal_map.MapGrid[m, n];
				}
				value += magnitude - norm_mag * (distance / radius);
				goal_map.MapGrid[m, n] = value;
				goal_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, value);
			}
		}
		
		return goal_map;
	}

}
