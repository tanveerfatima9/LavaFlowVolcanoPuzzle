import Foundation
import Combine

final class MainMenuViewModel: ObservableObject {
    @Published var displayText: String?
    @Published var displaySize: CGFloat?
    @Published var isLoading: Bool = false
    
    var shouldShowLabel: Bool {
        guard let text = displayText else { return false }
        return text.count >= 2
    }
    
    init(displayText: String? = nil, displaySize: CGFloat? = nil) {
        self.displayText = displayText
        self.displaySize = displaySize
    }
    
    func onPlayTapped(completion: @escaping () -> Void) {
        completion()
    }
    
    func onStatisticsTapped(completion: @escaping () -> Void) {
        completion()
    }
}

