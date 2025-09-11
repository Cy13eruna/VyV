using Godot;
using System.Collections.Generic;

namespace HexStrategy.Shared
{
    /// <summary>
    /// Represents a hexagonal node on the game board
    /// </summary>
    public class Node
    {
        public Vector2 Position { get; set; }
        public int Id { get; set; }
        public List<Path> Paths { get; set; } = new();
        public Unit? OccupyingUnit { get; set; }
        public Player? ControllingPlayer { get; set; }
        
        public Node(int id, Vector2 position)
        {
            Id = id;
            Position = position;
        }
    }

    /// <summary>
    /// Represents a path connection between two adjacent nodes
    /// </summary>
    public class Path
    {
        public int Id { get; set; }
        public Node FromNode { get; set; }
        public Node ToNode { get; set; }
        public bool IsBlocked { get; set; }
        
        public Path(int id, Node from, Node to)
        {
            Id = id;
            FromNode = from;
            ToNode = to;
            IsBlocked = false;
        }
    }

    /// <summary>
    /// Represents a game unit (piece) that can move between nodes
    /// </summary>
    public class Unit
    {
        public int Id { get; set; }
        public Player Owner { get; set; }
        public Node CurrentNode { get; set; }
        public UnitType Type { get; set; }
        public int MovementRange { get; set; }
        
        public Unit(int id, Player owner, Node startNode, UnitType type)
        {
            Id = id;
            Owner = owner;
            CurrentNode = startNode;
            Type = type;
            MovementRange = type == UnitType.Scout ? 2 : 1;
        }
    }

    /// <summary>
    /// Represents a hexagonal domain (1 center + 6 adjacent nodes + 12 paths)
    /// </summary>
    public class Domain
    {
        public int Id { get; set; }
        public Node CenterNode { get; set; }
        public List<Node> AdjacentNodes { get; set; } = new();
        public List<Path> DomainPaths { get; set; } = new();
        public Player? ControllingPlayer { get; set; }
        
        public Domain(int id, Node center)
        {
            Id = id;
            CenterNode = center;
        }
    }

    /// <summary>
    /// Represents a player in the game
    /// </summary>
    public class Player
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public Color PlayerColor { get; set; }
        public List<Unit> Units { get; set; } = new();
        public List<Domain> ControlledDomains { get; set; } = new();
        
        public Player(int id, string name, Color color)
        {
            Id = id;
            Name = name;
            PlayerColor = color;
        }
    }

    /// <summary>
    /// Represents the game board containing all nodes and paths
    /// </summary>
    public class Board
    {
        public int Width { get; set; }
        public int Height { get; set; }
        public List<Node> Nodes { get; set; } = new();
        public List<Path> Paths { get; set; } = new();
        public List<Domain> Domains { get; set; } = new();
        
        public Board(int width, int height)
        {
            Width = width;
            Height = height;
        }
    }

    public enum UnitType
    {
        Basic,
        Scout,
        Defender
    }
}