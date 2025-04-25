using Godot;
using System;

public partial class ThreatDetection : Action
{
    string true_name = "";
    string tmp_name = "threat detect ";

    public override NodeState Tick(Node agent)
    {
        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
        SteerData steer_data = (SteerData)agent.Get("SteerData");

        // You will need to know this is how we currently access globals
        // Node globals = GetTree().Root.GetNode("globals");
        // Call its functions like this
	    // globals.Call("generate_group_target_positions", agent);


        return NodeState.FAILURE;
    }

}
