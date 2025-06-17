using Godot;
using System.Collections.Generic;
using Vector2 = System.Numerics.Vector2;

public partial class AssessRetreat : Action
{
    float ratio = 1.0f;
    public override NodeState Tick(Node agent)
    {
        if (Engine.GetPhysicsFrames() % 240 != 0) return NodeState.FAILURE;

        ShipWrapper ship_wrapper = (ShipWrapper)agent.Get("ShipWrapper");
        SteerData steer_data = (SteerData)agent.Get("SteerData");
        if (ship_wrapper.TargetedBy is null || ship_wrapper.TargetedBy.Count == 0) return NodeState.FAILURE;
        if (GetTree().GetNodeCountInGroup(ship_wrapper.GroupName) == 0) return NodeState.FAILURE;
        
        List<string> groups_targeted_by = new List<string>();
        int invalid_attacker = 0;
        int valid_attacker = 0;
        foreach (RigidBody2D attacker in ship_wrapper.TargetedBy)
        {
            if (!IsInstanceValid(attacker) || attacker.IsQueuedForDeletion())
            {
                invalid_attacker++;
                continue;
            }
            valid_attacker++;
            ShipWrapper attacker_wrapper = (ShipWrapper)attacker.Get("ShipWrapper");
            if (!groups_targeted_by.Contains(attacker_wrapper.GroupName))
            {
                groups_targeted_by.Add(attacker_wrapper.GroupName);
            }
        }

        int attacker_count = 0;
        foreach (string group_name in groups_targeted_by)
        {
            attacker_count += GetTree().GetNodeCountInGroup(group_name);
        }
        attacker_count -= invalid_attacker;

        if (attacker_count == 0) return NodeState.FAILURE;

        // If the ratio of attackers to number of units in the current agent group is less or equal to a 1 to 2 ratio,
        // it is strike one.
        // This might yield a false positive since it is not a guarantee that all members of the group are aware of the agent.
        // It also not a guarantee that this is an accurate representation of the total troop strength, since a single unit in a group
        // is surrounded by units aligned to their faction.
        float group_ratio = (float)GetTree().GetNodeCountInGroup(ship_wrapper.GroupName) / attacker_count;
        bool strike_one = false;
        if (group_ratio < 0.5f) strike_one = true;

        // If the agent does not cross the first hurdle, back out and save further analysis for other agents.
        if (strike_one == false && ship_wrapper.RetreatFlag == false) return NodeState.FAILURE;
        
        float admiral_strength = 0.0f;
        float player_strength = 0.0f;
        foreach (RigidBody2D unit in GetTree().GetNodesInGroup("friendly"))
        {
            if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion()) continue;
            player_strength += (float)unit.Get("approx_influence");
        }

