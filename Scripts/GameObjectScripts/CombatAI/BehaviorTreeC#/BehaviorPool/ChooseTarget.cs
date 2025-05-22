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
		if (ship_wrapper.TargetedUnits.Count == 0 || ship_wrapper.FallbackFlag == true || ship_wrapper.RetreatFlag == true || ship_wrapper.VentFluxFlag == true)
		{
			return NodeState.FAILURE;
		}

		steer_data = (SteerData)agent.Get("SteerData");
		if (IsInstanceValid(steer_data.TargetUnit) && IsInstanceValid(ship_wrapper.TargetUnit))
		{
			return NodeState.FAILURE;
		}

		if (steer_data.TargetUnit is not null && ship_wrapper.TargetUnit is not null)
		{
			return NodeState.FAILURE;
		}
		
		RigidBody2D n_agent = agent as RigidBody2D;
		Godot.Vector2 agent_pos = n_agent.GlobalPosition;
		Godot.Collections.Dictionary<float, Godot.Collections.Array<Rid>> weigh_targets = new Godot.Collections.Dictionary<float, Godot.Collections.Array<Rid>>();
		Godot.Collections.Array<RigidBody2D> valid_targets = new Godot.Collections.Array<RigidBody2D>();
		//List<RigidBody2D> evaluate_targets = new List<RigidBody2D>();
		List<RigidBody2D> available_targets = new List<RigidBody2D>();
		List<float> sq_dist = new List<float>();
		foreach (RigidBody2D target in ship_wrapper.TargetedUnits)
		{
			if (!IsInstanceValid(target) || target.IsQueuedForDeletion()) 
			{
				GD.Print("target disposed or in queue for deletion");
				continue;
			}
			valid_targets.Add(target);
			//ShipWrapper target_wrapper = (ShipWrapper)target.Get("ShipWrapper");
			float prob = (float)agent.Call("generate_combat_probability", target);

			if (!weigh_targets.ContainsKey(prob))
			{
				weigh_targets[prob] = new Godot.Collections.Array<Rid>();
			}
			weigh_targets[prob].Add(target.GetRid());

			Godot.Vector2 target_pos = target.GlobalPosition;
			float dist = agent_pos.DistanceSquaredTo(target_pos);
			sq_dist.Add(dist);
			available_targets.Add(target);
			/*
			if (target_wrapper.TargetedBy is null || target_wrapper.TargetedBy.Count == 0)
			{
				available_targets.Add(target);
			}
			else
			{
				evaluate_targets.Add(target);
			}
			*/
		}
		
		foreach (Node2D weapon in ship_wrapper.AllWeapons)
		{
			weapon.Set("weighted_targets", weigh_targets);
		}

		/*
		if (evaluate_targets.Count == 0 & available_targets.Count == 0)
		{
			return NodeState.FAILURE;
		}
		*/

		if (available_targets.Count == 0)
		{
			return NodeState.FAILURE;
		}
		
		float min_distance = sq_dist.Min();
		
		/*
		foreach (RigidBody2D target in evaluate_targets)
		{
			if (!valid_targets.Contains(target)) continue;
			ShipWrapper target_wrapper = (ShipWrapper)target.Get("ShipWrapper");
			Godot.Vector2 target_pos = (Godot.Vector2)target.Get("global_position");
			float final_weight = 0.0f;
			foreach (RigidBody2D attacker in target_wrapper.TargetedBy)
			{
				if (!IsInstanceValid(attacker)|| attacker.IsQueuedForDeletion()) continue;
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
			if (final_weight < 3.0f) available_targets.Add(target);
		}
		*/
		Dictionary<float, RigidBody2D> weighted_targets = new Dictionary<float, RigidBody2D>();
		foreach (RigidBody2D target in available_targets)
		{
			if (!valid_targets.Contains(target)) continue;
			ShipWrapper target_wrapper = (ShipWrapper)target.Get("ShipWrapper");
			Godot.Vector2 target_pos = (Godot.Vector2)target.Get("global_position");
			float agent_inf = Math.Abs(ship_wrapper.ApproxInfluence);
			float target_inf = Math.Abs(target_wrapper.ApproxInfluence);
			float threat_weight = agent_inf / (agent_inf + target_inf);
			float flux_weight = ship_wrapper.TotalFlux / target_wrapper.TotalFlux;
			float threat_modifier = target_wrapper.AllWeapons.Count / ship_wrapper.AllWeapons.Count;
			float dist_weight = min_distance / agent_pos.DistanceSquaredTo(target_pos);
			float prob = (threat_weight + flux_weight + dist_weight) / (3.0f * threat_modifier);
			//float snap = (float)Math.Round(prob / snap_target) * snap_target;
			//if (snap < 0.5f) continue;
			weighted_targets[prob] = target;
		}

		RigidBody2D n_target;
		/*
		if (weighted_targets.Count == 0)
		{
			int rand_int = GD.RandRange(0, ship_wrapper.TargetedUnits.Count - 1);
			n_target = ship_wrapper.TargetedUnits[rand_int];
		}
		else
		{
			float max_prob = weighted_targets.Keys.Max();
			n_target = weighted_targets[max_prob];
		}
		*/
		float max_prob = weighted_targets.Keys.Max();
		n_target = weighted_targets[max_prob];
		
		//GD.Print(agent.Name, " targeting ", n_target.Name);
		if (!IsInstanceValid(n_target) || n_target is null) return NodeState.FAILURE;
		if (valid_targets.Count < ship_wrapper.TargetedUnits.Count)
		{
			GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", valid_targets);
			GD.Print("tried to set valid targets");
			return NodeState.FAILURE;
		}
		agent.Set("target_in_range", true);
		Godot.Collections.Array<RigidBody2D> targeted_by = (Godot.Collections.Array<RigidBody2D>)n_target.Get("targeted_by");
		steer_data.TargetUnit = n_target;
		ship_wrapper.TargetUnit = n_target;
		targeted_by.Add(n_agent);
		agent.Set("target_unit", new Godot.Collections.Array<int>());
		n_target.Set("targeted_by", targeted_by);
		agent.Call("set_target_for_weapons", new Godot.Collections.Array<int>());
		return NodeState.FAILURE; 
	}

}
