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
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		if (steer_data.TargetPosition != Vector2.Zero & (!IsInstanceValid(ship_wrapper.TargetUnit)|| ship_wrapper.TargetUnit.IsQueuedForDeletion()))
		{
			Transform2D transform_look_at = SteerData.LookingAt(agent_pos, steer_data.TargetPosition);
			n_agent.Transform = n_agent.Transform.InterpolateWith(transform_look_at, steer_data.TurnRate * steer_data.NDelta);
		//Vector2 steer_force = steer_data.SteeringForce;
			agent.Set("avoidance_force", new Godot.Vector2(steer_data.AvoidanceForce.X, steer_data.AvoidanceForce.Y) * steer_data.AvoidanceWeight);
			agent.Set("separation_force", new Godot.Vector2(steer_data.SeparationForce.X, steer_data.SeparationForce.Y) * steer_data.SeparationWeight);
			agent.Set("goal_force", new Godot.Vector2(steer_data.DesiredVelocity.X, steer_data.DesiredVelocity.Y) * steer_data.GoalWeight);
		}
		else
		{
			Vector2 enemy_pos = new(steer_data.TargetUnit.GlobalPosition.X, steer_data.TargetUnit.GlobalPosition.Y);
			Transform2D transform_look_at = SteerData.LookingAt(agent_pos, enemy_pos);
			n_agent.Transform = n_agent.Transform.InterpolateWith(transform_look_at, steer_data.TurnRate * steer_data.NDelta);
		//Vector2 steer_force = steer_data.SteeringForce;
			agent.Set("avoidance_force", new Godot.Vector2(steer_data.AvoidanceForce.X, steer_data.AvoidanceForce.Y) * steer_data.AvoidanceWeight);
			agent.Set("separation_force", new Godot.Vector2(steer_data.SeparationForce.X, steer_data.SeparationForce.Y) * steer_data.SeparationWeight);
			agent.Set("goal_force", new Godot.Vector2(steer_data.DesiredVelocity.X, steer_data.DesiredVelocity.Y) * steer_data.GoalWeight);
		}
		/*
		GD.Print(agent.Name, " Align");
		GD.Print(transform_look_at);
		GD.Print();
		*/
		
		return NodeState.SUCCESS;
	}
}
