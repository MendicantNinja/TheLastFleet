using Godot;
using InfluenceMap;
using System;
using System.Collections.Generic;

public partial class FindGoal : Action
{   const int radius = 30;
	Imap working_map = null;
    public override NodeState Tick(Node agent)
    {
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
        if (ship_wrapper.IsFriendly == true || ship_wrapper.RetreatFlag == true) return NodeState.SUCCESS;
        
        if (Engine.GetPhysicsFrames() % 720 == 0 || ship_wrapper.DeployFlag == false || ship_wrapper.GroupLeader == false) return NodeState.SUCCESS;

        if (ship_wrapper.CombatGoal == Globals.Goal.SKIRMISH && ship_wrapper.GoalFlag == true && ship_wrapper.TargetedUnits.Count == 0)
        {
            GetTree().CallGroup(ship_wrapper.GroupName, "set_goal_flag", false);
        }

        if (ship_wrapper.GoalFlag == true) return NodeState.SUCCESS;

        if (working_map == null)
		{
			working_map = new Imap(radius, radius);
		}

		ImapManager.Instance.GoalMap.AddIntoMap(working_map, ship_wrapper.ImapCell.X, ship_wrapper.ImapCell.Y);
		Dictionary<float, Vector2I> local_maximum = new Dictionary<float, Vector2I>();
		int rows = working_map.Height;
		int cols = working_map.Width;
		for (int m = 0; m < rows; m++)
{
			float maxVal = 0.0f;
			int n = -1;

			for (int i = 0; i < cols; i++)
			{
				float val = working_map.MapGrid[m, i];
				if (val > maxVal)
				{
					maxVal = val;
					n = i;
				}
			}

			if (maxVal <= 0.0f || n == -1)
				continue;

			Vector2I cell = new Vector2I(ship_wrapper.ImapCell.Y + m, ship_wrapper.ImapCell.X + n);
			local_maximum[maxVal] = cell;
		}

		if (local_maximum.Count == 0) return NodeState.FAILURE;

		float highest_value = 0.0f;
		foreach (float key in local_maximum.Keys)
		{
			if (key > highest_value) highest_value = key;
		}

		Vector2I cell_max = local_maximum[highest_value];
		Vector2 target_position = new Vector2(
			cell_max.Y * ImapManager.Instance.DefaultCellSize,
			cell_max.X * ImapManager.Instance.DefaultCellSize
		);

		agent.Call("set_navigation_position", target_position);
        return NodeState.FAILURE;
    }

}
