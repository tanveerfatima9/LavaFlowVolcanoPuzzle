import UIKit

final class AppCoordinator {
    
    private let window: UIWindow
    private var navigationController: UINavigationController?
    private var displayText: String?
    private var displaySize: CGFloat?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        showLoading()
        checkRoute()
    }
    
    private func showLoading() {
        let loadingVC = LoadingViewController()
        window.rootViewController = loadingVC
        window.makeKeyAndVisible()
    }
    
    private func checkRoute() {
        NetworkService.shared.checkInitialRoute { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .showGame:
                self.showMainMenu()
                
            case .showContent(_, let link):
                self.showContentDisplay(path: link)
                
            case .showGameWithLabel(let text, let size):
                self.displayText = text
                self.displaySize = size
                self.showMainMenu()
            }
        }
    }
    
    private func showMainMenu() {
        let viewModel = MainMenuViewModel(displayText: displayText, displaySize: displaySize)
        let mainMenuVC = MainMenuViewController(viewModel: viewModel)
        
        mainMenuVC.onPlayTapped = { [weak self] in
            self?.showLevelSelect()
        }
        
        mainMenuVC.onStatisticsTapped = { [weak self] in
            self?.showStatistics()
        }
        
        let navController = UINavigationController(rootViewController: mainMenuVC)
        navController.setNavigationBarHidden(true, animated: false)
        navigationController = navController
        
        window.rootViewController = navController
    }
    
    private func showLevelSelect() {
        let viewModel = LevelSelectViewModel()
        let levelSelectVC = LevelSelectViewController(viewModel: viewModel)
        
        levelSelectVC.onLevelSelected = { [weak self] level in
            self?.showGame(level: level)
        }
        
        levelSelectVC.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        navigationController?.pushViewController(levelSelectVC, animated: true)
    }
    
    private func showGame(level: Level) {
        let viewModel = GameViewModel(level: level)
        let gameVC = GamePlayViewController(viewModel: viewModel)
        
        gameVC.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        gameVC.onLevelCompleted = { [weak self] result in
            self?.handleLevelCompleted(result: result)
        }
        
        navigationController?.pushViewController(gameVC, animated: true)
    }
    
    private func handleLevelCompleted(result: GameResult) {
        if result.completed && result.levelId < 5 {
            let nextLevel = Level.allLevels()[result.levelId]
            navigationController?.popViewController(animated: false)
            showGame(level: nextLevel)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func showStatistics() {
        let viewModel = StatisticsViewModel()
        let statsVC = StatisticsViewController(viewModel: viewModel)
        
        statsVC.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        navigationController?.pushViewController(statsVC, animated: true)
    }
    
    private func showContentDisplay(path: String) {
        let viewModel = ContentDisplayViewModel(path: path)
        let contentVC = ContentDisplayViewController(viewModel: viewModel)
        
        window.rootViewController = contentVC
    }
}

final class LoadingViewController: UIViewController {
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .white
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.startAnimating()
        return ai
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0)
        
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

