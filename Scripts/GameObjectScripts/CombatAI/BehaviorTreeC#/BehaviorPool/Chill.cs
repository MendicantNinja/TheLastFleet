using Godot;
using System;
using System.Linq.Expressions;
using Vector2 = System.Numerics.Vector2;

public partial class Chill : Action
{
	public override NodeState Tick(Node agent)
	{
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		RigidBody2D n_agent = agent as RigidBody2D;

		if (!Equals(steer_data.TargetPosition, Vector2.Zero) || IsInstanceValid(ship_wrapper.TargetUnit) || ship_wrapper.TargetedUnits.Count > 0 || ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true)
		{
			if (steer_data.BrakeFlag == true) return NodeState.SUCCESS;
			n_agent.LinearDamp = 0.0f;
			return NodeState.SUCCESS;
		}

		float current_speed = n_agent.LinearVelocity.Length();
		if (current_speed > 1.0f)
		{
			steer_data.DesiredVelocity = Vector2.Zero;
			steer_data.AvoidanceWeight = 0.0f;
			steer_data.SeparationWeight = 0.0f;
			steer_data.CohesionWeight = 0.0f;
			agent.Set("acceleration", Godot.Vector2.Zero);
			//n_agent.LinearVelocity = Godot.Vector2.Zero;
			n_agent.LinearDamp = 10.0f;
		}
		else if (current_speed <= 1.0f)
		{
			n_agent.LinearDamp = 0.0f;
		}

		return NodeState.SUCCESS;
	}
}
