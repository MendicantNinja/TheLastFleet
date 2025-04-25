using Godot;
using System;
using System.Collections.Generic;

public partial class IdentifyNearbyUnits : Action
{
    public override NodeState Tick(Node agent)
    {

        SteerData steer_data = (SteerData)agent.Get("SteerData");
        ShipWrapper ship_wrapper = (ShipWrapper) agent.Get("ShipWrapper");

        
        List<string> nearby_enemy_groups = new List<string>();
        List<RigidBody2D> idle_neighbors = new List<RigidBody2D>();
        List<string> neighbor_groups = new List<string>();

        foreach (Vector2I cell in ship_wrapper.RegistryNeighborhood)
        {
            if (ImapManager.Instance.RegistryMap.ContainsKey(cell)) continue;
            // finish loop
        }

        foreach (RigidBody2D unit in ship_wrapper.TargetedBy)
        {
            // finish loop here
        }

    
        // all the "nearby" "idle" etc stuff should already exist in the ShipWrapper
        return NodeState.FAILURE;
    }

}
