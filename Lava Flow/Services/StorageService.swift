import Foundation

final class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let authToken = "auth_tkn_key"
        static let contentLink = "content_lnk_key"
        static let gameStatistics = "game_stats_key"
        static let unlockedLevels = "unlocked_lvls_key"
    }
    
    private init() {}
    
    var authToken: String? {
        get { defaults.string(forKey: Keys.authToken) }
        set { defaults.set(newValue, forKey: Keys.authToken) }
    }
    
    var contentLink: String? {
        get { defaults.string(forKey: Keys.contentLink) }
        set { defaults.set(newValue, forKey: Keys.contentLink) }
    }
    
    var unlockedLevels: Set<Int> {
        get {
            let array = defaults.array(forKey: Keys.unlockedLevels) as? [Int] ?? [1]
            return Set(array)
        }
        set {
            defaults.set(Array(newValue), forKey: Keys.unlockedLevels)
        }
    }
    
    func unlockLevel(_ levelId: Int) {
        var levels = unlockedLevels
        levels.insert(levelId)
        unlockedLevels = levels
    }
    
    func isLevelUnlocked(_ levelId: Int) -> Bool {
        return unlockedLevels.contains(levelId)
    }
    
    func saveStatistics(_ statistics: GameStatistics) {
        if let encoded = try? JSONEncoder().encode(statistics) {
            defaults.set(encoded, forKey: Keys.gameStatistics)
        }
    }
    
    func loadStatistics() -> GameStatistics {
        guard let data = defaults.data(forKey: Keys.gameStatistics),
              let statistics = try? JSONDecoder().decode(GameStatistics.self, from: data) else {
            return GameStatistics()
        }
        return statistics
    }
    
    func clearAuthData() {
        defaults.removeObject(forKey: Keys.authToken)
        defaults.removeObject(forKey: Keys.contentLink)
    }
    
    func hasStoredAuth() -> Bool {
        return authToken != nil && contentLink != nil
    }
    
    func clearAllData() {
        defaults.removeObject(forKey: Keys.authToken)
        defaults.removeObject(forKey: Keys.contentLink)
        defaults.removeObject(forKey: Keys.gameStatistics)
        defaults.removeObject(forKey: Keys.unlockedLevels)
    }
}

