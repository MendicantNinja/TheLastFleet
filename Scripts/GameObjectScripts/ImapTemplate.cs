using InfluenceMap;
using System;
using System.Data;
using System.Runtime.CompilerServices;

public struct ImapTemplate
{
    public int Radius;
    public ImapType TemplateType;
    public Imap Map;

    public ImapTemplate(int radius, ImapType type, Imap map)
    {
        Radius = radius;
        TemplateType = type;
        Map = map;
    }
}
