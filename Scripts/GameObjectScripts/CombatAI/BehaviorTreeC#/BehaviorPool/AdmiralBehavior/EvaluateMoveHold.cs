using Godot;
using System;

// Breakdown
//  Move and Hold is the defacto defensive operation and all defensive operations are a way to stage future operations.
//  However, the Admiral AI is not capable of sequencing goals together the way a player would to create strategic depth. 
//  As a consequence its only purpose is to seize territory and consequently deny the player control of a region.
//
// Use Cases
//  Skirmish
//      1) Counter-operation, to counter the player's own Move and Hold orders, or for offensive operations, like Eliminate.
//      2) Alternatively, we always consider Move and Hold within the context of other goals, like Harass.
//  Control points
//      We follow the World in Conflict design, Move and Hold is the defacto operation for seizing control points.
//  Mothership Assault
//      Move and Hold is likely the most useless goal to issue for these encounters. So skip over it.

public partial class EvaluateMoveHold : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.SUCCESS;

        current_tick = admiral.CurrentSampleTick;

        // Weigh Move and Hold
        //  1. Weigh For
        //      - No current fights
        //          - Early in combat
        //      - Enemy defensive operations
        //      - Player offensive operations
        //
        // 2. Weigh Against
        //      - Enemy units are winning
        
        //─── Next Steps ────────────────────────────────────────────────────
        //  1. Gather observations from RecentSamples, GroupData, and unit clusters
        //      A) Unit clusters, strengths, and goals
        //      B) Player group goals and movement 
        //  Note: GroupData now includes additional variables to use, like group velocity and target position
        //
        //  2. Run analysis on these observations
        //      A. Are "we" already on defense, i.e. a Move and Hold order?
        //          How well is that group fairing? If nothing is happening, reissue Move and Hold goal with a lower weight.
        //          If units are losing, weigh Move and Hold lower and weigh a reinforce or fallback goal higher.
        //          If units are winning, weigh Move and Hold lower and weigh an assault, harass or hunt goal higher.
        //          Do not move onto B or C.
        //
        //      B. Is the player on offense?
        //          Only process Escort and Eliminate. If either of these goals are issued:
        //          - Where / Which Target
        //          - How soon until they reach
        //      Given (B) is true: 
        //      Is it possible to mount a defense with units nearby the player's offensive operation? 
        //          - Cluster strength
        //          - Combat readiness, i.e. how many units are already in combat (defense and offense)
        //      If it is possible to mount a defense, weigh the Move and Hold goal instance high.
        //      If it is not possible, and weight Move and Hold goal instance lower. In instances
        //      where it clear there are additional units that can reinforce around the incoming attackers, handle it there.
        //
        //      C. If (B) is false, is the player on defense?
        //          Process Move and Hold only:
        //          - Where
        //          - How soon
        //      Given (C) is true:
        //      Is Move and Hold a useful goal to issue here?
        //          1. Is the player trying to seize ground to launch operations?
        //          2. Is the player potentially pulling a feint?
        //          3. Is the player losing and trying to regain control?
        //      If (2) or (3) are found true, weigh Move and Hold considerably lower, unless I set up an "Admiral goal sequence" of some sort.
        //      If (1) is true, determine if it is possible to counter-defense, i.e. set up Admiral's own Move and Hold to stage future operations.
        //
        // Common Data Points:
        //  - Status of enemy groups
        //  - Player groups and velocity

        return NodeState.SUCCESS;
    }
}
