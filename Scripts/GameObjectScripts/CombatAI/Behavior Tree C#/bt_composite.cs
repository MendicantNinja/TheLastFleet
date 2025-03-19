using Godot;
using System;
using System.Collections.Generic;

public abstract partial class Composite : BehaviorTreeNode
{
    protected List<BehaviorTreeNode> children = new List<BehaviorTreeNode>();

    public override void _Ready()
    {
        if (GetChildCount() <= 0)
        {
            throw new InvalidOperationException($"{GetType().Name} requires at least one child node.");
        }
        
        foreach (Node child in GetChildren())
        {
            if (child is BehaviorTreeNode behaviorNode)
            {
                children.Add(behaviorNode);
            }
        }
    }
}