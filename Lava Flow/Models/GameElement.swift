import Foundation
import SpriteKit

enum GameElementType: String, CaseIterable {
    case straight = "straight"
    case corner = "corner"
    case tSplit = "tsplit"
    case cross = "cross"
    case block = "block"
    
    var displayName: String {
        switch self {
        case .straight: return "Straight"
        case .corner: return "Corner"
        case .tSplit: return "T-Split"
        case .cross: return "Cross"
        case .block: return "Block"
        }
    }
    
    var hint: String {
        switch self {
        case .straight: return "↕"
        case .corner: return "↱"
        case .tSplit: return "⊥"
        case .cross: return "✚"
        case .block: return "⛔"
        }
    }
    
    var canRotate: Bool {
        switch self {
        case .straight, .corner, .tSplit: return true
        case .cross, .block: return false
        }
    }
    
    var connections: [FlowDirection] {
        switch self {
        case .straight: return [.up, .down]
        case .corner: return [.up, .right]
        case .tSplit: return [.left, .up, .right]
        case .cross: return [.up, .down, .left, .right]
        case .block: return []
        }
    }
}

enum FlowDirection: Int, CaseIterable {
    case up = 0
    case right = 90
    case down = 180
    case left = 270
    
    var opposite: FlowDirection {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
    
    var vector: CGVector {
        switch self {
        case .up: return CGVector(dx: 0, dy: 1)
        case .down: return CGVector(dx: 0, dy: -1)
        case .left: return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        }
    }
    
    func rotated(by degrees: Int) -> FlowDirection {
        let newAngle = (self.rawValue + degrees) % 360
        return FlowDirection(rawValue: newAngle) ?? self
    }
}

class GameElement {
    let type: GameElementType
    var gridPosition: CGPoint
    var rotation: Int
    var isPlaced: Bool
    var node: SKSpriteNode?
    var panelPosition: CGPoint = .zero
    
    init(type: GameElementType, gridPosition: CGPoint = .zero, rotation: Int = 0) {
        self.type = type
        self.gridPosition = gridPosition
        self.rotation = rotation
        self.isPlaced = false
    }
    
    func rotate() {
        guard type.canRotate else { return }
        rotation = (rotation + 90) % 360
        node?.zRotation = -CGFloat(rotation) * .pi / 180
    }
    
    func getActiveConnections() -> [FlowDirection] {
        return type.connections.map { $0.rotated(by: rotation) }
    }
    
    func canAcceptFlow(from direction: FlowDirection) -> Bool {
        if type == .block { return false }
        let connections = getActiveConnections()
        return connections.contains(direction.opposite)
    }
    
    func getOutputDirections(inputDirection: FlowDirection) -> [FlowDirection] {
        guard canAcceptFlow(from: inputDirection) else { return [] }
        let connections = getActiveConnections()
        return connections.filter { $0 != inputDirection.opposite }
    }
}
