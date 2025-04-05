using Godot;
using System;
using System.Linq.Expressions;

public partial class Chill : Action
{
	public override NodeState Tick(Node agent)
	{
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		RigidBody2D n_agent = agent as RigidBody2D;

		if (Vector2.Equals(steer_data.TargetPosition, Vector2.Zero) == false | steer_data.TargetUnit != null | ship_wrapper.TargetedUnits.Count == 0 | ship_wrapper.FallbackFlag == true | ship_wrapper.RetreatFlag == true)
		{
			n_agent.LinearDamp = 0.0f;
			return NodeState.SUCCESS;
		}

		float current_speed = n_agent.LinearVelocity.Length();
		if (Math.Floor(current_speed) > 0.0f)
		{
			n_agent.LinearDamp = 5.0f;
		}
		else if (current_speed == 0.0f)
		{
			n_agent.LinearDamp = 0.0f;
			steer_data.BrakeFlag = false;
		}
		return NodeState.SUCCESS;
	}

}
