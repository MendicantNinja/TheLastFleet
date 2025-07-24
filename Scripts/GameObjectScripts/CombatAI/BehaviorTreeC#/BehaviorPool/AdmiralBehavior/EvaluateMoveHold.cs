using Godot;
using Globals;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using Vector2 = System.Numerics.Vector2;

// Breakdown
//  Move and Hold is the defacto defensive operation and all defensive operations are a way to stage future operations.
//  However, the Admiral AI is not capable of sequencing goals together the way a player would to create strategic depth. 
//  As a consequence its only purpose is to seize territory and consequently deny the player control of a region.
//
// Use Cases
//  1) Seize a strategically significant region of the map

public partial class EvaluateMoveHold : Action
{
    int radius_min = 10;
    int radius_max = 40;
    int radius_dec = 5;
    int contender_limit = 3;
    int current_tick = 0;
    public override NodeState Tick(Node agent)
    {
        Admiral admiral = agent as Admiral;
        if (current_tick == admiral.CurrentSampleTick || admiral.CurrentSampleTick == 0) return NodeState.SUCCESS;

        current_tick = admiral.CurrentSampleTick;
        
        DiscreteSample current_sample = admiral.RecentSamples.Last();
        List<GroupData> player_defense = current_sample.PlayerGroups.Where(group => group.GroupGoal == Goal.MOVE_HOLD).ToList();
        
        // FOCUS ON STRATEGIC POI IE CELLMERIT POI
        // all 1st iteration no man's land go in this list
        HashSet<Vector2I> first_gen_nml = new();
        HashSet<Vector2I> strategic_cells = new();
        foreach (GroupData data in player_defense)
        {
            // Find Registry index
            Vector2I cell_idx = new((int)data.TargetPosition.Y / ImapManager.Instance.MaxCellSize, (int)data.TargetPosition.X / ImapManager.Instance.MaxCellSize);
            // Get registry cell data from RCM
            ref CellMerit center_merit = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, cell_idx);
            if (Unsafe.IsNullRef(ref center_merit) || center_merit.AdjacentCells.Count < 8) continue;

            // If player affiliated units are there and no enemy units are, set its base strategic value to -1.0
            // else move on (for now)
            if (center_merit.FriendlyPresence > 0.0f && center_merit.EnemyPresence == 0.0f)
            {
                center_merit.BaseStrategicValue = -1.0f;
            }

            // Go through each adjacent cell to the current respective cell
            // All "orthogonal" cells are set to -1.0f and sent to the second iteration to find overlapping diagonals
            // All diagonal cells are added to the strategic cells list for further evaluation
            //GD.Print("center cell: ", cell_idx);
            foreach (Vector2I adj_cell in center_merit.AdjacentCells)
            {
                ref CellMerit adj_data = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, adj_cell);
                if (Unsafe.IsNullRef(ref adj_data) || adj_data.BaseStrategicValue < 0.0f) continue;
                
                float dist_to = cell_idx.DistanceTo(adj_cell);
                //GD.Print(adj_cell, " : ", dist_to);
                if (dist_to > 1.0f)
                {
                    strategic_cells.Add(adj_cell);
                    continue;
                }
                else
                {
                    adj_data.BaseStrategicValue = -1.0f;
                    first_gen_nml.Add(adj_cell);
                }
                
                // I do not know if this will happen but just in case a diagonal cell makes it through that is actually
                // in no man's land, we remove it from the strategic cells list.
                if (strategic_cells.Contains(adj_cell)) strategic_cells.Remove(adj_cell);
            }
        }

        // Quickly iterate through the first group of strategic cells and set the base strategic value to 0.5.
        // mark all diagonal “fair game” cells
        foreach (Vector2I idx in strategic_cells)
        {
            ref CellMerit cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, idx);
            cell.BaseStrategicValue = 0.5f;
        }

        // The second iteration will try to find if there are strategically significant cells (base strategic value > 0)
        // orthogonally horizontal or vertical to the current "no man's land" cell.
        // If this is the case, there should exist at least one orthogonal cell with a base strategic value of 0,
        // or -1.
        foreach (Vector2I cell_idx in first_gen_nml)
        {
            ref CellMerit nml_cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, cell_idx);
            // cell_idx = (m, n) = (rows, columns) = (y, x)
            // left cell of (3,2) -> Vector2I(cell_idx.X, cell_idx.Y - 1) = (3, 1)
            ref CellMerit left_cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, new Vector2I(cell_idx.X, cell_idx.Y - 1));
            ref CellMerit right_cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, new Vector2I(cell_idx.X, cell_idx.Y + 1));
            ref CellMerit up_cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, new Vector2I(cell_idx.X - 1, cell_idx.Y));
            ref CellMerit down_cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, new Vector2I(cell_idx.X + 1, cell_idx.Y));

            if (Unsafe.IsNullRef(ref left_cell) || Unsafe.IsNullRef(ref right_cell) || Unsafe.IsNullRef(ref up_cell)
            || Unsafe.IsNullRef(ref down_cell)) continue;

            bool vertical_alignment = false;
            bool horizontal_alignment = false;
            if(left_cell.BaseStrategicValue > 0.0 && right_cell.BaseStrategicValue > 0.0)
            {
                horizontal_alignment = true;
            }
            else if (up_cell.BaseStrategicValue > 0.0 && down_cell.BaseStrategicValue > 0.0)
            {
                vertical_alignment = true;
            }
            else continue;

            // if flipped bool for horizontal, grab the up cell or down cell and find which one has a base
            // strategic value of 0, set it to 1
            // vice versa for vertical case
            // then: strategic_cells.Add(the index of the cell thats base strategic value is set to 1)
            if  (horizontal_alignment == true && up_cell.BaseStrategicValue < 0.0f && down_cell.BaseStrategicValue >= 0.0f)
            {
                down_cell.BaseStrategicValue = 1.0f;
                strategic_cells.Add(down_cell.CellIndex);
            }
            else if (horizontal_alignment == true && down_cell.BaseStrategicValue < 0.0f && up_cell.BaseStrategicValue >= 0.0f)
            {
                up_cell.BaseStrategicValue = 1.0f;
                strategic_cells.Add(up_cell.CellIndex);
            }
            else if (vertical_alignment == true && left_cell.BaseStrategicValue < 0.0f && right_cell.BaseStrategicValue >= 0.0f)
            {
                right_cell.BaseStrategicValue = 1.0f;
                strategic_cells.Add(right_cell.CellIndex);
            }
            else if (vertical_alignment == true && right_cell.BaseStrategicValue < 0.0f && left_cell.BaseStrategicValue >= 0.0f)
            {
                left_cell.BaseStrategicValue = 1.0f;
                strategic_cells.Add(left_cell.CellIndex);
            }
        }

        // There will be a divergence here when control points get implemented but for now we'll simply reflect the existing
        // skirmish mode
        // Regardless, the last focus is on objective weight, the strategic significance of the region in relation to the
        // objective of the combat encounter.
        List<CellMerit> eval_contenders = new();
        foreach (Vector2I idx in strategic_cells)
        {
            ref CellMerit cell = ref CollectionsMarshal.GetValueRefOrNullRef(admiral.RegistryCellsMerit, idx);
            //if (admiral.ObjectiveHeuristic == Objective.CONTROL) would go here
            // always set control points to 1.0 and weigh everything else lower
            
            if (admiral.HeuristicObjective == Objective.SKIRMISH && cell.BaseStrategicValue == 0.5f)
            {
                cell.ObjectiveWeight = (0.5f + cell.FriendlyPresence + cell.EnemyPresence + cell.BaseStrategicValue) / 4.0f;
            }
            else if (admiral.HeuristicObjective == Objective.SKIRMISH && cell.BaseStrategicValue == 1.0f)
            {
                cell.ObjectiveWeight = (1.0f + cell.FriendlyPresence + cell.EnemyPresence + cell.BaseStrategicValue) / 4.0f;
            }
            eval_contenders.Add(cell);
        }

        // This is not an end-all be-all implementation for how these goals are later evaluated before goal propagation.
        // However, this will serve as an off the cuff baseline that requires refinement to achieve desirable results.
        eval_contenders = eval_contenders.OrderByDescending(cell => cell.ObjectiveWeight).ToList();
        int goal_limit;
        
        if (eval_contenders.Count < contender_limit)
        {
            goal_limit = eval_contenders.Count;
        }
        else
        {
            goal_limit = contender_limit;
        }
        
        for (int i = 0; i < goal_limit; i++)
        {
            CellMerit cell = eval_contenders[i];
            GoalDescriptor goal = new()
            {
                Type = Goal.MOVE_HOLD,
                BaseWeight = cell.ObjectiveWeight,
                Radius = radius_max,
                SampleTick = current_tick
            };
            Vector2 cell_pos = new(cell.CellIndex.Y * ImapManager.Instance.MaxCellSize, cell.CellIndex.X * ImapManager.Instance.MaxCellSize);
            cell_pos.X += ImapManager.Instance.MaxCellSize / 2f;
            cell_pos.Y += ImapManager.Instance.MaxCellSize / 2f;
            Vector2I cell_idx = new((int)cell_pos.Y / ImapManager.Instance.DefaultCellSize, (int)cell_pos.X / ImapManager.Instance.DefaultCellSize);
            goal.CenterCell = cell_idx;
            List<GoalDescriptor> n_hist_goal = admiral.GoalHistory.Where(g => g.Type == Goal.MOVE_HOLD).ToList();
            foreach (GoalDescriptor n_goal in n_hist_goal)
            {
                if (n_goal.CenterCell != goal.CenterCell) continue;
                //if (n_goal.SampleTick < current_tick - admiral.sample_limit) continue;
                GoalDescriptor goal_copy = n_goal;
                if (n_goal.Radius > radius_min)
                {
                    goal_copy.Radius -= radius_dec;
                    admiral.GoalHistory[goal_copy.Index] = goal_copy;
                }

                goal.BaseWeight += n_goal.BaseWeight;
                if (goal.BaseWeight > 1.0f) goal.BaseWeight = 1.0f;

                if (goal.Radius > radius_min) goal.Radius = goal_copy.Radius;
            }
            admiral.CurrentGoalEvaluation.Add(goal);
        }

        return NodeState.SUCCESS;
    }
}
