import Foundation
import Combine

final class StatisticsViewModel: ObservableObject {
    @Published var statistics: GameStatistics
    @Published var levels: [Level] = []
    
    private let storageService = StorageService.shared
    
    init() {
        self.statistics = storageService.loadStatistics()
        self.levels = Level.allLevels()
    }
    
    func refresh() {
        statistics = storageService.loadStatistics()
    }
    
    func getStatsForLevel(_ levelId: Int) -> LevelStatistics? {
        return statistics.levelStats[levelId]
    }
    
    func formatTime(_ time: TimeInterval?) -> String {
        guard let time = time else { return "--:--" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var totalGamesPlayed: Int {
        return statistics.gamesStarted
    }
    
    var totalGamesCompleted: Int {
        return statistics.gamesCompleted
    }
    
    var overallCompletionRate: Double {
        guard statistics.gamesStarted > 0 else { return 0 }
        return Double(statistics.gamesCompleted) / Double(statistics.gamesStarted) * 100
    }
    
    var totalPlayTimeString: String {
        let hours = Int(statistics.totalPlayTime) / 3600
        let minutes = (Int(statistics.totalPlayTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

