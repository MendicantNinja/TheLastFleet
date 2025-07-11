using Godot;
using System;

// Notes:
// For now, if there is no combat, we do not immediately assume a need to reinforce any particular grouping of units in a region or area.
// The metric for this is TensionCells, if there are no TensionCells, we assume that units are not even within range of each other to attack.
// Thus, it makes no sense to reinforce any units when they are not in combat.

// Breakdown
//  Reinforce is born out of the necessity to counter Admiral AI's inability to sequence goals, thus it serves two purposes:
//      1) To prevent the collapse of enemy defenses.
//      2) Give enemy units breathing room to fallback and regroup.
//  In otherwords, reinforce gives enemy AI additional defensive capabilities to counter offensive operations from the player in the midst of combat.
//  Ships that are sturdy and move at a decent pace are best utilized to reinforce other ships.

public partial class EvaluateReinforce : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if(current_tick == admiral.CurrentSampleTick || admiral.TensionCells.Count == 0 || admiral.CurrentSampleTick == 0)
        {
            return NodeState.FAILURE;
        }

        current_tick = admiral.CurrentSampleTick;

        // Compare past TensionCell evaluations with the current.
        // If none exist, or are outdated, then run analysis on the current TensionCells.
        // The analysis is simple, iterate over the TensionCells and look for local minima and maxima.
        // Local minima are likely to exist on the outer perimeter of the local tension distributions.
        // The same local minima are more than likely to exist at cells of high vulnerability. 
        // Local maxima are likely areas of concentrated unit influence, player and enemy, where there is no clear vulnerability to discern.
        // It is a statistical grayzone, so we are better off knowing areas of high tension, areas of low tension, and evaluating vulnerability local to 
        // areas of low tension. 
        //
        // Keep tabs on enemy groups and their defensive operations (Move and Hold)
        // When a group of Move and Hold units are weak, and there are available nearby units
        // reinforce the group
        // Weigh the score based off how feasible reinforcing the units are, distance takes priority
        
        // Common Data Points:
        // - RegistryCellsMerit
        // - DiscreteSample
        // - GroupData
        
        return NodeState.FAILURE;
    }
}
