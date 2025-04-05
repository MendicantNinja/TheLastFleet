using Godot;
using System;
using Vector2 = System.Numerics.Vector2;

public partial class Pursue : Action
{
	RigidBody2D target_unit = null;
	float prediction_window = 2.0f;
	float time = 0.0f;

	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");

		if (steer_data.TargetUnit == null)
		{
			return NodeState.SUCCESS;
		}

		if (ship_wrapper.VentFluxFlag == true || ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true)
		{
			return NodeState.FAILURE;
		}

		RigidBody2D n_agent = agent as RigidBody2D;
		ShipWrapper target_wrapper = (ShipWrapper)ship_wrapper.TargetUnit.Get("ShipWrapper");
		if (ship_wrapper.TargetInRange == true && (target_wrapper.FallbackFlag == true || target_wrapper.RetreatFlag == true))
		{
			target_wrapper.TargetedBy.Remove(n_agent);
			steer_data.TargetUnit = null;
			agent.Call("set_target_for_weapons", steer_data.TargetUnit);
			return NodeState.SUCCESS;
		}

		if (steer_data.TargetUnit != target_unit)
		{
			target_unit = steer_data.TargetUnit;
		}

		Vector2 agent_pos = new Vector2(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
		Vector2 target_pos = new Vector2(target_unit.GlobalPosition.X, target_unit.GlobalPosition.Y);

		Vector2 direction_to = SteerData.DirectionTo(agent_pos, target_pos);
		float distance_to = Vector2.Distance(agent_pos, target_pos);
		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}

		Vector2 velocity = speed * direction_to * time;
		Vector2 target_lin_vel = new Vector2(target_unit.LinearVelocity.X, target_unit.LinearVelocity.Y);
		Vector2 pred_direction = Vector2.Normalize(target_lin_vel);
		if (Math.Floor(target_unit.LinearVelocity.Length()) > 0.0f)
		{
			SteerData target_steer_data = (SteerData)target_unit.Get("SteerData");
			Vector2 pred_agent_pos = agent_pos + velocity;
			float max_speed = target_steer_data.DefaultAcceleration + target_steer_data.ZeroFluxBonus;
			
			float target_time = (steer_data.NDelta + steer_data.TimeCoefficient) * prediction_window;
			Vector2 pred_vel = max_speed * pred_direction * target_time;
			Vector2 pred_target_pos = pred_vel + target_pos;
			distance_to = Vector2.Distance(pred_agent_pos, pred_target_pos);
			direction_to = SteerData.DirectionTo(pred_agent_pos, pred_target_pos);
		}

		time += steer_data.NDelta + steer_data.TimeCoefficient;
		if (time * speed > speed)
		{
			time = 0.0f;
		}

		if (distance_to > steer_data.ThreatRadius)
		{
			velocity = direction_to * speed * time;
		}
		else if (distance_to < steer_data.ThreatRadius && distance_to > ship_wrapper.AverageWeaponRange)
		{
			if (ship_wrapper.CombatFlag == false) ship_wrapper.SetCombatFlag(true);
			float scale_speed = (distance_to - steer_data.ThreatRadius) / (steer_data.ThreatRadius - ship_wrapper.AverageWeaponRange);
			if (scale_speed < -0.7f) scale_speed = 0.1f;
			speed *= scale_speed;
			velocity = direction_to * speed * time;
		}
		else
		{
			float scale_speed = (ship_wrapper.AverageWeaponRange - distance_to) / ship_wrapper.AverageWeaponRange;
			velocity = pred_direction * speed * scale_speed;
		}

		steer_data.DesiredVelocity = velocity;
		steer_data.Time = time;
		return NodeState.FAILURE;
	}
}
