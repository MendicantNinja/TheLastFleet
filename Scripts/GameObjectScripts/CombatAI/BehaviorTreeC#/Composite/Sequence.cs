using Godot;

[Icon("res://Art/MetaIcons/BehaviorTree/sequencer.svg")]
public partial class Sequence : Composite
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
