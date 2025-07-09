using Godot;
using System;

// Breakdown
//  Harass is a catch-all goal for evasive manuevering, hit-and-run tactics, and adding depth to offensive capabilities of enemy AI.
//  It is great for fast ships with the capacity of chipping away at other units, and only these units should commit to this goal. 
//  Unlike player goals, all combat enounter objectives benefit from a modular Harass goal, therefore there is no need to hone in
//  on use cases for any specific objective. I should also add that works in cases where there are no fights and fights. 
//
// Use Cases (Ranked)
//  1) To poke holes in the player's defense.
//  2) To prevent AI from getting goaded by the player into ambushes with a feint.
//  3) To goad player units into overcommitting isolated units under the player's nose.
//

public partial class EvaluateHarass : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if(current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0)
        {
            return NodeState.FAILURE;
        }

        current_tick = admiral.CurrentSampleTick;

        // Rule: Each evaluation is downstream of the previous evaluation. If not even one criteria is met, then
        // it falls through.
        //
        // "To poke holes in the player's defense." (Gold)
        //      - Evaluate where player groups are acting defensively
        //      - Evaluate if said player groups are already engaged in combat
        //      - Evaluate if there are positions where player groups are vulnerable
        //      - Evaluate if there are nearby enemy units that are capable of harassing vulnerable areas
        //
        // "To prevent AI from getting goaded by the player into ambushes with a feint." (Silver)
        //      - Evaluate if there are no fights
        //      - Evaluate if there are any vulnerable player group(s) near or about to be near enemy units (clusters)
        //      - Evaluate if these are disproportionately vulnerable player group(s)
        //      - Evaluate if there are nearby enemy units capable of harassing said group(s)
        //      - Determine region nearby other enemy units that would allow for harassing the group in question
        //
        //  "To goad player units into overcomitting isolated units under the player's nose." (Bronze)
        //      - Evaluate if there are any vulnerable player group(s) near or about to be near enemy units (clusters)
        //      - Evaluate if there are fights nearby
        //      - Evaluate if there are available units both in and outside the fights
        //      - Evaluate if units in the fights are winning
        //      - Determine which nearby region to an ongoing winning fight could drag player units towards combat
        //
        // Common Data Points:
        //  - Player groups and goals (Look to RecentSamples / most recent DiscreteSample container, use current_tick to retrieve the sample)
        //  - Fight ambiguity (If TensionCells.Count == 0, no combat, and vice versa.)
        //  - Availability of units (Use ImapManager.Instance.EnemyClusters and use TensionCells for fight sensitive cases)

        return NodeState.SUCCESS;
    }
}
