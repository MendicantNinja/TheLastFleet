using Godot;
using System;
using Vector2 = System.Numerics.Vector2;

public partial class SteerData : Node
{
	[Export]
	public RigidBody2D TargetUnit { get; set; }
    public Vector2 DesiredVelocity { get; set; }
    [Export]
    public float DefaultAcceleration { get; private set; }
    public float Deceleration { get; private set; }
    public float ZeroFluxBonus { get; private set; }
    public float TurnRate { get; private set; }
    [Export]
    public float NDelta { get; private set; }
    public float TimeCoefficient { get; private set; }
    public float Time { get; set; }
    public float FOFRadius { get; private set; }
    public float SqFOFRadius { get; private set; }
    public Vector2 MoveDirection { get; private set; }
    public Vector2 TargetPosition { get; private set; }
    [Export]
    public Godot.Vector2 debugTargetP { get; private set; }
    [Export]
    public bool BrakeFlag { get; set; }
    public float RADCoe = 2.0f;
    public void Initialize(Node agent)
    {
        var shipStats = (Resource)agent.Get("ship_stats") ?? throw new InvalidOperationException("ship_stats cannot be null");
        DesiredVelocity = Vector2.Zero;
        DefaultAcceleration = (float)shipStats.Get("acceleration") + (float)shipStats.Get("bonus_acceleration");
        TimeCoefficient = (float)agent.Get("time_coefficient");
        Deceleration = (float)shipStats.Get("deceleration") + (float)shipStats.Get("bonus_deceleration");
        TurnRate = (float)shipStats.Get("turn_rate");
        TargetUnit = null;
        TargetPosition = Vector2.Zero;
    }
    
    public void SetDelta(double value)
    {
        NDelta = (float)value;
    }

    public void SetMoveDirection(Vector2 value)
    {
        MoveDirection = value;
    }

	public void SetTargetPosition(Godot.Vector2 vector)
	{
		TargetPosition = new Vector2(vector.X, vector.Y);
        debugTargetP = vector;
	}

    public void SetFOFRadius(float radius)
    {
        FOFRadius = radius;
        SqFOFRadius = FOFRadius * FOFRadius;
    }

    public static Vector2 DirectionTo(Vector2 from, Vector2 to)
    {
        Vector2 direction = to - from;
        return Vector2.Normalize(direction);
    }

    public static Transform2D LookingAt(Vector2 agent_position, Vector2 target_position)
    {
        Vector2 direction = Vector2.Normalize(target_position - agent_position);
        float angle = Mathf.Atan2(direction.Y, direction.X);
        Godot.Vector2 GD_agent_position = new(agent_position.X, agent_position.Y);
        return new Transform2D(angle, GD_agent_position);
    }
}
