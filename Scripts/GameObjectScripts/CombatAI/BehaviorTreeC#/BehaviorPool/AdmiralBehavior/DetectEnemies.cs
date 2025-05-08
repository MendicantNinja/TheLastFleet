using Godot;
using System;
using System.Collections.Generic;

public partial class DetectEnemies : Action
{
    public override NodeState Tick(Node agent)
    {
        if (Engine.GetPhysicsFrames() % 120 != 0) return NodeState.FAILURE;

        Admiral admiral = agent as Admiral;
        Godot.Collections.Array<Node> player_presence = GetTree().GetNodesInGroup("friendly");
        Godot.Collections.Array<Node> unit_presence = GetTree().GetNodesInGroup("enemy");
        if (player_presence.Count == 0 || unit_presence.Count == 0) return NodeState.SUCCESS;

        List<Vector2I> unit_clusters = new List<Vector2I>();
        List<Vector2I> player_clusters = new List<Vector2I>();
        foreach (Vector2I cell in ImapManager.Instance.RegistryMap.Keys)
        {
            List<RigidBody2D> agent_registry = ImapManager.Instance.RegistryMap[cell];
            foreach (RigidBody2D unit in agent_registry)
            {
                bool is_friendly = (bool)unit.Get("is_friendly");
                if (is_friendly == false && !unit_clusters.Contains(cell))
                {
                    unit_clusters.Add(cell);
                }
                else if (!player_clusters.Contains(cell))
                {
                    player_clusters.Add(cell);
                }
            }
        }
        
        admiral.PlayerClusters = player_clusters;
        admiral.UnitClusters = unit_clusters;

        return NodeState.FAILURE;
    }
}
