using Godot;
using System;
using System.Collections.Generic;
public partial class ChooseStrategy : Action
{
	public override NodeState Tick(Node agent)
	{
		if (Engine.GetPhysicsFrames() % 240 != 0)
			return NodeState.FAILURE;
        
		Godot.Collections.Array<Node> available_agents = GetTree().GetNodesInGroup("agent");
		float admiral_strength = 0.0f;
		float player_strength = 0.0f;

		foreach (Node unit in available_agents)
		{
			float influence = (float)unit.Get("approx_influence");

			if (influence < 0.0f)
				admiral_strength += influence;
			else
				player_strength += influence;
		}

		float relative_strength = admiral_strength + player_strength;

		Admiral admiral = agent as Admiral; 
		if (relative_strength < 0)
			admiral.Set("heuristic_strat", (int)Globals.Strategy.OFFENSIVE);
		else if (relative_strength > 0)
			admiral.Set("heuristic_strat", (int)Globals.Strategy.DEFENSIVE);

		admiral.Set("admiral_strength", admiral_strength);
		admiral.Set("player_strength", player_strength);

		return NodeState.FAILURE;
	}
}