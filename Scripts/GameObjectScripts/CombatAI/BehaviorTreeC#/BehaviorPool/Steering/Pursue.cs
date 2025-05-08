using Godot;
using System;
using Vector2 = System.Numerics.Vector2;

public partial class Pursue : Action
{
	RigidBody2D target_unit = null;
	float prediction_window = 2.0f;
	public override NodeState Tick(Node agent)
	{
		steer_data = (SteerData)agent.Get("SteerData");
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");


		if (ship_wrapper.TargetUnit == null)
		{
			return NodeState.SUCCESS;
		}
		
		if (ship_wrapper.VentFluxFlag == true || ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true)
		{
			return NodeState.FAILURE;
		}

		RigidBody2D n_agent = agent as RigidBody2D;
		ShipWrapper target_wrapper = (ShipWrapper)ship_wrapper.TargetUnit.Get("ShipWrapper");
		if (ship_wrapper.CombatFlag == true && ship_wrapper.TargetInRange == false && (target_wrapper.FallbackFlag == true || target_wrapper.RetreatFlag == true))
		{
			Godot.Collections.Array<RigidBody2D> targeted_by = (Godot.Collections.Array<RigidBody2D>)ship_wrapper.TargetUnit.Get("targeted_by");
			targeted_by.Remove(n_agent);
			ship_wrapper.TargetUnit.Set("targeted_by", targeted_by);
			RigidBody2D dummy = null;
			agent.Set("target_unit", dummy);
			ship_wrapper.TargetUnit = null;
			steer_data.TargetUnit = null;
			agent.Call("set_target_for_weapons", steer_data.TargetUnit);
			return NodeState.SUCCESS;
		}
		
		if (steer_data.TargetUnit != target_unit)
		{
			target_unit = steer_data.TargetUnit;
		}

		if (target_unit == null)
		{
			return NodeState.SUCCESS;
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

		Vector2 velocity = speed * direction_to;
		Vector2 target_lin_vel = new Vector2(target_unit.LinearVelocity.X, target_unit.LinearVelocity.Y);
		Vector2 pred_direction = Vector2.Normalize(target_lin_vel);
		if (Math.Floor(target_lin_vel.Length()) > 0.0f)
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

		if (distance_to > steer_data.ThreatRadius)
		{
			steer_data.GoalWeight = 1.0f;
			velocity = direction_to * speed;
		}
		else if (distance_to < steer_data.ThreatRadius && distance_to > ship_wrapper.AverageWeaponRange)
		{
			//agent.Set("combat_flag", true);
			float normalized_distance = 1.0f - (distance_to - ship_wrapper.AverageWeaponRange) / (steer_data.ThreatRadius - ship_wrapper.AverageWeaponRange);
   			steer_data.GoalWeight = Mathf.Clamp(normalized_distance, 0.1f, 1.0f);
			velocity = direction_to * Mathf.Lerp(speed * 0.5f, -speed, normalized_distance); // Gradual slowdown
		}
		else
		{
			float normalized_weight = Mathf.Clamp((ship_wrapper.AverageWeaponRange - distance_to) / ship_wrapper.AverageWeaponRange, 0.1f, 1.0f);
			steer_data.GoalWeight = Mathf.Lerp(steer_data.GoalWeight, normalized_weight, 0.1f);
			velocity = direction_to * Mathf.Lerp(0.0f, -speed / normalized_weight, normalized_weight); // More controlled movement near combat range
		}

		steer_data.DesiredVelocity = velocity;
		return NodeState.FAILURE;
	}
}
