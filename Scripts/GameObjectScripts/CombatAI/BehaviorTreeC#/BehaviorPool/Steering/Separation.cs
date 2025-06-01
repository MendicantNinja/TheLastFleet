using Godot;
using System;
using System.Collections.Generic;
using System.Formats.Asn1;
using System.Linq;
using System.Linq.Expressions;
using System.Numerics;
using Vector2 = System.Numerics.Vector2;

public partial class Separation : Action
{
	float epsilon = 0.1f;
	float lv_sensitivity = 1.0f;
	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");
		steer_data.SeparationForce = Vector2.Zero;
		if (ship_wrapper.SeparationNeighbors == null || ship_wrapper.SeparationNeighbors.Count == 0 || steer_data.BrakeFlag == true)
		{
			return NodeState.FAILURE;
		}

		if (steer_data.BrakeFlag == true)
		{
			return NodeState.FAILURE;
		}
		
		RigidBody2D n_agent = agent as RigidBody2D;
		
		int index = 0;
		int batch_data_count = 3;
		float[] neighbor_data = new float[ship_wrapper.SeparationNeighbors.Count * batch_data_count];
		foreach (RigidBody2D neighbor in ship_wrapper.SeparationNeighbors)
		{
			if (!IsInstanceValid(neighbor) || neighbor.IsQueuedForDeletion()) continue;
			SteerData neighbor_steer_data = (SteerData)neighbor.Get("SteerData");
			if (neighbor.LinearVelocity.Length() > lv_sensitivity && neighbor_steer_data.BrakeFlag == false)
			{
				neighbor_data[index++] = neighbor.GlobalPosition.X;
				neighbor_data[index++] = neighbor.GlobalPosition.Y;
				neighbor_data[index++] = neighbor_steer_data.SqSeparationRadius;
			}
		}

		if (index == 0) 
		{
			return NodeState.FAILURE;
		}

		Array.Resize(ref neighbor_data, index);
		int vector_length = Vector<float>.Count;
		int batch_count = neighbor_data.Length / batch_data_count;
		int remainder = batch_count % vector_length;
		int array_size = batch_count + (remainder > 0 ? remainder : 0);
		float[] distances = new float[array_size];
		Vector2[] strafing_directions = new Vector2[array_size];
		index = 0;
		for (int i = 0; i + vector_length * batch_data_count < neighbor_data.Length; i += vector_length * batch_data_count)
		{
			// threshold_sq calculation here
			Vector<float> batch_pos_x = new Vector<float>(neighbor_data, i + vector_length * 0);
			Vector<float> batch_pos_y = new Vector<float>(neighbor_data, i + vector_length * 1);
			Vector<float> batch_avoid_radii = new Vector<float>(neighbor_data, i + vector_length * 2);
			Vector<float> delta_x = batch_pos_x - new Vector<float>(n_agent.GlobalPosition.X);
			Vector<float> delta_y = batch_pos_y - new Vector<float>(n_agent.GlobalPosition.Y);
			Vector<float> dist_sq = delta_x * delta_x + delta_y * delta_y;
			Vector<float> steer_radius_vector = new Vector<float>(steer_data.SqSeparationRadius);
			Vector<float> threshold_sq = steer_radius_vector + batch_avoid_radii;
			Vector<int> is_within_range = Vector.LessThanOrEqual(dist_sq, threshold_sq);
			if (Vector.EqualsAll(is_within_range, Vector<int>.Zero)) continue;
			
			Vector<float> valid_distances = Vector.ConditionalSelect(is_within_range, dist_sq, Vector<float>.Zero);
			float batch_min_dist = float.MaxValue;
			int batch_min_idx = -1;
			for (int j = 0; j < Vector<float>.Count; j++)
			{
				if (valid_distances[j] < batch_min_dist)
				{
					batch_min_dist = valid_distances[j];
					batch_min_idx = j;
				}
			}
			if (batch_min_idx == -1) continue;

			Vector2 strafe_dir = Vector2.Normalize(new Vector2(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y) - new Vector2(batch_pos_x[batch_min_idx], batch_pos_y[batch_min_idx]));
			// Update arrays
			distances[index] = batch_min_dist;
			strafing_directions[index] = strafe_dir;
			index++;
		}
		
		int remainder_start = (neighbor_data.Length / (vector_length * batch_data_count)) * (vector_length * batch_data_count); // Start index for remainder
		int radius_index = remainder_start / batch_data_count;
		for (int i = remainder_start; i < neighbor_data.Length; i += batch_data_count)
		{
			// Retrieve neighbor data
			float delta_x = neighbor_data[i + 0] - n_agent.GlobalPosition.X;
			float delta_y = neighbor_data[i + 1] - n_agent.GlobalPosition.Y;
			float threshold_sq = neighbor_data[i + 2] + steer_data.SqSeparationRadius;

			// Compute squared distance and check threshold
			float dist_sq = delta_x * delta_x + delta_y * delta_y;
			if (dist_sq > threshold_sq)
			{
				continue;
			}

			// Store valid distance
			distances[index] = dist_sq;
			Vector2 strafe_dir = Vector2.Normalize(new Vector2(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y) - new Vector2(neighbor_data[i + 0], neighbor_data[i + 1]));
			// Store strafing direction and increment the index
			strafing_directions[index] = strafe_dir;
			index++;
		}

		if (index == 0)
		{
			return NodeState.FAILURE;
		}

		Array.Resize(ref distances, index);
		Array.Resize(ref strafing_directions, index);
		float min_dist = float.MaxValue;
		int min_idx = 0;
		index = 0;
		foreach (float dist in distances)
		{
			if (dist < min_dist)
			{
				min_dist = dist;
				min_idx = index;
			}
			index++;
		}
		
		index = 0;
		//float separation_weight = 0.0f;
		Vector2 agg_separation_dir = new Vector2();
		foreach (float dist in distances)
		{
			float weight = 1.0f / (dist + epsilon);
			agg_separation_dir += strafing_directions[index] * weight;
			index++;
		}

		//separation_weight /= strafing_directions.Length;
		agg_separation_dir = Vector2.Normalize(agg_separation_dir);
		
		steer_data.SeparationForce = agg_separation_dir * steer_data.CurrentSpeed;
		float separation_urgency = (steer_data.SqSeparationRadius - min_dist) / (steer_data.SqSeparationRadius - steer_data.MinSeparationRadius);
		if (separation_urgency < 0.0f) separation_urgency = 0.0f;
		steer_data.SeparationWeight = separation_urgency;
		return NodeState.FAILURE;
	}
	
}
