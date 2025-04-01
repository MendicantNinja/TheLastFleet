using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using Vector2 = System.Numerics.Vector2;

public partial class Separation : Action
{
	float time = 0.0f;

	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");

		if (ship_wrapper.NeighborUnits == null || ship_wrapper.NeighborUnits.Length == 0)
		{
			return NodeState.FAILURE;
		}

		List<RigidBody2D> friendly_neighbors = new List<RigidBody2D>();
		foreach (RigidBody2D unit in ship_wrapper.NeighborUnits)
		{
			if (unit == null) continue;
			if (ship_wrapper.IsFriendly == (bool)unit.Get("is_friendly"))
			{
				friendly_neighbors.Add(unit);
			}
		}

		RigidBody2D n_agent = agent as RigidBody2D;

		Vector2 agent_position = new(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
		Vector2 agent_transform_x = new(n_agent.Transform.X.X, n_agent.Transform.X.Y);
		Vector2 agent_transform_y = new(n_agent.Transform.Y.X, n_agent.Transform.Y.Y);
		double magnitude_x = Math.Sqrt(agent_transform_x.Length());
		Dictionary<double, Vector2> strafe_direction = new Dictionary<double, Vector2>();
		foreach (RigidBody2D neighbor in friendly_neighbors)
		{
			SteerData neighbor_data = (SteerData)neighbor.Get("SteerData");
			Vector2 neighbor_position = new(neighbor.GlobalPosition.X, neighbor.GlobalPosition.Y);
			float neighbor_fof = neighbor_data.SqFOFRadius;
			float dist_sq = Vector2.DistanceSquared(agent_position, neighbor_position);
			if (dist_sq > (steer_data.SqFOFRadius + neighbor_fof))
			{
				continue;
			}

			Vector2 direction_to = SteerData.DirectionTo(agent_position, neighbor_position);
			float agent_dot_neighbor = Vector2.Dot(agent_transform_x, direction_to);
			double magnitude_direction = Math.Sqrt(direction_to.Length());
			double angle_to = Math.Acos(agent_dot_neighbor / (magnitude_x * magnitude_direction));
			if (angle_to < 0.0f)
			{
				strafe_direction.Add(dist_sq, agent_transform_y);
			}
			else if (angle_to > 0.0f)
			{
				strafe_direction.Add(dist_sq, -agent_transform_y);
			}
		}

		if (strafe_direction.Count == 0)
		{
			time = 0.0f;
			return NodeState.FAILURE;
		}

		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}

		time += steer_data.NDelta + steer_data.TimeCoefficient;
		double min_distance = strafe_direction.Keys.Min();
		Vector2 separation_velocity = strafe_direction[min_distance] * speed * time;
		if (time * speed > speed)
		{
			time = 0.0f;
			separation_velocity = strafe_direction[min_distance] * speed;
		}
		
		Vector2 new_velocity = steer_data.DesiredVelocity * 0.5f + separation_velocity * 0.2f;
		if (ship_wrapper.CombatFlag == true)
		{
			new_velocity = steer_data.DesiredVelocity * 0.5f + separation_velocity * 0.5f;
		}

		
		steer_data.Time = time;
		steer_data.DesiredVelocity = new_velocity;
		return NodeState.FAILURE;
	}
}
