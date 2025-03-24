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

		}

		//var successful_deploy = (bool)agent.Get("successful_deploy");
		var group_leader = (bool)agent.Get("group_leader");
		if (group_leader && Engine.GetPhysicsFrames() % 720 == 0 && (bool)agent.Get("successful_deploy") == false)
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

		//var target_unit = (Node)agent.Get("target_unit");
		var target_position = (Vector2)agent.Get("target_position");
		if ((Node)agent.Get("target_unit") != null || target_position == Vector2.Zero)
		{
			return NodeState.SUCCESS;
		}

		if (group_leader == true && target_position != Vector2.Zero)
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
