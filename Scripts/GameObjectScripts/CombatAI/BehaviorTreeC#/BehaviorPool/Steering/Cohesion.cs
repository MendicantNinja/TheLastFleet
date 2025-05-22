using Godot;
using System;
using System.Collections.Generic;
using Vector2 = System.Numerics.Vector2;

public partial class Cohesion : Action
{
    public override NodeState Tick(Node agent)
    {
        if (Engine.GetPhysicsFrames() % 120 != 0) return NodeState.FAILURE;
        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
        SteerData steer_data = (SteerData)agent.Get("SteerData");
        steer_data.CohesionForce = Vector2.Zero;
        if (ship_wrapper.NeighborUnits is null || ship_wrapper.NeighborUnits.Count == 0) return NodeState.FAILURE;
        if (string.IsNullOrEmpty(ship_wrapper.GroupName)) return NodeState.FAILURE;
        RigidBody2D n_agent = agent as RigidBody2D;

        //List<Vector2> neighbor_positions = new List<Vector2>();
        Vector2 agent_pos = new Vector2(n_agent.GlobalPosition.X, n_agent.GlobalPosition.Y);
        Vector2 arithmetic_median = Vector2.Zero;
        //float total_influence = 0.0f;
        //float max_influence = 0.0f;
        int count = 0;
        foreach (RigidBody2D neighbor in GetTree().GetNodesInGroup(ship_wrapper.GroupName))
        {
            if (!IsInstanceValid(neighbor) || neighbor.IsQueuedForDeletion()) continue;

            ShipWrapper neighbor_wrapper = (ShipWrapper)neighbor.Get("ShipWrapper");
            if (ship_wrapper.IsFriendly != neighbor_wrapper.IsFriendly) continue;
            else if (neighbor_wrapper.FallbackFlag == true || neighbor_wrapper.VentFluxFlag == true || neighbor_wrapper.RetreatFlag == true) continue;

            Vector2 neighbor_pos = new Vector2(neighbor.GlobalPosition.X, neighbor.GlobalPosition.Y);
            arithmetic_median += neighbor_pos;
            //neighbor_positions.Add(neighbor_pos);
            count++;
            float approx_inf = Mathf.Abs(neighbor_wrapper.ApproxInfluence);
            //total_influence += approx_inf;
        }

        arithmetic_median /= count;
        if (arithmetic_median == Vector2.Zero)
        {
            steer_data.CohesionWeight = 0.0f;
            return NodeState.FAILURE;
        }
        else if (steer_data.CohesionWeight == 0.0f)
        {
            steer_data.CohesionWeight = 1.0f;
        }
        /*
                    float relative_dist = Vector2.DistanceSquared(agent_pos, arithmetic_median);
                    float max_distance = 0.0f;
                    foreach (Vector2 position in neighbor_positions)
                    {
                        float dist = Vector2.DistanceSquared(position, arithmetic_median);
                        if (dist > max_distance)
                        {
                            max_distance = dist;
                        }
                    }

                    float dist_weight = relative_dist / max_distance;
                    float inf_weight = ship_wrapper.ApproxInfluence / max_influence;
                    */

        Vector2 direction_to = SteerData.DirectionTo(agent_pos, arithmetic_median);

        //float funny_weight = inf_weight / (steer_data.SeparationWeight + inf_weight + steer_data.GoalWeight);
        steer_data.CohesionForce = direction_to * steer_data.CurrentSpeed;
        //dist_weight = Mathf.Clamp(funny_weight, 0.0f, 1.0f);
        //steer_data.CohesionWeight = Mathf.Lerp(0.0f, 1.0f, dist_weight);
        return NodeState.FAILURE;
    }
}
