using System;
using System.Collections.Generic;
using Godot;
using Vector2 = System.Numerics.Vector2;

public partial class Pathfinding : Action
{
	public override NodeState Tick(Node agent)
	{
		ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
		if (steer_data == null)
		{
			steer_data = (SteerData)agent.Get("SteerData");
			steer_data.SetDelta(GetPhysicsProcessDeltaTime());
			steer_data.Initialize(agent);
			Godot.Collections.Array all_weapons = (Godot.Collections.Array)agent.Get("all_weapons");
			ship_wrapper.SetAllWeapons(all_weapons);
			ship_wrapper.TargetedBy = new List<RigidBody2D>();
		}
		steer_data = (SteerData)agent.Get("SteerData");

		if (steer_data.TargetUnit != null || steer_data.TargetPosition == Vector2.Zero)
		{
			return NodeState.SUCCESS;
		}
		else if (steer_data.GoalWeight <= 0.001f) steer_data.GoalWeight = 1.0f;
		
		if (ship_wrapper.GroupLeader == true && Engine.GetPhysicsFrames() % 720 == 0 && ship_wrapper.SuccessfulDeploy == false)
		{
			string group_name = ship_wrapper.GroupName;
			int group_count = GetTree().GetNodeCountInGroup(group_name);
			if (group_count == 1)
			{
				agent.Call("group_remove", group_name);
				agent.EmitSignal("ships_deployed");
				return NodeState.SUCCESS;
			}
		}

		if (ship_wrapper.GroupLeader == true)
		{
			NavigationAgent2D ShipNavigationAgent = (NavigationAgent2D)agent.Get("ShipNavigationAgent");
			if (ShipNavigationAgent.IsNavigationFinished() == false)
			{
				Node globals = GetTree().Root.GetNode("globals");
				globals.Call("generate_group_target_positions", agent);
				ShipNavigationAgent.SetTargetPosition((Godot.Vector2)agent.Get("global_position"));
			}
		}
		return NodeState.FAILURE;
	}
}
