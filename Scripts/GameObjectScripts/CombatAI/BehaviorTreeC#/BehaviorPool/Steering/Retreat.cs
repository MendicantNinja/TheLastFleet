using Godot;
using Vector2 = System.Numerics.Vector2;

public partial class Retreat : Action
{
    public override NodeState Tick(Node agent)
    {
        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
        if (ship_wrapper.RetreatFlag == false) return NodeState.SUCCESS;

        SteerData steer_data = (SteerData)agent.Get("SteerData");
        RigidBody2D n_agent = agent as RigidBody2D;
        Vector2 move_direction = new Vector2(-n_agent.Transform.X.X, -n_agent.Transform.X.Y);

        float speed = steer_data.DefaultAcceleration;
        if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
        {
            speed += steer_data.ZeroFluxBonus;
        }

        steer_data.DesiredVelocity = move_direction * speed;
        return NodeState.FAILURE;
    }

}
