using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using Vector2 = System.Numerics.Vector2;

public partial class DynamicAvoidance : Action
{
	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");
		
		Godot.Vector2 conv_DV = new Godot.Vector2(steer_data.DesiredVelocity.X, steer_data.DesiredVelocity.Y);
		if (ship_wrapper.NeighborUnits == null || ship_wrapper.NeighborUnits.Length == 0)
		{
			agent.Set("acceleration", conv_DV);
			return NodeState.FAILURE;
		}
		RigidBody2D n_agent = agent as RigidBody2D;

		float speed = steer_data.DefaultAcceleration;
		Vector2 agent_lv = new(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y);
		Vector2 agent_pos = new(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
		float proj_speed = speed * steer_data.Time;
		Dictionary<float, Vector2> avoid_vel = new Dictionary<float, Vector2>();
		Godot.Collections.Array<Godot.Node> group = GetTree().GetNodesInGroup(ship_wrapper.GroupName);
		foreach (RigidBody2D neighbor in ship_wrapper.NeighborUnits)
		{
			SteerData neighbor_steer_data = (SteerData)neighbor.Get("SteerData");
			if (group.Contains(neighbor) && neighbor_steer_data.BrakeFlag == true && neighbor_steer_data.TargetUnit == null)
			{
				continue;
			}
			Vector2 neighbor_pos = new(neighbor.GlobalPosition.X, neighbor.GlobalPosition.Y);
			Vector2 neighbor_lv = new(neighbor.LinearVelocity.X, neighbor.LinearVelocity.Y);
			
			Vector2 rel_p = neighbor_pos - agent_pos;
			Vector2 rel_v = agent_lv - neighbor_lv;
			float r = steer_data.FOFRadius + neighbor_steer_data.FOFRadius;
			float cone = Vector2.Dot(rel_v, rel_v) * (Vector2.Dot(rel_p, rel_p) - r * r);
			float sq_rel_v = Vector2.Dot(rel_v, rel_p);
			sq_rel_v *= sq_rel_v;
			if (sq_rel_v < cone)
			{
				continue;
			}

			Vector2 projection = (Vector2.Dot(rel_v, rel_p) / Vector2.Dot(rel_p, rel_p)) * rel_p;
			Vector2 translation = steer_data.DesiredVelocity + (rel_v - projection);
			if (Mathf.Round(neighbor_lv.Length()) == 0.0f)
			{
				translation = steer_data.DesiredVelocity - agent_lv + (rel_v - projection);
			}

			Vector2 avoid_direction = Vector2.Normalize(translation);
			Vector2 avoid_velocity = avoid_direction * speed * steer_data.Time;
			if (proj_speed > speed)
			{
				avoid_velocity = avoid_direction * speed;
			}
			float test_avoid = Vector2.Dot(avoid_velocity, rel_p);
			test_avoid *= test_avoid;
			if (test_avoid >= cone)
			{
				continue;
			}
		
			float dist_sq = Vector2.DistanceSquared(agent_pos, neighbor_pos);
			avoid_vel[dist_sq] = avoid_velocity;
		}

		if (avoid_vel.Count == 0)
		{
			agent.Set("acceleration", conv_DV);
			return NodeState.FAILURE;
		}
		
		float min_dist = avoid_vel.Keys.Min();
		steer_data.DesiredVelocity = avoid_vel[min_dist];
		conv_DV = new Godot.Vector2(steer_data.DesiredVelocity.X, steer_data.DesiredVelocity.Y);
		agent.Set("acceleration", conv_DV);
		return NodeState.FAILURE;
	}
	
}
