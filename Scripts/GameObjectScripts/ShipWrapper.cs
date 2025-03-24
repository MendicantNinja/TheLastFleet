using Godot;
using System;

public partial class ShipWrapper : RigidBody2D
{
    // Called when the node enters the scene tree for the first time.
    [Export]
    public bool group_leader { get; private set; }
    [Export]
    public String group_name { get; set; }

    [Export]
    public bool target_in_range { get; private set; }
    [Export]
    public bool goal_flag { get; private set; }
    [Export]
    public bool avoid_flag { get; private set; }
    [Export]
    public bool brake_flag { get; private set; }
    [Export]
    public bool retreat_flag { get; private set; }
    [Export]
    public bool fallback_flag { get; private set; }
    [Export]
    public bool combat_flag { get; private set; }

    public void SetGroupName(string newGroupName)
    {
        group_name = newGroupName ?? throw new ArgumentNullException(nameof(newGroupName), "Group name cannot be null.");
    }

    public void SetGroupLeader(bool value)
    {
        group_leader = value;
    }

    public void SetTargetInRange(bool value)
    {
        target_in_range = value;
    }

    public void SetGoalFlag(bool value)
    {
        goal_flag = value;
    }

    public void SetAvoidFlag(bool value)
    {
        avoid_flag = value;
    }

    public void SetBrakeFlag(bool value)
    {
        brake_flag = value;
    }

    public void SetRetreatFlag(bool value)
    {
        retreat_flag = value;
    }

    public void SetFallbackFlag(bool value)
    {
        fallback_flag = value;
    }

    public void SetCombatFlag(bool value)
    {
        combat_flag = value;
    }
}