        foreach (RigidBody2D unit in GetTree().GetNodesInGroup("enemy"))
        {
            if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion()) continue;
            admiral_strength += (float)unit.Get("approx_influence");
        }

        if (admiral_strength == 0) admiral_strength += Mathf.Epsilon;
        if (player_strength == 0) player_strength += Mathf.Epsilon;

        admiral_strength = Mathf.Abs(admiral_strength);

        // If the respective strength ratio shows that strength of the opposing size is greater than or equal to a 1 to 2 ratio,
        // it is strike two.
        bool strike_two = false;
        if (ship_wrapper.IsFriendly == true && ship_wrapper.CombatFlag == true && (float)player_strength / admiral_strength <= ratio)
        {
            strike_two = true;
        }
        else if (ship_wrapper.IsFriendly == false && ship_wrapper.CombatFlag == true && (float)admiral_strength / player_strength <= ratio)
        {
            strike_two = true;
        }

        // If there are more than enough available affiliated agents, agents will use behaviors like ThreatDetection to attempt to find nearby
        // affiliated groups to try to join them or combine groups.
        if (strike_one == true && strike_two == false)
        {
            if (ship_wrapper.RetreatFlag == true)
            {
                agent.Set("retreat_flag", false);
                steer_data.RotateDirection = Vector2.Zero;
            }
            return NodeState.FAILURE;
        }

        if (strike_one == true && strike_two == true && ship_wrapper.RetreatFlag == true) return NodeState.FAILURE;

        // A "third strike" is not necessary here, if despite meeting all these criteria it fails at this one, we move along.
        // If it is determined that there are more unfriendly than friendly units (same 1 to 2 ratio comparison)
        // then it is the third strike and it is now time for all agents in the same group to find the nearest border to retreat off the map
        int nearby_player_units = 0;
        int nearby_admiral_units = 0;
        foreach (Vector2I cell in ship_wrapper.RegistryNeighborhood)
        {
            if (!ImapManager.Instance.RegistryMap.ContainsKey(cell)) continue;

            List<RigidBody2D> registry_units = ImapManager.Instance.RegistryMap[cell];
            foreach (RigidBody2D unit in registry_units)
            {
                if (!IsInstanceValid(unit) || unit.IsQueuedForDeletion()) continue;
                ShipWrapper unit_wrapper = (ShipWrapper)unit.Get("ShipWrapper");
                
                if (ship_wrapper.IsFriendly == true && ship_wrapper.IsFriendly == unit_wrapper.IsFriendly)
                {
                    nearby_player_units++;
                }
                else if (ship_wrapper.IsFriendly == true && ship_wrapper.IsFriendly != unit_wrapper.IsFriendly && groups_targeted_by.Contains(unit_wrapper.GroupName))
                {
                    nearby_admiral_units++;
                }
                else if (ship_wrapper.IsFriendly == false && ship_wrapper.IsFriendly == unit_wrapper.IsFriendly)
                {
                    nearby_admiral_units++;
                }
                else if (ship_wrapper.IsFriendly == false && ship_wrapper.IsFriendly != unit_wrapper.IsFriendly && groups_targeted_by.Contains(unit_wrapper.GroupName))
                {
                    nearby_player_units++;
                }
            }
        }
        
        // Assume problem spot here
        if (ship_wrapper.IsFriendly == true && nearby_player_units == 0)
        {
            agent.Set("retreat_flag", true);  
        }
        else if (ship_wrapper.IsFriendly == false && nearby_admiral_units == 0)
        {
            agent.Set("retreat_flag", true);
        }

        if (nearby_player_units == 0 || nearby_admiral_units == 0) return NodeState.FAILURE;

        int total_units = nearby_admiral_units + nearby_player_units;
        if (ship_wrapper.IsFriendly == true && (float)nearby_player_units / total_units <= ratio)
        {
            agent.Set("retreat_flag", true);
        }
        else if (ship_wrapper.IsFriendly == false && (float)nearby_admiral_units / total_units <= ratio)
        {
            agent.Set("retreat_flag", true);
        }
        else if (ship_wrapper.RetreatFlag == true)
        {
            agent.Set("retreat_flag", false);
            steer_data.RotateDirection = Vector2.Zero;
        }
        
        /*
        if (IsInstanceValid(ship_wrapper.TargetUnit) || !ship_wrapper.TargetUnit.IsQueuedForDeletion())
        {
            RigidBody2D n_agent = agent as RigidBody2D;
            Godot.Collections.Array<RigidBody2D> targeted_by = (Godot.Collections.Array<RigidBody2D>)ship_wrapper.TargetUnit.Get("targeted_by");
            targeted_by.Remove(n_agent);
            ship_wrapper.TargetUnit.Set("targeted_by", targeted_by);
            agent.Call("set_target_unit", new Godot.Collections.Array<int>());
            ship_wrapper.TargetUnit = null;
            steer_data.TargetUnit = null;
            agent.Call("set_target_for_weapons", new Godot.Collections.Array<int>());
        }
        */
        
        return NodeState.FAILURE;
    }
}
