using Globals;
using Godot;
using System;
using System.Collections.Generic;
using Vector2 = System.Numerics.Vector2;

public partial class DetectGoals : Action
{
    public override NodeState Tick(Node agent)
    {
        if (Engine.GetPhysicsFrames() % 160 != 0) return NodeState.SUCCESS;

        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");

        if (ship_wrapper.CombatGoal == Goal.MOVE_HOLD)
        {
            foreach (Vector2I registry_cell in ship_wrapper.RegistryNeighborhood)
            {
                
            }
        }

        return NodeState.SUCCESS;
    }
}
