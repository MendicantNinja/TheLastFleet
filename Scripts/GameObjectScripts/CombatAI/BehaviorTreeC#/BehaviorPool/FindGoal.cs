using Godot;
using System;

public partial class FindGoal : Action
{
    bool is_friendly = false;
    public override NodeState Tick(Node agent)
    {
        if (is_friendly == true) return NodeState.SUCCESS;
        
        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");

        if (ship_wrapper.IsFriendly == true)
        {
            is_friendly = true;
            return NodeState.SUCCESS;
        }

        if (Engine.GetPhysicsFrames() % 480 == 0 || ship_wrapper.GroupLeader == false) return NodeState.FAILURE;

        if (ship_wrapper.CombatGoal == Globals.Goal.SKIRMISH && ship_wrapper.GoalFlag == true && ship_wrapper.TargetedUnits.Count == 0)
        {
            agent.Set("combat_flag", false);
            GetTree().CallGroup(ship_wrapper.GroupName, "set_goal_flag", false);
        }

        if (ship_wrapper.GoalFlag == true) return NodeState.SUCCESS;

        SteerData steer_data = (SteerData)agent.Get("SteerData");


        return NodeState.FAILURE;
    }

}
