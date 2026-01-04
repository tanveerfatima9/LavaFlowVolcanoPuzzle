import Foundation
import Combine

final class LevelSelectViewModel: ObservableObject {
    @Published var levels: [Level] = []
    @Published var unlockedLevels: Set<Int> = []
    
    private let storageService = StorageService.shared
    
    init() {
        loadLevels()
    }
    
    func loadLevels() {
        levels = Level.allLevels()
        unlockedLevels = storageService.unlockedLevels
    }
    
    func isLevelUnlocked(_ levelId: Int) -> Bool {
        return unlockedLevels.contains(levelId)
    }
    
    func selectLevel(_ level: Level, completion: @escaping (Level) -> Void) {
        guard isLevelUnlocked(level.id) else { return }
        completion(level)
    }
    
    func getLevelStatus(_ level: Level) -> LevelStatus {
        let stats = storageService.loadStatistics()
        if let levelStats = stats.levelStats[level.id] {
            if levelStats.timesCompleted > 0 {
                return .completed(stars: levelStats.bestStars)
            } else if levelStats.timesPlayed > 0 {
                return .attempted
            }
        }
        return isLevelUnlocked(level.id) ? .unlocked : .locked
    }
}

enum LevelStatus {
    case locked
    case unlocked
    case attempted
    case completed(stars: Int)
}

