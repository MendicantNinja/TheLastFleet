using Godot;
using System;
public partial class SteerData : Node
{
	[Export]
	public Vector2 TargetPosition { get; private set; }

	[Export]
	public RigidBody2D TargetUnit { get; private set; }

    public Vector2 DesiredVelocity { get; set; }
    public float DefaultAcceleration { get; private set; }
    public float ZeroFluxBonus { get; private set; }
    public double NDelta { get; private set; }
    public float TimeCoefficient { get; private set; }
    public Vector2 MoveDirection { get; private set; }

    public void Initialize(Node agent)
    {
        var shipStats = (Resource)agent.Get("ship_stats") ?? throw new InvalidOperationException("ship_stats cannot be null");
        DesiredVelocity = Vector2.Zero;
        DefaultAcceleration = (float)shipStats.Get("acceleration") + (float)shipStats.Get("bonus_acceleration");
        TimeCoefficient = (float)agent.Get("time_coefficient");
    }
    
    public void SetDelta(double value)
    {
        NDelta = value;
    }

    public void SetMoveDirection(Vector2 value)
    {
        MoveDirection = value;
    }

	public void SetTargetPosition(Vector2 value)
	{
		TargetPosition = value;
	}
}
