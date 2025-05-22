using Godot;

public partial class Escape : Action
{
	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");

		if (ship_wrapper.FallbackFlag == false || ship_wrapper.RetreatFlag == false)
		{
			return NodeState.FAILURE;
		}

		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}

		steer_data.DesiredVelocity = steer_data.MoveDirection * speed;
		return NodeState.FAILURE;
	}

}
