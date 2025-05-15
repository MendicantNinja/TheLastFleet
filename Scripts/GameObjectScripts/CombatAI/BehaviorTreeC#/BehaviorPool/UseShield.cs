using Godot;
using System;

public partial class UseShield : Action
{
	float overload_thresh = 0.9f;
	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		
		if (ship_wrapper.VentFluxFlag == true | ship_wrapper.FluxOverload == true)
		{
			return NodeState.FAILURE;
		}
		
		if (ship_wrapper.ShieldFlag == true && ship_wrapper.CombatFlag == false)
		{
			agent.Call("set_shields", false);
		}

		float flux_norm = (ship_wrapper.SoftFlux + ship_wrapper.HardFlux) / ship_wrapper.TotalFlux;
		if (flux_norm >= overload_thresh)
		{
			agent.Call("set_shields", false);
		}

		if (ship_wrapper.CombatFlag == true && ship_wrapper.ShieldFlag == false && flux_norm < overload_thresh)
		{
			agent.Call("set_shields", true);
		}

		return NodeState.FAILURE;
	}

}
