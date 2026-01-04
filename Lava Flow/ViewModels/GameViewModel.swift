import Foundation
import Combine

final class GameViewModel: ObservableObject {
    @Published var currentLevel: Level
    @Published var availableElements: [GameElement] = []
    @Published var placedElements: [GameElement] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPlaying: Bool = false
    @Published var isPaused: Bool = false
    @Published var gameResult: GameResult?
    @Published var targetsReached: Int = 0
    
    private var timer: Timer?
    private let storageService = StorageService.shared
    
    init(level: Level) {
        self.currentLevel = level
        setupAvailableElements()
    }
    
    private func setupAvailableElements() {
        availableElements = []
        let elementTypes = GameElementType.allCases
        let count = currentLevel.difficulty.availableElements
        
        for i in 0..<count {
            let type = elementTypes[i % elementTypes.count]
            let element = GameElement(type: type)
            availableElements.append(element)
        }
    }
    
    func startGame() {
        isPlaying = true
        isPaused = false
        gameResult = nil
        elapsedTime = 0
        targetsReached = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.elapsedTime += 0.1
        }
    }
    
    func pauseGame() {
        isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
    }
    
    func stopGame() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
    
    func placeElement(_ element: GameElement, at position: CGPoint) {
        guard !element.isPlaced else { return }
        element.gridPosition = position
        element.isPlaced = true
        placedElements.append(element)
        
        if let index = availableElements.firstIndex(where: { $0 === element }) {
            availableElements.remove(at: index)
        }
    }
    
    func removeElement(_ element: GameElement) {
        guard element.isPlaced else { return }
        element.isPlaced = false
        
        if let index = placedElements.firstIndex(where: { $0 === element }) {
            placedElements.remove(at: index)
        }
        availableElements.append(element)
    }
    
    func launchLava(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func completeLevel(targetsReached: Int, totalTargets: Int, elementsUsed: Int) {
        stopGame()
        
        let completed = targetsReached >= currentLevel.requiredTargets
        self.targetsReached = targetsReached
        
        let stars = calculateStars(
            completed: completed,
            targetsReached: targetsReached,
            totalTargets: totalTargets,
            requiredTargets: currentLevel.requiredTargets,
            elementsUsed: elementsUsed,
            availableElements: currentLevel.difficulty.availableElements,
            time: elapsedTime
        )
        
        var statistics = storageService.loadStatistics()
        statistics.updateStats(
            for: currentLevel.id,
            completed: completed,
            time: elapsedTime,
            targetsReached: targetsReached,
            elements: elementsUsed,
            stars: stars
        )
        storageService.saveStatistics(statistics)
        
        if completed && currentLevel.id < 5 {
            storageService.unlockLevel(currentLevel.id + 1)
        }
        
        gameResult = GameResult(
            levelId: currentLevel.id,
            completed: completed,
            time: elapsedTime,
            targetsReached: targetsReached,
            totalTargets: totalTargets,
            requiredTargets: currentLevel.requiredTargets,
            elementsUsed: elementsUsed,
            stars: stars
        )
    }
    
    private func calculateStars(completed: Bool, targetsReached: Int, totalTargets: Int, requiredTargets: Int, elementsUsed: Int, availableElements: Int, time: TimeInterval) -> Int {
        guard completed else { return 0 }
        
        var stars = 1
        
        if targetsReached >= totalTargets {
            stars += 1
        }
        
        let elementEfficiency = Double(elementsUsed) / Double(availableElements)
        if elementEfficiency <= 0.7 && time < 60 {
            stars += 1
        } else if elementEfficiency <= 0.85 || time < 90 {
            if stars < 3 {
                stars = min(stars + 1, 2)
            }
        }
        
        return min(stars, 3)
    }
    
    func resetLevel() {
        stopGame()
        placedElements.removeAll()
        setupAvailableElements()
        gameResult = nil
        elapsedTime = 0
        targetsReached = 0
    }
}

struct GameResult {
    let levelId: Int
    let completed: Bool
    let time: TimeInterval
    let targetsReached: Int
    let totalTargets: Int
    let requiredTargets: Int
    let elementsUsed: Int
    let stars: Int
    
    var timeString: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

