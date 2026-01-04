import UIKit
import SpriteKit
import Combine

final class GamePlayViewController: UIViewController {
    
    private let viewModel: GameViewModel
    private var cancellables = Set<AnyCancellable>()
    private var gameScene: LavaGameScene?
    private var isSceneSetup = false
    
    var onBackTapped: (() -> Void)?
    var onLevelCompleted: ((GameResult) -> Void)?
    
    private lazy var skView: SKView = {
        let sv = SKView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.ignoresSiblingOrder = true
        return sv
    }()
    
    private lazy var topBarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 0.9)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var launchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("LAUNCH", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 1.0)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(launchTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.2, green: 0.25, blue: 0.4, alpha: 1.0)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resultOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    
    private lazy var resultContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.1, green: 0.14, blue: 0.25, alpha: 1.0)
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var resultTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var resultDetailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("CONTINUE", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("RETRY", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isSceneSetup && skView.bounds.size.width > 0 && skView.bounds.size.height > 0 {
            isSceneSetup = true
            setupGameScene()
            viewModel.startGame()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0)
        
        view.addSubview(skView)
        view.addSubview(topBarView)
        topBarView.addSubview(backButton)
        topBarView.addSubview(levelLabel)
        topBarView.addSubview(timerLabel)
        view.addSubview(launchButton)
        view.addSubview(resetButton)
        view.addSubview(resultOverlay)
        resultOverlay.addSubview(resultContainer)
        resultContainer.addSubview(resultTitleLabel)
        resultContainer.addSubview(resultDetailsLabel)
        resultContainer.addSubview(continueButton)
        resultContainer.addSubview(retryButton)
        
        levelLabel.text = "Level \(viewModel.currentLevel.id)"
        
        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 100),
            
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            levelLabel.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
            levelLabel.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -20),
            
            timerLabel.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16),
            timerLabel.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -20),
            
            skView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: launchButton.topAnchor, constant: -20),
            
            launchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            launchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            launchButton.widthAnchor.constraint(equalToConstant: 150),
            launchButton.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.centerYAnchor.constraint(equalTo: launchButton.centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44),
            
            resultOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            resultOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            resultContainer.centerXAnchor.constraint(equalTo: resultOverlay.centerXAnchor),
            resultContainer.centerYAnchor.constraint(equalTo: resultOverlay.centerYAnchor),
            resultContainer.widthAnchor.constraint(equalToConstant: 300),
            resultContainer.heightAnchor.constraint(equalToConstant: 280),
            
            resultTitleLabel.topAnchor.constraint(equalTo: resultContainer.topAnchor, constant: 30),
            resultTitleLabel.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            
            resultDetailsLabel.topAnchor.constraint(equalTo: resultTitleLabel.bottomAnchor, constant: 20),
            resultDetailsLabel.leadingAnchor.constraint(equalTo: resultContainer.leadingAnchor, constant: 20),
            resultDetailsLabel.trailingAnchor.constraint(equalTo: resultContainer.trailingAnchor, constant: -20),
            
            continueButton.bottomAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: resultContainer.leadingAnchor, constant: 20),
            continueButton.widthAnchor.constraint(equalToConstant: 120),
            continueButton.heightAnchor.constraint(equalToConstant: 44),
            
            retryButton.bottomAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: -20),
            retryButton.trailingAnchor.constraint(equalTo: resultContainer.trailingAnchor, constant: -20),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
            retryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupGameScene() {
        gameScene = LavaGameScene(size: skView.bounds.size, level: viewModel.currentLevel)
        gameScene?.scaleMode = .resizeFill
        gameScene?.gameDelegate = self
        skView.presentScene(gameScene)
    }
    
    private func bindViewModel() {
        viewModel.$elapsedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                let minutes = Int(time) / 60
                let seconds = Int(time) % 60
                self?.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
            }
            .store(in: &cancellables)
        
        viewModel.$gameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self, let result = result else { return }
                self.showResult(result)
            }
            .store(in: &cancellables)
    }
    
    private func showResult(_ result: GameResult) {
        resultOverlay.isHidden = false
        
        if result.completed {
            resultTitleLabel.text = "SUCCESS!"
            resultTitleLabel.textColor = UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)
            continueButton.isHidden = false
        } else {
            resultTitleLabel.text = "FAILED"
            resultTitleLabel.textColor = UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0)
            continueButton.isHidden = true
        }
        
        let starsText = result.completed ? "\n\(starsString(result.stars))" : ""
        
        resultDetailsLabel.text = """
        Time: \(result.timeString)
        Targets: \(result.targetsReached)/\(result.totalTargets) (need \(result.requiredTargets))
        Elements Used: \(result.elementsUsed)\(starsText)
        """
        
        resultOverlay.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.resultOverlay.alpha = 1
        }
    }
    
    private func starsString(_ count: Int) -> String {
        let filled = String(repeating: "⭐", count: count)
        let empty = String(repeating: "☆", count: 3 - count)
        return filled + empty
    }
    
    @objc private func backTapped() {
        viewModel.stopGame()
        onBackTapped?()
    }
    
    @objc private func launchTapped() {
        gameScene?.launchLava()
    }
    
    @objc private func resetTapped() {
        viewModel.resetLevel()
        gameScene?.resetLevel()
        viewModel.startGame()
    }
    
    @objc private func continueTapped() {
        if let result = viewModel.gameResult {
            onLevelCompleted?(result)
        }
    }
    
    @objc private func retryTapped() {
        resultOverlay.isHidden = true
        viewModel.resetLevel()
        gameScene?.resetLevel()
        viewModel.startGame()
    }
}

extension GamePlayViewController: LavaGameSceneDelegate {
    func gameScene(_ scene: LavaGameScene, didComplete targetsReached: Int, totalTargets: Int, elementsUsed: Int) {
        viewModel.completeLevel(targetsReached: targetsReached, totalTargets: totalTargets, elementsUsed: elementsUsed)
    }
}

