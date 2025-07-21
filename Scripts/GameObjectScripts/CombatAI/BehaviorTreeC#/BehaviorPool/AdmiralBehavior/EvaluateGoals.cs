using Globals;
using Godot;
using System.Collections.Generic;
using System.Linq;

// This is really rough around the edges but its a start and not a finished implementation of selecting front-runner goals.
// Ideally this is agnostic to the objective, to the goals at hand, and at most only considers the potential for goal propagation 
// to overlap one another and nothing further than that.
public partial class EvaluateGoals : Action
{
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.FAILURE;

        admiral.CurrentGoalEvaluation = admiral.CurrentGoalEvaluation.OrderByDescending(eval => eval.BaseWeight).ToList();
        List<GoalDescriptor> top_goals = new();
        List<Goal> visited_goals = new();
        foreach (GoalDescriptor goal_eval in admiral.CurrentGoalEvaluation)
        {
            
            if (visited_goals.Contains(goal_eval.Type)) continue;
            

            top_goals.Add(goal_eval);
            visited_goals.Add(goal_eval.Type);
            admiral.GoalHistory.Add(goal_eval);
        }

        admiral.CurrentGoalEvaluation = top_goals;
        return NodeState.SUCCESS;
    }
}
