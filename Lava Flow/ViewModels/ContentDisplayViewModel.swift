import Foundation
import Combine

final class ContentDisplayViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var contentPath: String
    
    init(path: String) {
        self.contentPath = path
    }
    
    func didFinishLoading() {
        isLoading = false
    }
    
    func didStartLoading() {
        isLoading = true
    }
}

