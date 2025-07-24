using Globals;
using Godot;
using System;
using System.Collections.Generic;
using Vector2 = System.Numerics.Vector2;

public partial class FindGoals : Action
{
    bool is_friendly = false;
    public override NodeState Tick(Node agent)
    {
        if (is_friendly == true || Engine.GetPhysicsFrames() % 120 != 0) return NodeState.SUCCESS;

        ShipWrapper ship_wrapper = (ShipWrapper) agent.Get("ShipWrapper");
        
        if (is_friendly != ship_wrapper.IsFriendly) is_friendly = ship_wrapper.IsFriendly;

        if (ship_wrapper.DeployFlag == false) return NodeState.SUCCESS;
        
        SteerData steer_data = (SteerData) agent.Get("SteerData");
        ImapManager.Instance.GoalMap.AddIntoMap(ship_wrapper.GoalSample, ship_wrapper.ImapCell.X, ship_wrapper.ImapCell.Y);

        List<float> local_maximum_val = new();
        List<Vector2I> local_maximum_idx = new();
        for (int m = 0; m < ship_wrapper.GoalSample.Width; m++)
        {
            float rel_max_val = float.MinValue;
            int col = 0;
            for (int n = 0; n < ship_wrapper.GoalSample.Height; n++)
            {
                float val = ship_wrapper.GoalSample.MapGrid[m, n];
                if (val > rel_max_val)
                {
                    rel_max_val = val;
                    col = n;
                }
            }
            local_maximum_idx.Add(new Vector2I(m, col));
            local_maximum_val.Add(rel_max_val);
        }

        Godot.Vector2I max_cell = new(0, 0);
        float max_val = float.MinValue;
        for (int i = 0; i < local_maximum_idx.Count; i++)
        {
            if (local_maximum_val[i] > max_val)
            {
                max_val = local_maximum_val[i];
                max_cell = local_maximum_idx[i];
            }
        }

        Goal found_goal = ship_wrapper.GoalSample.GoalGrid[max_cell.X, max_cell.Y];
        Vector2 goal_pos = new(ship_wrapper.ImapCell.Y * ImapManager.Instance.DefaultCellSize, ship_wrapper.ImapCell.X * ImapManager.Instance.DefaultCellSize);
        Vector2I global_goal_cell = new(ship_wrapper.ImapCell.X + (int)max_cell.X / 2, ship_wrapper.ImapCell.Y + (int)max_cell.Y / 2);
        goal_pos.X = global_goal_cell.Y * ImapManager.Instance.DefaultCellSize;
        goal_pos.Y = global_goal_cell.X * ImapManager.Instance.DefaultCellSize;
        //Godot.Vector2 direction_to = center_cell.DirectionTo(max_cell);

        if (ship_wrapper.CombatGoal != found_goal)
        {
            agent.Set("combat_goal", (int)found_goal);
        }
        
        steer_data.TargetPosition = goal_pos;

        return NodeState.SUCCESS;
    }
}
