using Godot;
using HexStrategy.Shared;
using System.Collections.Generic;

namespace HexStrategy.Client
{
    public partial class GameManager : Node2D
    {
        [Export] public int BoardWidth = 10;
        [Export] public int BoardHeight = 8;
        [Export] public float HexSize = 50.0f;
        
        private Board _gameBoard;
        private List<Player> _players = new();
        private int _currentPlayerIndex = 0;
        private Unit? _selectedUnit;
        
        // Colors for game entities
        private readonly Color BoardColor = Colors.White;
        private readonly Color NodeColor = Colors.Black;
        private readonly Color PathColor = Colors.LightGray;
        
        public override void _Ready()
        {
            GD.Print("GameManager _Ready called");
            InitializeGame();
            QueueRedraw(); // Force initial draw
        }
        
        private void InitializeGame()
        {
            // Create players
            _players.Add(new Player(0, "Player 1", Colors.Red));
            _players.Add(new Player(1, "Player 2", Colors.Blue));
            
            // Create board
            _gameBoard = new Board(BoardWidth, BoardHeight);
            GenerateHexagonalGrid();
            CreateDomains();
            SpawnInitialUnits();
            
            GD.Print("Game initialized with hexagonal board");
        }
        
        private void GenerateHexagonalGrid()
        {
            int nodeId = 0;
            
            // Generate hexagonal grid nodes
            for (int row = 0; row < BoardHeight; row++)
            {
                for (int col = 0; col < BoardWidth; col++)
                {
                    Vector2 position = HexToPixel(col, row);
                    var node = new Shared.Node(nodeId++, position);
                    _gameBoard.Nodes.Add(node);
                }
            }
            
            // Create paths between adjacent nodes
            CreateHexagonalPaths();
        }
        
        private Vector2 HexToPixel(int col, int row)
        {
            float x = HexSize * (3.0f / 2.0f * col) + 100; // Offset from edge
            float y = HexSize * (Mathf.Sqrt(3.0f) * (row + 0.5f * (col & 1))) + 100; // Offset from edge
            return new Vector2(x, y);
        }
        
        private void CreateHexagonalPaths()
        {
            int pathId = 0;
            
            // Define hexagonal directions (6 neighbors)
            var directions = new (int, int)[]
            {
                (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)
            };
            
            foreach (var node in _gameBoard.Nodes)
            {
                int col = (int)(node.Position.X / (HexSize * 3.0f / 2.0f));
                int row = (int)((node.Position.Y - HexSize * Mathf.Sqrt(3.0f) * 0.5f * (col & 1)) / (HexSize * Mathf.Sqrt(3.0f)));
                
                foreach (var (dx, dy) in directions)
                {
                    int neighborCol = col + dx;
                    int neighborRow = row + dy;
                    
                    if (col % 2 == 1) // Odd column offset
                    {
                        if (dx == -1 && dy == 1) neighborRow = row;
                        if (dx == 1 && dy == -1) neighborRow = row;
                    }
                    
                    var neighbor = GetNodeAt(neighborCol, neighborRow);
                    if (neighbor != null)
                    {
                        var path = new Path(pathId++, node, neighbor);
                        _gameBoard.Paths.Add(path);
                        node.Paths.Add(path);
                    }
                }
            }
        }
        
        private Shared.Node? GetNodeAt(int col, int row)
        {
            if (col < 0 || col >= BoardWidth || row < 0 || row >= BoardHeight)
                return null;
                
            int index = row * BoardWidth + col;
            return index < _gameBoard.Nodes.Count ? _gameBoard.Nodes[index] : null;
        }
        
        private void CreateDomains()
        {
            int domainId = 0;
            
            foreach (var centerNode in _gameBoard.Nodes)
            {
                var domain = new Domain(domainId++, centerNode);
                
                // Add adjacent nodes to domain
                foreach (var path in centerNode.Paths)
                {
                    domain.AdjacentNodes.Add(path.ToNode);
                    domain.DomainPaths.Add(path);
                }
                
                _gameBoard.Domains.Add(domain);
            }
        }
        
