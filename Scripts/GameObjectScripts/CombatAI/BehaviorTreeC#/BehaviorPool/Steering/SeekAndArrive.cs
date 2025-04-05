using System;
using Godot;
using Vector2 = System.Numerics.Vector2;

public partial class SeekAndArrive : Action
{
	float target_area_radius = 50.0f;
	float epsilon = 1.0f;
	float time = 0.0f;

	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");

		Vector2 velocity = Vector2.Zero;
		Godot.Vector2 GD_agent_vector = (Godot.Vector2)agent.Get("global_position");
		Vector2 agent_position = new(GD_agent_vector.X, GD_agent_vector.Y);
		Vector2 direction_to_path = SteerData.DirectionTo(agent_position, steer_data.TargetPosition);
		float speed = steer_data.DefaultAcceleration;
		if ((ship_wrapper.SoftFlux + ship_wrapper.HardFlux) == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}

		if (steer_data.BrakeFlag == true)
		{
			speed = steer_data.Deceleration;
		}
		
		time += steer_data.NDelta + steer_data.TimeCoefficient;
		velocity = direction_to_path * speed * time;
		float distance_to = Vector2.Distance(agent_position, steer_data.TargetPosition) - target_area_radius;
		if (ship_wrapper.SuccessfulDeploy == false && ship_wrapper.GroupLeader == false && distance_to < target_area_radius)
		{
			agent.Set("successful_deploy", true);
			agent.Call("group_remove", ship_wrapper.GroupName);
		}

		Godot.Vector2 lin_vel = (Godot.Vector2)agent.Get("linear_velocity");
		float lin_vel_len = lin_vel.Length();
		float brake_distance = (lin_vel_len * lin_vel_len) / (2.0f * steer_data.DefaultAcceleration);
		if (distance_to <= brake_distance)
		{
			steer_data.BrakeFlag = true;
		}
		else if (distance_to > brake_distance && steer_data.BrakeFlag == true)
		{
			steer_data.BrakeFlag = false;
		}

		if (steer_data.BrakeFlag == false && speed * time > speed)
		{
			time = 0.0f;
		}

		if (steer_data.BrakeFlag == true)
		{
			velocity = new Vector2(lin_vel.X, lin_vel.Y);
			velocity = -Vector2.Normalize(velocity) * speed;
		}

		if (steer_data.BrakeFlag == true & lin_vel_len < epsilon)
		{
			agent.Set("target_position", Godot.Vector2.Zero);
			agent.Set("acceleration", Godot.Vector2.Zero);
			agent.Set("linear_velocity", Godot.Vector2.Zero);
			steer_data.BrakeFlag = false;
			steer_data.DesiredVelocity = Vector2.Zero;
			time = 0.0f;
			return NodeState.SUCCESS;
		}
		
		steer_data.Time = time;
		steer_data.DesiredVelocity = velocity;
		return NodeState.FAILURE;
	}
}
