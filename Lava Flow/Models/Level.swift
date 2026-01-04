import Foundation
import UIKit

enum LevelDifficulty: Int, CaseIterable {
    case veryEasy = 1
    case easy = 2
    case medium = 3
    case hard = 4
    case veryHard = 5
    
    var lavaSpeed: CGFloat {
        switch self {
        case .veryEasy: return 40
        case .easy: return 55
        case .medium: return 70
        case .hard: return 90
        case .veryHard: return 110
        }
    }
    
    var lavaCoolingTime: TimeInterval {
        switch self {
        case .veryEasy: return 25
        case .easy: return 20
        case .medium: return 15
        case .hard: return 12
        case .veryHard: return 8
        }
    }
    
    var availableElements: Int {
        switch self {
        case .veryEasy: return 8
        case .easy: return 7
        case .medium: return 6
        case .hard: return 7
        case .veryHard: return 8
        }
    }
}

struct LevelTarget {
    let position: CGPoint
    let type: TargetType
    var isReached: Bool = false
    
    enum TargetType: String {
        case village = "village"
        case altar = "altar"
        case garden = "garden"
    }
}

struct Level {
    let id: Int
    let name: String
    let difficulty: LevelDifficulty
    let backgroundName: String
    let volcanoPosition: CGPoint
    let targets: [LevelTarget]
    let gridSize: CGSize
    let requiredTargets: Int
    
    static func allLevels() -> [Level] {
        return [
            Level(
                id: 1,
                name: "Volcanic Valley",
                difficulty: .veryEasy,
                backgroundName: "level1_bg",
                volcanoPosition: CGPoint(x: 0.5, y: 0.85),
                targets: [
                    LevelTarget(position: CGPoint(x: 0.2, y: 0.15), type: .village),
                    LevelTarget(position: CGPoint(x: 0.8, y: 0.15), type: .altar)
                ],
                gridSize: CGSize(width: 5, height: 7),
                requiredTargets: 1
            ),
            Level(
                id: 2,
                name: "Mystic Mountains",
                difficulty: .easy,
                backgroundName: "level2_bg",
                volcanoPosition: CGPoint(x: 0.5, y: 0.9),
                targets: [
                    LevelTarget(position: CGPoint(x: 0.15, y: 0.1), type: .garden),
                    LevelTarget(position: CGPoint(x: 0.5, y: 0.1), type: .village),
                    LevelTarget(position: CGPoint(x: 0.85, y: 0.1), type: .altar)
                ],
                gridSize: CGSize(width: 6, height: 8),
                requiredTargets: 2
            ),
            Level(
                id: 3,
                name: "Ancient Ruins",
                difficulty: .medium,
                backgroundName: "level3_bg",
                volcanoPosition: CGPoint(x: 0.3, y: 0.85),
                targets: [
                    LevelTarget(position: CGPoint(x: 0.7, y: 0.1), type: .altar),
                    LevelTarget(position: CGPoint(x: 0.2, y: 0.3), type: .village),
                    LevelTarget(position: CGPoint(x: 0.8, y: 0.5), type: .garden)
                ],
                gridSize: CGSize(width: 6, height: 9),
                requiredTargets: 2
            ),
            Level(
                id: 4,
                name: "Frozen Peaks",
                difficulty: .hard,
                backgroundName: "level4_bg",
                volcanoPosition: CGPoint(x: 0.5, y: 0.85),
                targets: [
                    LevelTarget(position: CGPoint(x: 0.3, y: 0.3), type: .village),
                    LevelTarget(position: CGPoint(x: 0.7, y: 0.3), type: .altar),
                    LevelTarget(position: CGPoint(x: 0.5, y: 0.15), type: .garden)
                ],
                gridSize: CGSize(width: 6, height: 8),
                requiredTargets: 2
            ),
            Level(
                id: 5,
                name: "Inferno Core",
                difficulty: .veryHard,
                backgroundName: "level5_bg",
                volcanoPosition: CGPoint(x: 0.5, y: 0.85),
                targets: [
                    LevelTarget(position: CGPoint(x: 0.2, y: 0.5), type: .village),
                    LevelTarget(position: CGPoint(x: 0.8, y: 0.5), type: .village),
                    LevelTarget(position: CGPoint(x: 0.2, y: 0.2), type: .altar),
                    LevelTarget(position: CGPoint(x: 0.8, y: 0.2), type: .altar),
                    LevelTarget(position: CGPoint(x: 0.5, y: 0.1), type: .garden)
                ],
                gridSize: CGSize(width: 7, height: 9),
                requiredTargets: 3
            )
        ]
    }
}

