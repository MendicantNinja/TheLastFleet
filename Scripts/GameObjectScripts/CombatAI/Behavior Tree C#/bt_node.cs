using Godot;
using System;

public abstract partial class BehaviorTreeNode : BehaviorTree
{
    public enum NodeState {FAILURE, SUCCESS, RUNNING};
    protected NodeState state;

    public abstract NodeState Tick();
}
