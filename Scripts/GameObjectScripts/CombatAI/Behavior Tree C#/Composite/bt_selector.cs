using Godot;
using System.Collections.Generic;

public partial class CompositeSelector : Composite
{
    public override NodeState Tick(Node agent)
    {
        foreach (var child in children)
        {
            var result = child.Tick(agent);
            if (result != NodeState.FAILURE)
            {
                return result;
            }
        }
        return NodeState.SUCCESS;
    }
}
