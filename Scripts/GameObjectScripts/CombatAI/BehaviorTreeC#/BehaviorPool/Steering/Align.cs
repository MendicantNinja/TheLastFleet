using Godot;
using System;
using Vector2 = System.Numerics.Vector2;

public partial class Align : Action
{
	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		if (ship_wrapper.FallbackFlag == true || ship_wrapper.VentFluxFlag == true || ship_wrapper.RetreatFlag == true)
		{
			return NodeState.FAILURE;
		}


		RigidBody2D n_agent = agent as RigidBody2D;
		Vector2 agent_pos = new(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
		Transform2D transform_look_at;
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		if (steer_data.TargetUnit == null)
		{
			transform_look_at = SteerData.LookingAt(agent_pos, steer_data.TargetPosition);
		}
		else
		{
			Vector2 enemy_pos = new(steer_data.TargetUnit.GlobalPosition.X, steer_data.TargetUnit.GlobalPosition.Y);
			transform_look_at = SteerData.LookingAt(agent_pos, enemy_pos);
		}

		n_agent.Transform = n_agent.Transform.InterpolateWith(transform_look_at, steer_data.TurnRate * steer_data.NDelta);

		return NodeState.SUCCESS;
	}
}
