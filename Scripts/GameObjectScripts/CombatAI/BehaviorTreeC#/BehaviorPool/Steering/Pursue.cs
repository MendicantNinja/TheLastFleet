using Godot;
using System;
using Vector2 = System.Numerics.Vector2;

public partial class Pursue : Action
{
	RigidBody2D target_unit = null;
	float prediction_window = 4.0f;
	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		if (ship_wrapper.RetreatFlag == true || !IsInstanceValid(ship_wrapper.TargetUnit) || ship_wrapper.TargetUnit is null)
		{
			return NodeState.SUCCESS;
		}
		
		if (ship_wrapper.VentFluxFlag == true || ship_wrapper.FallbackFlag == true)
		{
			return NodeState.FAILURE;
		}

		steer_data = (SteerData)agent.Get("SteerData");
		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}
		steer_data.CurrentSpeed = speed;

		RigidBody2D n_agent = agent as RigidBody2D;
		ShipWrapper target_wrapper = (ShipWrapper)ship_wrapper.TargetUnit.Get("ShipWrapper");
		if (ship_wrapper.CombatFlag == true && ship_wrapper.TargetInRange == false && target_wrapper.FallbackFlag == true)
		{
			Godot.Collections.Array<RigidBody2D> targeted_by = (Godot.Collections.Array<RigidBody2D>)ship_wrapper.TargetUnit.Get("targeted_by");
			targeted_by.Remove(n_agent);
			ship_wrapper.TargetUnit.Set("targeted_by", targeted_by);
			agent.Call("set_target_unit", new Godot.Collections.Array<int>());
			ship_wrapper.TargetUnit = null;
			steer_data.TargetUnit = null;
			agent.Call("set_target_for_weapons", new Godot.Collections.Array<int>());
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
		Vector2 velocity = steer_data.CurrentSpeed * direction_to;
		Vector2 target_lin_vel = new Vector2(target_unit.LinearVelocity.X, target_unit.LinearVelocity.Y);
		//Vector2 pred_direction = Vector2.Normalize(target_lin_vel);
		if (target_lin_vel.Length() > 1.0f)
		{
			//SteerData target_steer_data = (SteerData)target_unit.Get("SteerData");
			Vector2 pred_agent_pos = agent_pos + new Vector2(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y) * prediction_window;
			//float max_speed = target_steer_data.DefaultAcceleration + target_steer_data.ZeroFluxBonus;

			//float target_time = (steer_data.NDelta + steer_data.TimeCoefficient) * prediction_window;
			//Vector2 pred_vel = max_speed * pred_direction * target_time;
			//Vector2 pred_target_pos = pred_vel + target_pos;
			Vector2 pred_target_pos = target_lin_vel + target_pos;
			distance_to = Vector2.Distance(pred_agent_pos, pred_target_pos);
			direction_to = SteerData.DirectionTo(pred_agent_pos, pred_target_pos);
		}

		if (distance_to > steer_data.ThreatRadius)
		{
			steer_data.GoalWeight = 1.0f;
		}
		else if (distance_to < ship_wrapper.AverageWeaponRange)
		{
			float normalized_distance = speed * (distance_to / ship_wrapper.AverageWeaponRange);
			//steer_data.GoalWeight = Mathf.Clamp(normalized_distance, 0.1f, 1.0f);
			velocity = new Vector2(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y) - (direction_to * speed * normalized_distance); // Gradual slowdown
		}
		
		steer_data.DesiredVelocity = velocity;
		return NodeState.FAILURE;
	}
}
