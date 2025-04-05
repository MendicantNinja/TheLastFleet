using Godot;
using Godot.Collections;

public partial class VelocityMatching : Action
{
	public override NodeState Tick(Node agent)
	{
		if (Engine.GetPhysicsFrames() % 120 != 0) return NodeState.FAILURE;

		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		
		if (ship_wrapper.Posture == ShipWrapper.Strategy.OFFENSIVE || ship_wrapper.Posture == ShipWrapper.Strategy.EVASIVE) 
		{
			return NodeState.FAILURE;
		}
		else if (string.IsNullOrEmpty(ship_wrapper.GroupName) == true)
		{
			return NodeState.FAILURE;
		}

		if (ship_wrapper.CombatFlag == false && ship_wrapper.FallbackFlag == false && ship_wrapper.RetreatFlag == false && ship_wrapper.VentFluxFlag)
		{
			agent.Set("match_velocity_flag", true);
		}

		Array<Node> group = GetTree().GetNodesInGroup(ship_wrapper.GroupName);
		foreach (Node unit in group)
		{
			RigidBody2D n_unit = unit as RigidBody2D;
			if (n_unit == null) continue;
			ShipWrapper unit_wrapper = (ShipWrapper)n_unit.Get("ShipWrapper");
			if (unit_wrapper.CombatFlag == true)
			{
				agent.Set("match_velocity_flag", false);
				break;
			}
		}

		if (ship_wrapper.MatchVelocityFlag == false) return NodeState.FAILURE;
		Array<float> group_speeds = new Array<float>();
		foreach (Node unit in group)
		{
			if (unit == null) continue;
			SteerData unit_data = (SteerData)unit.Get("SteerData");
			ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
			float speed = unit_data.DefaultAcceleration;
			if (unit_wrapper.SoftFlux + unit_wrapper.HardFlux == 0.0f) speed += unit_data.ZeroFluxBonus;
			group_speeds.Add(speed);
		}

		agent.Set("match_speed", group_speeds.Min());
		return NodeState.FAILURE;
	}

}
