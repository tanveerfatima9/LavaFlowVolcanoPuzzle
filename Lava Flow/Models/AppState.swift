import Foundation

enum AppLaunchDestination {
    case game
    case contentDisplay(String)
}

struct AppConfiguration {
    var displayText: String?
    var displaySize: CGFloat?
    var contentLink: String?
    var authToken: String?
    
    var hasValidDisplayText: Bool {
        guard let text = displayText else { return false }
        return text.count >= 2
    }
}

