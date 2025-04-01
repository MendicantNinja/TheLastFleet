using Godot;
using System;

public partial class Pursue : Action
{
    float time = 0.0f;

    public override NodeState Tick(Node agent)
    {
        ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");
        if (steer_data.TargetUnit == null)
        {
            return NodeState.SUCCESS;
        }

        if ((bool)steer_data.TargetUnit.Get("fallback_flag") == true)
        {
            ShipWrapper enemy_wrapper = (ShipWrapper)ship_wrapper.TargetUnit.Get("ShipWrapper");
        }

        return NodeState.FAILURE;
    }
}
