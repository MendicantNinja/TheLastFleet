using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using Vector2 = System.Numerics.Vector2;

public partial class DynamicAvoidance : Action
{
	float epsilon = 0.01f;
	bool debug = false;
	float ttc_min = 4.0f;
	float ttc_default = 8.0f;
	float ttc_max = 20.0f;
	float lerp_weight = 0.1f;
	float stop_coe = 0.1f;
	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");
		RigidBody2D n_agent = agent as RigidBody2D;
		
		Vector2 steering_force = steer_data.SteeringForce;
		if (debug == true || steer_data.BrakeFlag == true || ship_wrapper.NeighborUnits == null || ship_wrapper.NeighborUnits.Count == 0)
		{
			steer_data.AvoidanceWeight = 0.0f;
			steer_data.GoalWeight = 1.0f;
			steering_force = steer_data.SteeringForce;
			agent.Set("acceleration", new Godot.Vector2(steering_force.X, steering_force.Y));
			return NodeState.FAILURE;
		}

		Vector2 agent_lv = new(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y);
		Vector2 agent_pos = new(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f) speed += steer_data.ZeroFluxBonus;

		List<RigidBody2D> valid_neighbors = new List<RigidBody2D>();
		valid_neighbors = ship_wrapper.SeparationNeighbors.OfType<RigidBody2D>().Where(unit => unit != null && (bool)unit.Get("steer_data") == false).ToList();
		int total_neighbors = valid_neighbors.Count;
		int batch_data_count = 5;
		float[] neighbor_data = new float[total_neighbors * batch_data_count]; // Total size: neighbors * data per neighbor
		int index = 0; // Tracks the position within neighbor units
		foreach (RigidBody2D neighbor in valid_neighbors)
		{
			SteerData neighbor_steer_data = (SteerData)neighbor.Get("SteerData");
			neighbor_data[index++] = neighbor.GlobalPosition.X; // Store pos_x
			neighbor_data[index++] = neighbor.GlobalPosition.Y; // Store pos_y
			neighbor_data[index++] = neighbor.LinearVelocity.X; // Store vel_x
			neighbor_data[index++] = neighbor.LinearVelocity.Y; // Store vel_y
			neighbor_data[index++] = neighbor_steer_data.AvoidRadius; // Store radii
		}
		if (index == 0)
		{
			steer_data.AvoidanceWeight = 0.0f;
			steer_data.GoalWeight = 1.0f;
			agent.Set("acceleration", new Godot.Vector2(steering_force.X, steering_force.Y));
			return NodeState.FAILURE;
		}
		
		// AvoidanceBias related variables
		int bias_counter = 0;
		//float aggregate_bias = 0.0f;
		
