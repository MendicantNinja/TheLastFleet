using Godot;
using System;

public partial class BehaviorTreeRoot : BehaviorTree
{
    [Export]
    public bool enabled = true;
    
    public Node agent;

    public override void _Ready()
    {
        agent = GetParent();
        if (GetChildCount() != 1)
        {
            ToggleRoot(false);
            return;
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        if (enabled == false)
        {
            return;
        }
    }

    private void ToggleRoot(bool value)
    {
        enabled = value;
    }
}
