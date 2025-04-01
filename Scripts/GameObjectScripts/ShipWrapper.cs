using Godot;
using System;
using System.Collections.Generic;
using System.Drawing;
using Vector2 = System.Numerics.Vector2;

public partial class ShipWrapper : Node
{
    public enum Strategy
    {
        NEUTRAL,
        DEFENSIVE,
        OFFENSIVE,
        EVASIVE
    }

    public enum Goal
    {
        SKIRMISH,
        MOTHERSHIP,
        CONTROL
    }

    [Export]
    public String GroupName { get; private set; }
    [Export]
    public bool GroupLeader { get; private set; }
    [Export]
    public bool IsFriendly { get; private set; }
    [Export]
    public bool FluxOverload { get; private set; }
    [Export]
    public bool VentFluxFlag { get; private set; }
    [Export]
    public int CombatGoal { get; private set; }
    [Export]
    public bool TargetInRange { get; private set; }
    [Export]
    public bool GoalFlag { get; private set; }
    [Export]
    public bool AvoidFlag { get; private set; }
    [Export]
    public bool RetreatFlag { get; private set; }
    [Export]
    public bool FallbackFlag { get; private set; }
    [Export]
    public bool CombatFlag { get; private set; }
    [Export]
    public bool SuccessfulDeploy { get; private set; }
    [Export]
    public bool MatchVelocityFlag { get; private set; }
    public float ApproxInfluence { get; private set; }
    public float TotalFlux { get; private set; }
    public float SoftFlux { get; private set; }
    public float HardFlux { get; private set; }
    public float HullIntegrity { get; private set; }
    public float Armor { get; private set; }
    public List<Node2D> AllWeapons { get; private set; }
    public int Posture { get; private set; }
    public List<RigidBody2D> TargetedUnits { get; private set; }
    public RigidBody2D TargetUnit { get; set; }
    public Array NeighborUnits { get; private set; }
    public Vector2I ImapCell { get; private set; }
    public Vector2I RegistryCell { get; private set; }
    public float DefaultCellSize { get; private set; }
    public float MaxCellSize { get; private set; }
    public float AverageWeaponRange { get; private set; }
    public List<string> AvailableNeighborGroups { get; set; }
    public List<string> NearbyEnemyGroups { get; set; }
    public List <string> NeighborGroups { get; set; }
    public List <string> NearbyAttackers { get; set; }
    public List<RigidBody2D> IdleNeighbors { get; set; }
    public List<RigidBody2D> TargetedBy { get; set; }

    public void SetGroupName(string newGroupName)
    {
        GroupName = newGroupName ?? throw new ArgumentNullException(nameof(newGroupName), "Group name cannot be null.");
    }

    public void SetGroupLeader(bool value)
    {
        GroupLeader = value;
    }

    public void SetIsFriendly(bool value)
    {
        IsFriendly = value;
    }

    public void SetFluxOverload(bool value)
    {
        FluxOverload = value;
    }

    public void SetVentFluxFlag(bool value)
    {
        VentFluxFlag = value;
    }

    public void SetCombatGoal(int value)
    {
        CombatGoal = value;
    }

    public void SetTargetInRange(bool value)
    {
        TargetInRange = value;
    }

    public void SetGoalFlag(bool value)
    {
        GoalFlag = value;
    }

    public void SetAvoidFlag(bool value)
    {
        AvoidFlag = value;
    }

    public void SetRetreatFlag(bool value)
    {
        RetreatFlag = value;
    }

    public void SetFallbackFlag(bool value)
    {
        FallbackFlag = value;
    }

    public void SetCombatFlag(bool value)
    {
        CombatFlag = value;
    }

    public void SetDeployFlag(bool value)
    {
        SuccessfulDeploy = value;
    }

    public void SetMatchVelocityFlag(bool value)
    {
        MatchVelocityFlag = value;
    }

    public void SetApproxInfluence(float value)
    {
        ApproxInfluence = value;
    }

    public void SetPosture(int value)
    {
        Posture = value;
    }

    public void SetAllWeapons(Godot.Collections.Array all_weapons)
    {
        foreach (Node2D weapon in all_weapons)
        {
            AllWeapons.Add(weapon);
        }
    }

    public void SetTargetedUnits(Godot.Collections.Array targeted_units)
    {
        foreach (RigidBody2D target in targeted_units)
        {
            if (target == null) continue;
            TargetedUnits.Add(target);
        }
    }

    public void SetNeighborUnits(Array neighbors)
    {
        NeighborUnits = neighbors;
    }

    public void SetTotalFlux(float value)
    {
        TotalFlux = value;
    }

    public void SetSoftFlux(float value)
    {
        SoftFlux = value;
    }

    public void SetHardFlux(float value)
    {
        HardFlux = value;
    }

    public void SetHullIntegrity(float value)
    {
        HullIntegrity = value;
    }

    public void SetArmor(float value)
    {
        Armor = value;
    }


    public void SetImapCell(Vector2I cell)
    {
        ImapCell = cell;
    }

    public void SetRegistryCell(Vector2I cell)
    {
        RegistryCell = cell;
    }

    public void SetDefaultCellSize(float size)
    {
        DefaultCellSize = size;
    }

    public void SetMaxCellSize(float size)
    {
        MaxCellSize = size;
    }

    public void SetAvgWeaponRange(float avg)
    {
        AverageWeaponRange = avg;
    }
}
