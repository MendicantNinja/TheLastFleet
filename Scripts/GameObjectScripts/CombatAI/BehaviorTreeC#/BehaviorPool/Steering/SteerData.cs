using Godot;
using System;
using Vector2 = System.Numerics.Vector2;

public partial class SteerData : Node
{
    // Core Parameters
    [Export]
    public RigidBody2D TargetUnit { get; set; }
    
    public Vector2 DesiredVelocity { get; set; } = Vector2.Zero;
    
    [Export]
    public float DefaultAcceleration { get; set; }
    public float Deceleration { get; set; }
    public float ZeroFluxBonus { get; set; }
    public float TurnRate { get; set; }
    
    [Export]
    public float NDelta { get; set; }
    
    public float TimeCoefficient { get; set; }
    public float Time { get; set; }

    [Export]
    public float SqSeparationRadius { get; private set; }
    public float FOFRadius { get; set; }
    public float SqFOFRadius { get; set; }
    public float AvoidRadius { get; set; }
    [Export]
    public float ThreatRadius { get; private set; }

    public int AvoidanceBias = 0;
    
    public Vector2 MoveDirection { get; set; } = Vector2.Zero;
    public Vector2 TargetPosition { get; set; } = Vector2.Zero;
    
    [Export]
    public Godot.Vector2 debugTargetP { get; set; } // Keeps the original Godot type if needed for debugging.
    [Export]
    public bool BrakeFlag { get; set; }
    
    public float RADCoe = 2.0f;
    
    // --- Steering Behavior Forces ---
    // These properties let your individual behavior modules simply assign to the vector.
    public Vector2 SeparationForce { get; set; } = Vector2.Zero;
    public Vector2 AvoidanceForce { get; set; } = Vector2.Zero;
    
    // Weights for blending forces.
    public float SeparationWeight { get; set; } = 0.0f;
    public float AvoidanceWeight { get; set; } = 0.0f;
    public float GoalWeight { get; set; } = 1.0f;
    
    // Computed aggregation of all steering forces.
    public Vector2 SteeringForce
    {
        get
        {
            Vector2 aggregated = DesiredVelocity;
            float total_weight = SeparationWeight + AvoidanceWeight + GoalWeight;
            if (total_weight == 0.0f) return aggregated;
                        
            aggregated = SeparationForce * SeparationWeight +
                                 AvoidanceForce * AvoidanceWeight +
                                 DesiredVelocity;
            
            aggregated /= total_weight;
            return aggregated;
        }
    }
    
    // A convenience routine to update the agent's final desired velocity.
    public void UpdateDesiredVelocity(float maxForce)
    {
        Vector2 force = SteeringForce;
        if (force.Length() > maxForce)
        {
            force = Vector2.Normalize(force) * maxForce;
        }
        DesiredVelocity = force;
    }
    
    public void Initialize(Node agent)
    {
        var shipStats = (Resource)agent.Get("ship_stats") 
                        ?? throw new InvalidOperationException("ship_stats cannot be null");
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

    public void SetTargetUnit(RigidBody2D target)
    {
        TargetUnit = target;
    }

    public void SetFOFRadius(float radius)
    {
        FOFRadius = radius;
        SqFOFRadius = FOFRadius * FOFRadius;
    }

    public void SetThreatRadius(float radius)
    {
        ThreatRadius = radius;
    }

    public void SetAvoidRadius(float radius)
    {
        AvoidRadius = radius;
    }

    public void SetSqSeparationRadius(float radius)
    {
        SqSeparationRadius = radius;
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
