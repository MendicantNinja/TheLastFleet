using System;
using System.Numerics;
using Godot;
using Vector2 = System.Numerics.Vector2;

public partial class SeekAndArrive : Action
{
	float target_area_radius = 10.0f;
	float hystersis_buffer = 2.0f;
	float separation_buffer = 3.0f;
	float time_to_target = 0.1f;
	float lerp_weight = 0.1f;
	float prediction_window = 2.0f;
	int epsilon = 1;
	bool debug = false;

	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");
		steer_data.DesiredVelocity = Vector2.Zero;
		Vector2 velocity;
		RigidBody2D n_agent = agent as RigidBody2D;
		Vector2 agent_position = new Vector2(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
		Vector2 direction_to_path = SteerData.DirectionTo(agent_position, steer_data.TargetPosition);
		float speed = steer_data.DefaultAcceleration;
		if ((ship_wrapper.SoftFlux + ship_wrapper.HardFlux) == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}
		steer_data.CurrentSpeed = speed;
		
		velocity = direction_to_path * speed;
		float distance_to = (steer_data.TargetPosition - agent_position).Length();
		if (debug == false && ship_wrapper.DeployFlag == false && distance_to < target_area_radius / 2.0f)
		{
			ship_wrapper.EmitSignal(ShipWrapper.SignalName.Deployed);
		}

		Vector2 predict_pos = agent_position + new Vector2(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y) * prediction_window;
		direction_to_path = SteerData.DirectionTo(predict_pos, steer_data.TargetPosition);
		velocity = direction_to_path * speed;
		float sq_lin_vel = n_agent.LinearVelocity.LengthSquared();
		float brake_distance = hystersis_buffer * sq_lin_vel / (2 * speed);
		if (distance_to <= brake_distance && steer_data.BrakeFlag == false)
		{
			steer_data.BrakeFlag = true;
			agent.Set("brake_flag", steer_data.BrakeFlag);
		}
		else if (distance_to > brake_distance && steer_data.BrakeFlag == true)
		{
			n_agent.LinearDamp = 0.0f;
			steer_data.BrakeFlag = false;
			agent.Set("brake_flag", steer_data.BrakeFlag);
		}

		//if (distance_to < brake_distance * separation_buffer) steer_data.SeparationWeight = 0.0f;

		if (steer_data.BrakeFlag == true)
		{
			speed *= distance_to / brake_distance;
			float angular_dampening = Mathf.Clamp(distance_to / (target_area_radius * hystersis_buffer), 0.1f, 1.0f);
			velocity = Vector2.Normalize(velocity) * angular_dampening;
			velocity *= speed;
			velocity -= new Vector2(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y);
			velocity /= time_to_target;
		}

		if (distance_to < target_area_radius * 2) n_agent.LinearDamp = 0.5f;

		if (distance_to < target_area_radius && n_agent.LinearVelocity.Length() > epsilon)
		{
			n_agent.LinearDamp = 1.0f;
			velocity = new Vector2(-n_agent.LinearVelocity.X, -n_agent.LinearVelocity.Y) * time_to_target;
		}

		if (steer_data.BrakeFlag == true && distance_to < target_area_radius / 2)
		{
			agent.Set("target_position", Godot.Vector2.Zero);
			agent.Set("acceleration", Godot.Vector2.Zero);
			agent.Set("linear_velocity", Godot.Vector2.Zero);
			steer_data.BrakeFlag = false;
			agent.Set("brake_flag", steer_data.BrakeFlag);
			steer_data.SeparationForce = Vector2.Zero;
			steer_data.CohesionForce = Vector2.Zero;
			steer_data.AvoidanceForce = Vector2.Zero;
			steer_data.SeparationWeight = 0.0f;
			steer_data.AvoidanceWeight = 0.0f;
			steer_data.CohesionWeight = 0.0f;
			//steer_data.GoalWeight = float.Epsilon;
			steer_data.DesiredVelocity = Vector2.Zero;
			GD.Print(agent.Name, " navigated to position");
			return NodeState.SUCCESS;
		}
		
		steer_data.DesiredVelocity = velocity;

		return NodeState.FAILURE;
	}
}
