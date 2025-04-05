using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime;
using Vector2 = System.Numerics.Vector2;

public partial class ChooseTarget : Action
{
	float snap_target = 0.1f;
	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		steer_data = (SteerData)agent.Get("SteerData");
        
		if (ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true || ship_wrapper.VentFluxFlag == true)
		{
			return NodeState.FAILURE;
		}

		if (steer_data.TargetUnit != null || ship_wrapper.TargetedUnits.Count == 0)
		{
			return NodeState.FAILURE;
		}
		
		Godot.Vector2 agent_pos = (Godot.Vector2)agent.Get("global_position");
		Godot.Collections.Dictionary<float, Godot.Collections.Array<int>> weigh_targets = new Godot.Collections.Dictionary<float, Godot.Collections.Array<int>>();
		List<RigidBody2D> evaluate_targets = new List<RigidBody2D>();
		List<RigidBody2D> available_targets = new List<RigidBody2D>();
		List<float> sq_dist = new List<float>();
		foreach (RigidBody2D target in ship_wrapper.TargetedUnits)
		{
			if (target == null) continue;
			ShipWrapper target_wrapper = (ShipWrapper)target.Get("ShipWrapper");
			float prob = (float)agent.Call("generate_combat_probability", target);
			if (weigh_targets.ContainsKey(prob) == false)
			{
				weigh_targets[prob] = new Godot.Collections.Array<int>();
			}
			weigh_targets[prob].Append(target.GetIndex());
		   
			Godot.Vector2 target_pos = (Godot.Vector2)target.Get("global_position");
			float dist = agent_pos.DistanceSquaredTo(target_pos);
			sq_dist.Add(dist);
			if (target_wrapper.TargetedBy.Count == 0)
			{
				available_targets.Add(target);
			}
			else
			{
				evaluate_targets.Add(target);
			}
		}
		
		foreach (Node2D weapon in ship_wrapper.AllWeapons)
		{
			weapon.Set("weighted_targets", weigh_targets);
		}

		if (evaluate_targets.Count == 0 & available_targets.Count == 0)
		{
			return NodeState.FAILURE;
		}
		
		float min_distance = sq_dist.Min();

		foreach (RigidBody2D target in evaluate_targets)
		{
			ShipWrapper target_wrapper = (ShipWrapper)target.Get("ShipWrapper");
			Godot.Vector2 target_pos = (Godot.Vector2)target.Get("global_position");
			float final_weight = 0.0f;
			foreach (RigidBody2D attacker in target_wrapper.TargetedBy)
			{
				if (attacker == null) continue;
				if (attacker == agent & steer_data.TargetUnit == null)
				{
					steer_data.TargetUnit = target;
					ship_wrapper.TargetUnit = target;
					return NodeState.FAILURE;
				}
				ShipWrapper attacker_wrapper = (ShipWrapper)attacker.Get("ShipWrapper");
				float agent_inf = Math.Abs(attacker_wrapper.ApproxInfluence);
				float target_inf = Math.Abs(target_wrapper.ApproxInfluence);
				float threat_weight = agent_inf / (agent_inf + target_inf);
				float flux_weight = (target_wrapper.SoftFlux + target_wrapper.HardFlux) / target_wrapper.TotalFlux;
				float weapon_weight = target_wrapper.AllWeapons.Count / attacker_wrapper.AllWeapons.Count;
				Godot.Vector2 attacker_pos = (Godot.Vector2)attacker.Get("global_position");
				float dist_weight = min_distance / attacker_pos.DistanceSquaredTo(target_pos);
				final_weight += (threat_weight + flux_weight + dist_weight + weapon_weight) / 4.0f;
			}
			if (final_weight < 1.0f) available_targets.Add(target);
		}

		if (available_targets.Count == 0) 
		{
			return NodeState.FAILURE;
		}
		Dictionary<float, RigidBody2D> weighted_targets = new Dictionary<float, RigidBody2D>();
		foreach (RigidBody2D target in available_targets)
		{
			ShipWrapper target_wrapper = (ShipWrapper)target.Get("ShipWrapper");
			Godot.Vector2 target_pos = (Godot.Vector2)target.Get("global_position");
			float agent_inf = Math.Abs(ship_wrapper.ApproxInfluence);
			float target_inf = Math.Abs(target_wrapper.ApproxInfluence);
			float threat_weight = agent_inf / (agent_inf + target_inf);
			float flux_weight = (target_wrapper.SoftFlux + target_wrapper.HardFlux) / target_wrapper.TotalFlux;
			float weapon_weight = target_wrapper.AllWeapons.Count / ship_wrapper.AllWeapons.Count;
			float dist_weight = min_distance / agent_pos.DistanceSquaredTo(target_pos);
			float prob = (threat_weight + flux_weight + dist_weight + weapon_weight) / 4.0f;
			float snap = (float)Math.Round(prob / snap_target) * snap_target;
			if (snap < 0.5f) continue;
			weighted_targets[prob] = target;
		}

		RigidBody2D n_target = null;
		if (weighted_targets.Keys.Count == 0)
		{
			int rand_int = (int)GD.Randi() % available_targets.Count - 1;
			n_target = available_targets[rand_int];
		}
		else
		{
			float max_prob = weighted_targets.Keys.Max();
			n_target = weighted_targets[max_prob];
		}

		ShipWrapper n_target_wrapper = (ShipWrapper)n_target.Get("ShipWrapper");
		steer_data.TargetUnit = n_target;
		ship_wrapper.TargetUnit = n_target;
		n_target_wrapper.TargetedBy.Add((RigidBody2D)agent);
		agent.Call("set_target_for_weapons", n_target);
		return NodeState.FAILURE; 
	}

}
