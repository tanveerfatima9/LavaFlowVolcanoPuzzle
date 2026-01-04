import UIKit
import AppsFlyerLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppsFlyerLib.shared().appsFlyerDevKey = "kewcnVMN5kswP3zw4jAH8a"
        AppsFlyerLib.shared().appleAppID = "6757359430"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().isDebug = false
        AppsFlyerLib.shared().start()
        
        let mainWindow = UIWindow(frame: UIScreen.main.bounds)
        window = mainWindow
        
        appCoordinator = AppCoordinator(window: mainWindow)
        appCoordinator?.start()
        
        return true
    }
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        if let status = conversionInfo["af_status"] as? String {
            if status == "Non-organic" {
                if let sourceID = conversionInfo["media_source"],
                   let campaign = conversionInfo["campaign"] {
                    print("Conversion: \(sourceID), \(campaign)")
                }
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        print("Conversion data error: \(error.localizedDescription)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootVC = window?.rootViewController {
            if rootVC is ContentDisplayViewController {
                return .all
            }
            if let navVC = rootVC as? UINavigationController {
                if navVC.topViewController is ContentDisplayViewController {
                    return .all
                }
            }
        }
        return .portrait
    }
}
