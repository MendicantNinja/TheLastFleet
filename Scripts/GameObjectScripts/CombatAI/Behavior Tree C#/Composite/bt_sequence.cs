using Godot;
using System.Collections.Generic;

public partial class CompositeSequence : Composite
{
    public override NodeState Tick(Node agent)
    {
        foreach (var child in children)
        {
            var result = child.Tick(agent);
            if (result != NodeState.SUCCESS)
            {
                return result;
            }
        }
        return NodeState.SUCCESS;
    }
}
