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

		if (!Equals(steer_data.TargetPosition, Vector2.Zero) || steer_data.TargetUnit != null || ship_wrapper.TargetedUnits.Count > 0 || ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true)
		{
			if (steer_data.BrakeFlag == true) return NodeState.SUCCESS;
			n_agent.LinearDamp = 0.0f;
			return NodeState.SUCCESS;
		}

		float current_speed = n_agent.LinearVelocity.Length();
		if (Mathf.Floor(current_speed) > float.Epsilon)
		{
			steer_data.DesiredVelocity = Vector2.Zero;
			steer_data.AvoidanceForce = Vector2.Zero;
			steer_data.SeparationForce = Vector2.Zero;
			n_agent.LinearDamp = 5.0f;
		}
		else if (current_speed <= float.Epsilon)
		{
			n_agent.LinearDamp = 0.0f;
		}

		return NodeState.SUCCESS;
	}
}
