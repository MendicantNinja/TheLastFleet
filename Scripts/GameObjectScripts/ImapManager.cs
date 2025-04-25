using Godot;
using InfluenceMap;
using System;
using System.Collections.Generic;

[GlobalClass]
public partial class ImapManager : Node
{
    public static ImapManager Instance { get; private set; }

    private List<ImapTemplate> OccupancyTemplates;
    private List<ImapTemplate> ThreatTemplates;
    private List<ImapTemplate> InverseOccupancyTemplates;
    private List<ImapTemplate> InverseThreatTemplates;

    public Dictionary<Vector2I, RigidBody2D[]> RegistryMap;

    int default_radius = 5;
    int arena_width = 17000;
    int arena_height = 20000;
    int default_cell_size = 250;
    int max_cell_size = 2250;

    public override void _Ready()
    {
        int longest_range = 2250 / default_cell_size;
        OccupancyTemplates = InitOccupancyMapTemplates(default_radius, ImapType.OccupancyMap, 1.0f);
        ThreatTemplates = InitThreatMapTemplates(longest_range, ImapType.ThreatMap, 1.0f);
        InverseOccupancyTemplates = InitOccupancyMapTemplates(default_radius, ImapType.OccupancyMap, -1.0f);
        InverseThreatTemplates = InitThreatMapTemplates(longest_range, ImapType.ThreatMap, -1.0f);
    }

    public List<ImapTemplate> InitOccupancyMapTemplates(int radius, ImapType type, float magnitude = 1.0f)
    {
        List<ImapTemplate> new_templates = new List<ImapTemplate>();

        for (int r = 1; r <= radius; r++)
        {
            int size = (2 * radius) + 1;
            Imap new_map = new Imap(size, size);
            new_map.PropagateInfluenceFromCenter(magnitude);
            new_templates.Add(new ImapTemplate(r, type, new_map));
        }

        return new_templates;
    }

    public List<ImapTemplate> InitThreatMapTemplates(int radius, ImapType type, float magnitude = 1.0f)
    {
        List<ImapTemplate> new_templates = new List<ImapTemplate>();

        for (int r = 1; r <= radius; r++)
        {
            int size = (2 * radius) + 1;
            Imap new_map = new Imap(size, size);
            new_map.PropagateInfluenceFromCenter(magnitude);
            new_templates.Add(new ImapTemplate(r, type, new_map));
        }

        return new_templates;
    }
}
