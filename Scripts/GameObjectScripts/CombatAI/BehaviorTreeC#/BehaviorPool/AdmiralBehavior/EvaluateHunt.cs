using Godot;
using System;

// Breakdown
//  In order to make enemy AI capable of snowballing against player units when victory is near, we need a goal to do so.
//  Since the player can issue direct orders to eliminate specific targets in a similar way, this is more or less
//  a way to hand the Admiral a similar capability without the need to specify which units to target. This is also another
//  goal that fits in every combat objective.
//  Enemy ships act on the Hunt goal if they are fast and able to finish off stragglers, think light cavalary on retreating units.
//  Other slower, sturdy, battle ready ships are better off finishing the fights they are already in.
// 
// Use Case
//  When a victory is right around the corner, meaning the player's defensive operations are collapsing, any offensive operations
//  are borderline suicidal, and overall player strength is gone.
//
// Note that this is not an important one to include, for now, it is merely a minor bit of early polish to make it so the
// enemy is more intimidating to the player. An enemy that relentlessly pursues stragglers to cement victory is a 
// fearsome foe.

public partial class EvaluateHunt : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.FAILURE;

        // Given there are multiple means to create a trendline to determine if victory is near, so this is a fairly simple 
        // goal to implement by comparison to others. Enemy units recklessly hunting down their opposition do not suffer
        // the same consequences as a player who loses units. 
        // There is not much to do here for now, and it is worth doing this for the sake of wrapping up goal propagation
        // and enemy AI, more generally.

        return NodeState.SUCCESS;
    }
}