        private void SpawnInitialUnits()
        {
            // Spawn units for each player at opposite corners
            var player1StartNode = _gameBoard.Nodes[0];
            var player2StartNode = _gameBoard.Nodes[_gameBoard.Nodes.Count - 1];
            
            var unit1 = new Unit(0, _players[0], player1StartNode, UnitType.Basic);
            var unit2 = new Unit(1, _players[1], player2StartNode, UnitType.Basic);
            
            _players[0].Units.Add(unit1);
            _players[1].Units.Add(unit2);
            
            player1StartNode.OccupyingUnit = unit1;
            player2StartNode.OccupyingUnit = unit2;
        }
        
        public override void _Draw()
        {
            DrawBoard();
            DrawNodes();
            DrawPaths();
            DrawUnits();
        }
        
        private void DrawBoard()
        {
            // Draw board background
            DrawRect(new Rect2(Vector2.Zero, GetViewportRect().Size), BoardColor);
            
            // Debug: Print board info
            if (_gameBoard?.Nodes?.Count > 0)
            {
                GD.Print($"Drawing {_gameBoard.Nodes.Count} nodes, {_gameBoard.Paths.Count} paths");
            }
        }
        
        private void DrawNodes()
        {
            foreach (var node in _gameBoard.Nodes)
            {
                DrawCircle(node.Position, 8, NodeColor);
            }
        }
        
        private void DrawPaths()
        {
            foreach (var path in _gameBoard.Paths)
            {
                DrawLine(path.FromNode.Position, path.ToNode.Position, PathColor, 2);
            }
        }
        
        private void DrawUnits()
        {
            foreach (var player in _players)
            {
                foreach (var unit in player.Units)
                {
                    DrawCircle(unit.CurrentNode.Position, 12, player.PlayerColor);
                }
            }
        }
        
        public override void _Input(InputEvent @event)
        {
            if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
            {
                HandleMouseClick(mouseEvent.Position);
            }
        }
        
        private void HandleMouseClick(Vector2 clickPosition)
        {
            var clickedNode = GetNodeAtPosition(clickPosition);
            if (clickedNode == null) return;
            
            if (_selectedUnit == null)
            {
                // Select unit if clicking on current player's unit
                if (clickedNode.OccupyingUnit?.Owner == _players[_currentPlayerIndex])
                {
                    _selectedUnit = clickedNode.OccupyingUnit;
                    GD.Print($"Selected unit {_selectedUnit.Id}");
                }
            }
            else
            {
                // Move selected unit
                if (CanMoveUnit(_selectedUnit, clickedNode))
                {
                    MoveUnit(_selectedUnit, clickedNode);
                    _selectedUnit = null;
                    NextTurn();
                }
                else
                {
                    _selectedUnit = null;
                }
            }
            
            QueueRedraw();
        }
        
        private Shared.Node? GetNodeAtPosition(Vector2 position)
        {
            foreach (var node in _gameBoard.Nodes)
            {
                if (node.Position.DistanceTo(position) < 15)
                    return node;
            }
            return null;
        }
        
        private bool CanMoveUnit(Unit unit, Shared.Node targetNode)
        {
            if (targetNode.OccupyingUnit != null) return false;
            
            // Check if target is adjacent
            foreach (var path in unit.CurrentNode.Paths)
            {
                if (path.ToNode == targetNode && !path.IsBlocked)
                    return true;
            }
            
            return false;
        }
        
        private void MoveUnit(Unit unit, Shared.Node targetNode)
        {
            unit.CurrentNode.OccupyingUnit = null;
            unit.CurrentNode = targetNode;
            targetNode.OccupyingUnit = unit;
            
            GD.Print($"Unit {unit.Id} moved to node {targetNode.Id}");
        }
        
        private void NextTurn()
        {
            _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.Count;
            GD.Print($"Turn: Player {_currentPlayerIndex + 1}");
        }
    }
}