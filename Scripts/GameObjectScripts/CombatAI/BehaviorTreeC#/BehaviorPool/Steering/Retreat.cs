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

        if (steer_data.SeparationForce != Vector2.Zero)
        {
            steer_data.SeparationForce = Vector2.Zero;
        }

        // Check to see if there are no nearby agents, and if there are none, set the vent flux flag
        // Use rotate_angle
        
        steer_data.DesiredVelocity = move_direction * speed;
        return NodeState.FAILURE;
    }

}
