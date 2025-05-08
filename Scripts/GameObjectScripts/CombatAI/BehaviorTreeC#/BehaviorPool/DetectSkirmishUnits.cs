using Godot;
using Globals;
using InfluenceMap;
using System;
using System.Collections.Generic;
using System.Linq;

// A struct that wraps a Vector2I array and implements value-based equality.
public struct ClusterKey : IEquatable<ClusterKey>
{
    public Vector2I[] Cells;

    public ClusterKey(Vector2I[] cells)
    {
        Cells = cells;
    }

    public bool Equals(ClusterKey other)
    {
        if (Cells == null || other.Cells == null)
            return Cells == other.Cells;
        if (Cells.Length != other.Cells.Length)
            return false;

        for (int i = 0; i < Cells.Length; i++)
        {
            if (!Cells[i].Equals(other.Cells[i]))
                return false;
        }
        return true;
    }

    public override bool Equals(object obj)
    {
        if (obj is ClusterKey)
            return Equals((ClusterKey)obj);
        return false;
    }

    public override int GetHashCode()
    {
        if (Cells == null)
            return 0;

        int hash = 17;
        foreach (var cell in Cells)
        {
            hash = hash * 31 + cell.GetHashCode();
        }
        return hash;
    }
}

public partial class DetectSkirmishUnits : Action
{
    public override NodeState Tick(Node agent)
    {
        // Run logic once every 65 physics frames
        if (Engine.GetPhysicsFrames() % 65 != 0)
            return NodeState.SUCCESS;

        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");

        if (ship_wrapper.CombatGoal != (int)Goal.SKIRMISH ||
            string.IsNullOrEmpty(ship_wrapper.GroupName) ||
            (ship_wrapper.RegistryCell.X < 0 && ship_wrapper.RegistryCell.Y < 0))
        {
            return NodeState.SUCCESS;
        }

        // Already has targets or goal flag set
        if (ship_wrapper.TargetedUnits.Count > 0 || ship_wrapper.GoalFlag)
            return NodeState.SUCCESS;

        Node globals = GetTree().Root.GetNode("globals");

        // Calculate our group average strength and geometric median position.
        float group_strength = 0.0f;
        Godot.Collections.Array group_positions = new Godot.Collections.Array();
        foreach (RigidBody2D unit in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
        {
            if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion())
                continue;

            ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
            group_strength += unit_wrapper.ApproxInfluence;
            group_positions.Add(unit.GlobalPosition);
        }
        Godot.Vector2 group_geo_median = (Godot.Vector2)globals.Call("geometric_median_of_objects", group_positions);

        // Gather friendly units and registry cells.
        Godot.Collections.Array player_registry_cells = new Godot.Collections.Array();
        Godot.Collections.Array player_agents = (Godot.Collections.Array)GetTree().GetNodesInGroup("friendly");

        // Use ClusterKey (instead of raw arrays) to index clusters.
        Dictionary<ClusterKey, Godot.Collections.Array<RigidBody2D>> registry_cluster =
            new Dictionary<ClusterKey, Godot.Collections.Array<RigidBody2D>>();

        foreach (RigidBody2D unit in player_agents)
        {
            if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion())
                continue;

            ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
            if (unit_wrapper.RegistryCell.X < 0 || unit_wrapper.RegistryCell.Y < 0)
                continue;

            if (!player_registry_cells.Contains(unit_wrapper.RegistryCell))
                player_registry_cells.Add(unit_wrapper.RegistryCell);

            ClusterKey key = new ClusterKey(unit_wrapper.RegistryCluster);
            if (!registry_cluster.ContainsKey(key))
                registry_cluster[key] = new Godot.Collections.Array<RigidBody2D>();

            registry_cluster[key].Add(unit);
        }

        if (player_registry_cells.Count == 0)
            return NodeState.SUCCESS;

        // For each cluster, calculate its aggregated strength and geographic median.
        Dictionary<ClusterKey, float> target_strength = new Dictionary<ClusterKey, float>();
        Dictionary<ClusterKey, Godot.Vector2> target_geo_median = new Dictionary<ClusterKey, Godot.Vector2>();

        foreach (KeyValuePair<ClusterKey, Godot.Collections.Array<RigidBody2D>> pair in registry_cluster)
        {
            ClusterKey cluster = pair.Key;
            Godot.Collections.Array<RigidBody2D> agents_in_cluster = pair.Value;
            float relative_strength = 0.0f;
            Godot.Collections.Array unit_positions = new Godot.Collections.Array();

            foreach (RigidBody2D unit in agents_in_cluster)
            {
                if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion())
                    continue;
                ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
                relative_strength += unit_wrapper.ApproxInfluence;
                unit_positions.Add(unit.GlobalPosition);
            }

            target_geo_median[cluster] = (Godot.Vector2)globals.Call("geometric_median_of_objects", unit_positions);
            target_strength[cluster] = relative_strength;
        }

        // If there is only one cluster, assign it immediately.
        if (registry_cluster.Count == 1)
        {
            Godot.Collections.Array<RigidBody2D> target_units = registry_cluster.First().Value;
            GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", target_units);
            GetTree().CallGroup(ship_wrapper.GroupName, "set_goal_flag", true);
            return NodeState.SUCCESS;
        }

        // Weight each target cluster by distance (to our team's median) and strength.
        List<float> dist_to_cell = new List<float>();
        foreach (var kvp in target_geo_median)
        {
            float distance_squared = group_geo_median.DistanceSquaredTo(kvp.Value);
            dist_to_cell.Add(distance_squared);
        }

        float min_distance = dist_to_cell.Min();
        Dictionary<float, ClusterKey> weigh_strength = new Dictionary<float, ClusterKey>();

        foreach (KeyValuePair<ClusterKey, float> pair in target_strength)
        {
            ClusterKey cluster = pair.Key;
            float relative_strength = pair.Value;
            Godot.Vector2 targetMedian = target_geo_median[cluster];
            float dist_to = group_geo_median.DistanceSquaredTo(targetMedian);
            float weight = dist_to / min_distance;
            float reweighed_strength = group_strength + relative_strength * weight;
            weigh_strength[reweighed_strength] = cluster;
        }

        float min_strength = weigh_strength.Keys.Min();
        // Select the cluster with the minimum weighted strength.
        ClusterKey selectedCluster = weigh_strength[min_strength];
        Godot.Collections.Array<RigidBody2D> target_units_final = registry_cluster[selectedCluster];
        GetTree().CallGroup(ship_wrapper.GroupName, "set_targets", target_units_final);
        GetTree().CallGroup(ship_wrapper.GroupName, "set_goal_flag", true);
        
        return NodeState.SUCCESS;
    }
}
