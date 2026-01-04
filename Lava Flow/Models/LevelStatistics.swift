import Foundation

struct LevelStatistics: Codable {
    let levelId: Int
    var timesPlayed: Int
    var timesCompleted: Int
    var bestTime: TimeInterval?
    var totalTargetsReached: Int
    var elementsUsed: Int
    var lastPlayedDate: Date?
    var bestStars: Int
    
    var completionRate: Double {
        guard timesPlayed > 0 else { return 0 }
        return Double(timesCompleted) / Double(timesPlayed) * 100
    }
    
    init(levelId: Int) {
        self.levelId = levelId
        self.timesPlayed = 0
        self.timesCompleted = 0
        self.bestTime = nil
        self.totalTargetsReached = 0
        self.elementsUsed = 0
        self.lastPlayedDate = nil
        self.bestStars = 0
    }
    
    mutating func recordGame(completed: Bool, time: TimeInterval, targetsReached: Int, elements: Int, stars: Int) {
        timesPlayed += 1
        if completed {
            timesCompleted += 1
        }
        if let currentBest = bestTime {
            if time < currentBest && completed {
                bestTime = time
            }
        } else if completed {
            bestTime = time
        }
        totalTargetsReached += targetsReached
        elementsUsed += elements
        lastPlayedDate = Date()
        if stars > bestStars {
            bestStars = stars
        }
    }
}

struct GameStatistics: Codable {
    var levelStats: [Int: LevelStatistics]
    var totalPlayTime: TimeInterval
    var gamesStarted: Int
    var gamesCompleted: Int
    
    init() {
        self.levelStats = [:]
        self.totalPlayTime = 0
        self.gamesStarted = 0
        self.gamesCompleted = 0
    }
    
    mutating func getOrCreateStats(for levelId: Int) -> LevelStatistics {
        if let stats = levelStats[levelId] {
            return stats
        }
        let newStats = LevelStatistics(levelId: levelId)
        levelStats[levelId] = newStats
        return newStats
    }
    
    mutating func updateStats(for levelId: Int, completed: Bool, time: TimeInterval, targetsReached: Int, elements: Int, stars: Int) {
        var stats = getOrCreateStats(for: levelId)
        stats.recordGame(completed: completed, time: time, targetsReached: targetsReached, elements: elements, stars: stars)
        levelStats[levelId] = stats
        totalPlayTime += time
        gamesStarted += 1
        if completed {
            gamesCompleted += 1
        }
    }
}

