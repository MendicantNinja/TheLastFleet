using Godot;

public partial class Escape : Action
{
	float time = 0.0f;
	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");

		if (ship_wrapper.FallbackFlag == false || ship_wrapper.RetreatFlag == false)
		{
			time = 0.0f;
			return NodeState.FAILURE;
		}

		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}

		RigidBody2D n_agent = agent as RigidBody2D;
		if (n_agent.LinearVelocity.Length() < speed)
		{
			time += steer_data.NDelta + steer_data.TimeCoefficient;
		}

		
		if (speed * time > speed)
		{
			time = 1.0f;
		}

		steer_data.DesiredVelocity = steer_data.MoveDirection * speed * time;
		steer_data.Time = time;
		return NodeState.FAILURE;
	}

}
