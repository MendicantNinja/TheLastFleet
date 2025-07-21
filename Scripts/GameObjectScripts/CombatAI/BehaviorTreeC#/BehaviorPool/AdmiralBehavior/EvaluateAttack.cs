using Godot;
using System;

// Breakdown
//  Without the ability to select units and sequence goals the way a player can,
//  the enemy AI needs a blanket offensive operation. In infantry doctrine:
//      (1) Moving means attacking.
//      (2) Idle means preparing to attack.
//  Attack is about commitment, risk, and focused aggression.
//
//  Units on the attack take on more risk and try to commit to ganging up on individual player units to whittle away at their forces. 
//  They will chase units to further distances before giving up, they will worry less about their surroundings, 
//  and certainly focus less on their own survivability.
//
// Use Case
//  1) Group(s) of player units in defensive operations are collapsing, or weak.
//  2) Key strategic point is lightly defended.

public partial class EvaluateAttack : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.SUCCESS;

        current_tick = admiral.CurrentSampleTick;

        // "Group(s) of player units in defensive operations are collapsing, or weak."
        //      - Evaluate recent samples of group(s) on defense (use RecentSamples (List<DiscreteSample>) -> Iterate over PlayerGroups (List<GroupData>) -> Goal)
        //      - Evaluate if group(s) are fighting (use TensionCells)
        //      - Evaluate areas of vulnerability (crossreference vulnerability map with tension map)
        //      - Evaluate strength trend of player and enemy group(s) from each sample (use DiscreteSample -> Strength over sample ticks)
        //      - Evaluate if nearby player and enemy units are capable of pitching in (clusters)
        //          - Weigh accordingly
        // "Key strategic point is lightly defended."
        //  Note that this is really only suitable for control point and perhaps mothership defense, unless flanks are rolled into strategic points.
        //      - Find strategic points of interest, e.g. control points/area
        //      - Evaluate recent samples of group(s) on defense (use RecentSamples (List<DiscreteSample>) -> Iterate over PlayerGroups (List<GroupData>) -> Goal)
        //          - Crossreference strategic points of interest with defense groups
        //      - Evaluate local vulnerability (use vulnerability map)
        //      - Evaluate if nearby enemy forces are capable of attacking the region (clusters)
        //          - Weigh accordingly
        //
        // Common Data Points:
        // - DiscreteSample
        // - GroupData
        // - (Maybe) RegistryCellsMerit

        return NodeState.SUCCESS;
    }
}
