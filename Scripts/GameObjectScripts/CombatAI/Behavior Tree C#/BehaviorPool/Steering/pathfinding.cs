using Godot;
using System;
using System.Net;

public partial class Pathfinding : LeafAction
{

	public override NodeState Tick(Node agent)
	{
		if (steer_data == null)
		{
			steer_data = new SteerData();
			steer_data.Initialize(agent);
			steer_data.SetDelta(GetPhysicsProcessDeltaTime());
			ship_wrapper = new ShipWrapper();
		}
		
		if (ship_wrapper.GroupLeader && Engine.GetPhysicsFrames() % 720 == 0 && ship_wrapper.SuccessfulDeploy)
		{
			var group_name = (StringName)agent.Get("group_name");
			var group_count = (int)GetTree().GetNodeCountInGroup(group_name);
			if (group_count == 1)
			{
				agent.Call("group_remove", group_name);
				agent.EmitSignal("ships_deployed");
				return NodeState.SUCCESS;
			}
		}

		if (ship_wrapper.TargetUnit != null || steer_data.TargetPosition != Vector2.Zero)
		{
			return NodeState.SUCCESS;
		}

		if (ship_wrapper.GroupLeader && steer_data.TargetPosition != Vector2.Zero)
		{
			var globals = (Node)GetTree().Root.GetNode("globals");
			globals.Call("generate_group_target_position", agent);
			var ShipNavigationPosition = (NavigationAgent2D)agent.Get("ShipNavigationAgent");
			var current_position = (Vector2)agent.Get("global_position");
			ShipNavigationPosition.Call("set_target_position", current_position);
		}
		return NodeState.FAILURE;
	}
}