		int vector_length = Vector<float>.Count;
		int remainder = total_neighbors % vector_length;
		int batch_size = neighbor_data.Length / batch_data_count;
		int remainder_start = neighbor_data.Length / (vector_length * batch_data_count) * vector_length * batch_data_count;
		int array_size = batch_size * vector_length + (remainder > 0 ? remainder : 0);
		float[] time_to_collision = new float[array_size];
		Vector2[] avoid_velocities = new Vector2[array_size];
		index = 0;
		for (int i = 0; i + vector_length <= total_neighbors; i += vector_length)
		{
			Vector<float> batch_pos_x = new Vector<float>(neighbor_data, i); // Batch Position X
			Vector<float> batch_pos_y = new Vector<float>(neighbor_data, i + vector_length); // Batch Position Y
			Vector<float> batch_vel_x = new Vector<float>(neighbor_data, i + vector_length * 2); // Batch Velocity X
			Vector<float> batch_vel_y = new Vector<float>(neighbor_data, i + vector_length * 3); // Batch Velocity Y
			Vector<float> batch_radii = new Vector<float>(neighbor_data, i + vector_length * 4); // Batch Avoidance Radii

			// Process batch relaive positions, velocities and combined avoidance
			Vector<float> rel_pos_x = batch_pos_x - new Vector<float>(agent_pos.X); // Relative Position X
			Vector<float> rel_pos_y = batch_pos_y - new Vector<float>(agent_pos.Y); // Relative Position Y
			Vector<float> rel_vel_x = batch_vel_x - new Vector<float>(agent_lv.X); // Relative Velocity X
			Vector<float> rel_vel_y = batch_vel_y - new Vector<float>(agent_lv.Y); // Relative Velocity Y
			Vector<float> radii = batch_radii + new Vector<float>(steer_data.AvoidRadius); // Combined Avoidance Radii

			Vector<float> mag_rel_vel = (rel_vel_x * rel_vel_x) + (rel_vel_y * rel_vel_y);
			Vector<float> mag_rel_pos = (rel_pos_x * rel_pos_x) + (rel_pos_y * rel_pos_y);
			Vector<float> cone = mag_rel_vel * (mag_rel_pos - radii * radii);
			Vector<float> rel_dot = (rel_vel_x * rel_pos_x) + (rel_vel_y * rel_pos_y);
			Vector<float> sq_rel_dot = rel_dot * rel_dot;
			Vector<int> is_potential_collision = Vector.LessThan(sq_rel_dot, cone);
			if (Vector.EqualsAll(is_potential_collision, Vector<int>.Zero)) continue;

			// dynamically resize batch position x and y to filter out any invalid data
			batch_pos_x = Vector.ConditionalSelect(is_potential_collision, batch_pos_x, Vector<float>.Zero);
			batch_pos_y = Vector.ConditionalSelect(is_potential_collision, batch_pos_y, Vector<float>.Zero);
			rel_vel_x = Vector.ConditionalSelect(is_potential_collision, rel_vel_x, Vector<float>.Zero);
			rel_vel_y = Vector.ConditionalSelect(is_potential_collision, rel_vel_y, Vector<float>.Zero);
			Vector<float> valid_distances = Vector.SquareRoot((batch_pos_x * batch_pos_x) + (batch_pos_y * batch_pos_y));

			// find the most likely neighbor too collide soon
			int batch_min_idx = -1;
			float ttc = float.MaxValue;
			Vector2 neighbor_pos = Vector2.Zero;
			for (int j = 0; j < vector_length; j++)
			{
				Vector2 rel_vel = new Vector2(rel_vel_x[j], rel_vel_y[j]);
				Vector2 dir_to = Vector2.Normalize(new Vector2(rel_pos_x[j], rel_pos_y[j]));
				float closing_speed = Vector2.Dot(rel_vel, dir_to);
				if (closing_speed >= 0.0f) continue;

				float ini_dist = valid_distances[j];
				float n_ttc = ini_dist / -closing_speed;
				if (n_ttc < ttc)
				{
					ttc = n_ttc;
					batch_min_idx = j;
				}
			}

			if (batch_min_idx == -1) continue;
			if (ttc > ttc_max) continue;

			// Calculate the avoidance direction based of the neighbor's relative velocity and position with respect to the agent's desired velociy
			Vector2 avoid_rel_vel = new Vector2(rel_vel_x[batch_min_idx], rel_vel_y[batch_min_idx]);
			Vector2 avoid_rel_pos = new Vector2(rel_pos_x[batch_min_idx], rel_pos_y[batch_min_idx]);
			//Vector2 projection = new Vector2(batch_pos_x[batch_min_idx], batch_pos_y[batch_min_idx]);
			float dot = Vector2.Dot(avoid_rel_vel, avoid_rel_pos);
			float magSq = avoid_rel_pos.LengthSquared();
			Vector2 properProjection = (magSq > epsilon) ? (dot / magSq) * avoid_rel_pos : Vector2.Zero;
			//projection *= rel_dot[batch_min_idx] / mag_rel_pos[batch_min_idx];
			//Vector2 translation = steer_data.DesiredVelocity + (avoid_rel_vel - projection);
			Vector2 lateralComponent = avoid_rel_vel - properProjection;
			Vector2 properTranslation = steer_data.DesiredVelocity + lateralComponent;
			float neighbor_speed = new Vector2(batch_vel_x[batch_min_idx], batch_vel_y[batch_min_idx]).LengthSquared();

			if (neighbor_speed <= epsilon) bias_counter++;

			if (steer_data.AvoidanceBias != 0 && neighbor_speed > epsilon) continue;

			if (neighbor_speed <= epsilon && steer_data.AvoidanceBias == 0)
			{
				Vector2 desired_rel = steer_data.DesiredVelocity - avoid_rel_pos;
				float cross = avoid_rel_pos.X * desired_rel.Y - avoid_rel_pos.Y * desired_rel.X;
				steer_data.AvoidanceBias = (cross >= 0) ? -1  // Counterclockwise avoidance
														: 1; // Clockwise avoidance
				return NodeState.FAILURE;
			}
			
			if (steer_data.AvoidanceBias != 0)
			{
				properTranslation = (steer_data.AvoidanceBias > 0) ? new Vector2(-avoid_rel_vel.Y, avoid_rel_vel.X)  // Counterclockwise avoidance
												 				   : new Vector2(avoid_rel_vel.Y, -avoid_rel_vel.X); // Clockwise avoidance
			}

			Vector2 avoid_direction = Vector2.Normalize(properTranslation);
			Vector2 avoid_velocity = avoid_direction * speed;
			if (steer_data.AvoidanceBias != 0 && ttc > ttc_default && ttc < ttc_max)
			{
				//GD.Print(agent.Name, " ttc (avoidance bias != 0): ", ttc);
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_default) / (ttc_max - ttc_default), 0.0f, 1.0f);
				avoid_velocity = avoid_direction * speed * brake_weight;
				//avoid_velocity = Vector2.Normalize(avoid_rel_pos) * agent_lv.Length() * brake_weight;
			}
			else if (ttc > ttc_default && ttc < ttc_max)
			{
				//GD.Print(agent.Name, " ttc (avoidance bias == 0): ", ttc);
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_default) / (ttc_max - ttc_default), 0.0f, 1.0f);
				avoid_velocity = Vector2.Lerp(avoid_velocity, -agent_lv, brake_weight);
			}
			else if (steer_data.AvoidanceBias != 0 && ttc > ttc_min && ttc < ttc_default)
			{
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_min) / (ttc_default - ttc_min), 0.0f, 1.0f);
				avoid_velocity = avoid_direction * speed * 2.0f / brake_weight;
				//back_up_counter += bu_increment;
			}
			else if (ttc > ttc_min && ttc < ttc_default)
			{
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_min) / (ttc_default - ttc_min), 0.0f, 1.0f);
				avoid_velocity = Vector2.Lerp(Vector2.Zero, -agent_lv, brake_weight);
			}
			else if (ttc <= ttc_min)
			{
				avoid_velocity = -agent_lv / stop_coe;
			}
			time_to_collision[index] = ttc;
			avoid_velocities[index] = avoid_velocity;
			index++;
		}
		
		for (int i = remainder_start; i < neighbor_data.Length; i += batch_data_count)
		{
			// Extract individual neighbor data
			float pos_x = neighbor_data[i + 0]; // Position X
			float pos_y = neighbor_data[i + 1]; // Position Y
			float vel_x = neighbor_data[i + 2]; // Velocity X
			float vel_y = neighbor_data[i + 3]; // Velocity Y
			float radii = neighbor_data[i + 4];

			// Compute relative position and velocity
			Vector2 rel_pos = new(pos_x - agent_pos.X, pos_y - agent_pos.Y);
			Vector2 rel_vel = new(vel_x - agent_lv.X, vel_y - agent_lv.Y);
			
			// Collision avoidance logic for the individual neighbor
			float mag_rel_pos = rel_pos.LengthSquared(); // Magnitude of relative position
			float mag_rel_vel = rel_vel.LengthSquared(); // Magnitude of relative velocity
			float cone = mag_rel_vel * (mag_rel_pos - (radii + steer_data.AvoidRadius) * (radii + steer_data.AvoidRadius));
			float rel_dot = Vector2.Dot(rel_vel, rel_pos);
			float sq_rel_dot = rel_dot * rel_dot;

			if (sq_rel_dot < cone) continue; // Skip if no potential collision
			
			Vector2 dir_to = Vector2.Normalize(rel_pos);
			float closing_speed = Vector2.Dot(rel_vel, dir_to);
			if (closing_speed >= 0.0f) continue;

			float ini_dist = Vector2.Distance(agent_pos, new Vector2(pos_x, pos_y));
			float ttc = ini_dist / -closing_speed;
			if (ttc > ttc_max) continue;

			float dot = Vector2.Dot(rel_vel, rel_vel);
			float magSq = rel_pos.LengthSquared();
			Vector2 properProjection = (magSq > epsilon) ? (dot / magSq) * rel_pos : Vector2.Zero;
			//Vector2 projection = rel_pos * (rel_dot / mag_rel_pos); // Project velocity
			//Vector2 translation = steer_data.DesiredVelocity + (rel_vel - projection);
			Vector2 properTranslation = steer_data.DesiredVelocity + properProjection;
			float neighbor_speed = new Vector2(vel_x, vel_y).LengthSquared();

			if (neighbor_speed <= epsilon) bias_counter++;

			if (steer_data.AvoidanceBias != 0 && neighbor_speed > epsilon) continue;

			if (neighbor_speed <= epsilon && steer_data.AvoidanceBias == 0)
			{
				float cross = rel_pos.X * rel_vel.Y - rel_pos.Y * rel_vel.X;
				steer_data.AvoidanceBias = (cross >= 0) ? 1  // Counterclockwise avoidance
												 		: -1;
				return NodeState.FAILURE;
			}
			
			if (steer_data.AvoidanceBias != 0)
			{
				properTranslation = (steer_data.AvoidanceBias > 0) ? new Vector2(-rel_vel.Y, rel_vel.X)  // Counterclockwise avoidance
												 				   : new Vector2(rel_vel.Y, -rel_vel.X);
			}

			Vector2 avoid_direction = Vector2.Normalize(properTranslation);
			Vector2 avoid_velocity = avoid_direction * speed;
			if (steer_data.AvoidanceBias != 0 && ttc > ttc_default && ttc < ttc_max)
			{
				//GD.Print(agent.Name, " ttc (avoidance bias != 0): ", ttc);
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_default) / (ttc_max - ttc_default), 0.0f, 1.0f);
				avoid_velocity = avoid_direction * speed * brake_weight;
			}
			else if (ttc > ttc_default && ttc < ttc_max)
			{
				//GD.Print(agent.Name, " ttc (avoidance bias == 0): ", ttc);
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_default) / (ttc_max - ttc_default), 0.0f, 1.0f);
				avoid_velocity = Vector2.Lerp(avoid_velocity, -agent_lv, brake_weight);
			}
			else if (steer_data.AvoidanceBias != 0 && ttc > ttc_min && ttc < ttc_default)
			{
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_min) / (ttc_default - ttc_min), 0.0f, 1.0f);
				avoid_velocity = avoid_direction * speed * 2.0F / brake_weight;
				//back_up_counter += bu_increment;
			}
			else if (ttc > ttc_min && ttc < ttc_default)
			{
				float brake_weight = 1.0f - Mathf.Clamp((ttc - ttc_min) / (ttc_default - ttc_min), 0.0f, 1.0f);
				avoid_velocity = Vector2.Lerp(Vector2.Zero, -agent_lv, brake_weight);
			}
			else if (ttc <= ttc_min)
			{
				avoid_velocity = -agent_lv / stop_coe;
			}

			time_to_collision[index] = ttc;
			avoid_velocities[index] = avoid_velocity; // Store the computed avoidance velocity
			index++;
		}
		
		if (steer_data.AvoidanceBias != 0 && bias_counter == 0)
		{
			GD.Print(agent.Name, " avoidance bias no longer applied");
			steer_data.AvoidanceBias = 0;
		}

		if (index == 0)
		{
			steer_data.AvoidanceWeight = 0.0f;
			steer_data.GoalWeight = 1.0f;
			agent.Set("acceleration", new Godot.Vector2(steering_force.X, steering_force.Y));
			return NodeState.FAILURE;
		}

		Array.Resize(ref time_to_collision, index);
		Array.Resize(ref avoid_velocities, index);
		
		float local_ttc_min = float.MaxValue;
		index = 0;
		foreach (float ttc in time_to_collision)
		{
			if (ttc < local_ttc_min)
			{
				local_ttc_min = ttc;
			}
			index++;
		}

		if (local_ttc_min == 0.0f)
		{
			steer_data.AvoidanceWeight = 0.0f;
			steer_data.GoalWeight = 1.0f;
			agent.Set("acceleration", new Godot.Vector2(steering_force.X, steering_force.Y));
			return NodeState.FAILURE;
		}
		
		index = 0;
		Vector2 aggregate_vel = Vector2.Zero;
		float avoidance_weight = 0.0f;
		foreach (float ttc in time_to_collision)
		{
			float weight = local_ttc_min / (ttc + epsilon);
			aggregate_vel += avoid_velocities[index] * weight;
			avoidance_weight += weight;
			index++;
		}
		
		avoidance_weight /= index;
		if (bias_counter == 0 && ship_wrapper.CombatFlag == false)
		{
			avoidance_weight = Mathf.Clamp(avoidance_weight, 0.0f, 1.0f);
			steer_data.SeparationWeight = Mathf.Lerp(steer_data.SeparationWeight, 0.1f, lerp_weight * 2.0f);
			steer_data.GoalWeight = Mathf.Lerp(steer_data.GoalWeight, 0.1f, lerp_weight / 2.0f);
		}
		else if (ship_wrapper.CombatFlag == true)
		{
			avoidance_weight = 1.0f;
			steer_data.SeparationWeight = 10.0f;
			steer_data.GoalWeight = 1.0f;
		}
		else
		{
			steer_data.SeparationWeight = 0.01f;
			steer_data.GoalWeight = 0.01f;
		}
		
		steer_data.AvoidanceForce = aggregate_vel;
		steer_data.AvoidanceWeight = avoidance_weight;
		steering_force = steer_data.SteeringForce;
		agent.Set("acceleration", new Godot.Vector2(steering_force.X, steering_force.Y));
		return NodeState.FAILURE;
	}
	
}
