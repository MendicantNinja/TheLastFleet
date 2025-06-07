using Godot;
using System;
using System.Collections.Generic;

public partial class UnitThreatDetection : Action
{
    Imap working_map = new Imap(3, 3, 0, 0, ImapManager.Instance.DefaultCellSize);
    public override NodeState Tick(Node agent)
    {
        return NodeState.FAILURE;
    }
}
