using Godot;
using System;

// Breakdown
//  Move and Hold is the defacto defensive operation and all defensive operations are a way to stage future operations.
//  However, the Admiral AI is not capable of sequencing goals together the way a player would to create strategic depth. 
//  As a consequence its only purpose is to seize territory and consequently deny the player control of a region.
//
// Use Cases
//  1) Seize a strategically significant region of the map

public partial class EvaluateMoveHold : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.SUCCESS;

        current_tick = admiral.CurrentSampleTick;

        // Q: What are we looking for?
        // A: Areas of the combat map with strategic value and weighing its significance with regards to the objective of the combat encounter.
        // Q: What are areas of low value, or no value?
        // A: In the context of the game
        //      - Already captured control points
        //      - Effective area of player's defensive operations
        // Q: What are areas of high value?
        // A: In the context of the game
        //      - Neutral control points
        //      - Areas outside of the player's defensive operations
        
        // Weigh Move and Hold
        //  1. Weigh For
        //      - No current fights
        //          - Early in combat
        //      - Enemy defensive operations
        //      - Player offensive operations
        //
        // 2. Weigh Against
        //      - Enemy units are winning
        //
        //  Use RegistryCellsMerit for evaluating the strategic significance of different regions of the map
        //
        // Common Data Points:
        // - RegistryCellsMerit
        // - DiscreteSample
        // - GroupData

        return NodeState.SUCCESS;
    }
}
