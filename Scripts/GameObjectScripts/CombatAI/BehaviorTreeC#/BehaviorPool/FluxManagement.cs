using Godot;
using System;
using Vector2 = System.Numerics.Vector2;
public partial class FluxManagement : Action
{
	float offense_threshold = 0.8f;
	float def_neut_threshold = 0.7f;
	float evasive_threshold = 0.5f;
	bool vent_flux = false;

	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");
		
		float flux_norm = (ship_wrapper.SoftFlux + ship_wrapper.HardFlux) / ship_wrapper.TotalFlux;

		if (ship_wrapper.CombatFlag == false && flux_norm > 0.0f && ship_wrapper.VentFluxFlag == false)
		{
			ship_wrapper.SetVentFluxFlag(true);
			agent.Set("vent_flux_flag", ship_wrapper.VentFluxFlag);
			foreach (Node2D weapon in ship_wrapper.AllWeapons)
			{
				weapon.Set("vent_flux", ship_wrapper.VentFluxFlag);
			}
		}

		if ((ship_wrapper.SoftFlux + ship_wrapper.HardFlux) == 0.0f && vent_flux == true && ship_wrapper.FallbackFlag == true)
		{
			vent_flux = false;
			agent.Set("vent_flux_flag", vent_flux);
			agent.Set("fallback_flag", vent_flux);
			steer_data.MoveDirection = Vector2.Zero;
		}

		if (vent_flux == true && flux_norm == 0.0f)
		{
			vent_flux = false;
		}

		if ((ship_wrapper.Posture == Globals.Strategy.NEUTRAL | ship_wrapper.Posture == Globals.Strategy.DEFENSIVE) && flux_norm >= def_neut_threshold)
		{
			vent_flux = true;
		}
		else if (ship_wrapper.Posture == Globals.Strategy.OFFENSIVE && flux_norm >= offense_threshold)
		{
			vent_flux = true;
		}
		else if (ship_wrapper.Posture == Globals.Strategy.EVASIVE && flux_norm >= evasive_threshold)
		{
			vent_flux = true;
		}

		RigidBody2D n_agent = agent as RigidBody2D;
		if (vent_flux == true && ship_wrapper.CombatFlag == true && ship_wrapper.FallbackFlag == false)
		{
			ship_wrapper.Set("fallback_flag", vent_flux);
			Vector2 transform_x = new Vector2(n_agent.Transform.X.X, n_agent.Transform.Y.Y);
			steer_data.MoveDirection = -transform_x;
		}

		if (vent_flux == true && ship_wrapper.CombatFlag == true && steer_data.TargetUnit != null)
		{
			ShipWrapper target_wrapper = (ShipWrapper)steer_data.TargetUnit.Get("ShipWrapper");
			target_wrapper.TargetedBy.Remove(n_agent);
			steer_data.TargetUnit = null;
			agent.Call("set_target_for_weapons", steer_data.TargetUnit);
		}

		return NodeState.FAILURE;
	}


}
