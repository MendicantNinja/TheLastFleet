using Godot;
using System;
using InfluenceMap;
using System.Collections.Generic;
using System.Security.Cryptography.X509Certificates;
using Vector2 = System.Numerics.Vector2;
using Globals;

public partial class FillGoalMap : Action
{
	int current_tick = 0;
	public override NodeState Tick(Node agent)
	{
		Admiral admiral = agent as Admiral;
		if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.FAILURE;
		current_tick = admiral.CurrentSampleTick;

		
		Imap goal_map = ImapManager.Instance.GoalMap;
		goal_map.ClearMap();
		foreach (GoalDescriptor goal in admiral.CurrentGoalEvaluation)
		{
			GD.Print(goal.Type);
			GD.Print(goal.CenterCell);
			GD.Print(goal.BaseWeight);
			goal_map = PropagateGoalValues(goal_map, goal.Radius, goal.CenterCell, goal.Type, goal.BaseWeight);
		}
		
		ImapManager.Instance.GoalMap = goal_map;
		admiral.CurrentGoalEvaluation.Clear();
		return NodeState.SUCCESS;
	}

	public static Imap PropagateGoalValues(Imap goal_map, int radius, Vector2I center, Goal type, float magnitude = 1.0f)
	{
		int start_col = Math.Max(0, center.Y - radius);
		int end_col = Math.Min(center.Y + radius, goal_map.Width);
		int start_row = Math.Max(0, center.X - radius);
		int end_row = Math.Min(center.X + radius, goal_map.Height);
		//float norm_mag = magnitude / norm_val;

		for (int m = start_row; m < end_row; m++)
		{
			for (int n = start_col; n < end_col; n++)
			{
				float distance = center.DistanceTo(new Vector2I(m, n));
				float value = magnitude - magnitude * (distance / radius);
				if (value < 0.0) value = 0.0f;
				/*
				if (goal_map.MapGrid[m, n] != 0.0f)
				{
					value = goal_map.MapGrid[m, n];
				}
				value += magnitude - magnitude * (distance / radius);
				*/
				goal_map.GoalGrid[m, n] = type;
				if (value == 0.0) goal_map.GoalGrid[m, n] = Goal.DEFAULT;

				goal_map.MapGrid[m, n] = value;
				goal_map.EmitSignal(Imap.SignalName.UpdateGridValue, m, n, value, (int)type);
			}
		}

		return goal_map;
	}
}