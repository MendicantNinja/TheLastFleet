using System.Collections.Generic;
using System.Runtime.Serialization.Formatters;
using Godot;
using Vector2 = System.Numerics.Vector2;

public partial class Retreat : Action
{
    Vector2 current_retreat_dir = Vector2.Zero;
    public override NodeState Tick(Node agent)
    {
        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
        if (ship_wrapper.RetreatFlag == false) return NodeState.SUCCESS;

        SteerData steer_data = (SteerData)agent.Get("SteerData");
        RigidBody2D n_agent = agent as RigidBody2D;
        Vector2 move_direction = new Vector2(-n_agent.Transform.X.X, -n_agent.Transform.X.Y);
        if (current_retreat_dir == Vector2.Zero)
        {
            current_retreat_dir = move_direction;
        }

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
        // Must rely on transform interpolation in order to reorient agent
        if (ship_wrapper.CombatFlag == false)
        {
            steer_data.RotateDirection = new Vector2(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y) + current_retreat_dir * speed;
        }
        else if (ship_wrapper.CombatFlag == true && Engine.GetPhysicsFrames() % 60 == 0 && ship_wrapper.TargetedBy.Count > 0)
        {
            Godot.Collections.Array<RigidBody2D> valid_attackers = new Godot.Collections.Array<RigidBody2D>();
            Vector2 arithmetic_mean = Vector2.Zero;
            int count = 0;
            foreach (RigidBody2D attacker in ship_wrapper.TargetedBy)
            {
                if (!IsInstanceValid(attacker) || attacker.IsQueuedForDeletion()) continue;
                if (valid_attackers.Contains(attacker)) continue;
                valid_attackers.Add(attacker);
                arithmetic_mean += new Vector2(attacker.GlobalPosition.X, attacker.GlobalPosition.Y);
                count++;
            }
            arithmetic_mean /= count;
            steer_data.RotateDirection = arithmetic_mean;
            agent.Set("targeted_by", valid_attackers);
        }

        steer_data.CurrentSpeed = speed;
        steer_data.DesiredVelocity = current_retreat_dir * speed;
        return NodeState.FAILURE;
    }

}
