using Godot;
using Vector2 = System.Numerics.Vector2;
public partial class Fallback : Action
{
	float hystersis_buffer = 2.0f;
	float throttle_lv = 0.1f;
	int epsilon = 1;
	public override NodeState Tick(Node agent)
	{
		ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		SteerData steer_data = (SteerData)agent.Get("SteerData");

		if (ship_wrapper.FallbackFlag == false || ship_wrapper.VentFluxFlag == false)
		{
			return NodeState.FAILURE;
		}

		float speed = steer_data.DefaultAcceleration;
		if (ship_wrapper.SoftFlux + ship_wrapper.HardFlux == 0.0f)
		{
			speed += steer_data.ZeroFluxBonus;
		}

		Vector2 move_direction;
		RigidBody2D n_agent = agent as RigidBody2D;
		move_direction = new Vector2(n_agent.Transform.X.X, n_agent.Transform.X.Y);
		if (ship_wrapper.CombatFlag == true)
		{
			steer_data.DesiredVelocity = -move_direction * speed;
		}
		else if (ship_wrapper.CombatFlag == false && n_agent.LinearVelocity.Length() > epsilon)
		{
			Vector2 velocity = Vector2.Normalize(-move_direction) * speed;
			velocity -= new Vector2(n_agent.LinearVelocity.X, n_agent.LinearVelocity.Y);
			velocity /= throttle_lv;
			steer_data.DesiredVelocity = velocity;
		}

		return NodeState.FAILURE;
	}

}
