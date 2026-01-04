import UIKit
import Combine

final class MainMenuViewController: UIViewController {
    
    private let viewModel: MainMenuViewModel
    private var cancellables = Set<AnyCancellable>()
    
    var onPlayTapped: (() -> Void)?
    var onStatisticsTapped: (() -> Void)?
    
    private lazy var backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1.0).cgColor
        ]
        layer.locations = [0.0, 0.5, 1.0]
        return layer
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "LAVA FLOW"
        label.font = UIFont.systemFont(ofSize: 42, weight: .black)
        label.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.shadowColor = UIColor.orange.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 10
        label.layer.shadowOpacity = 0.8
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Launch the Volcano!"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var displayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("PLAY", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 1.0)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.orange.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var statisticsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("STATISTICS", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 1.0)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(statisticsTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("RESET DATA", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(UIColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.1, blue: 0.1, alpha: 0.8)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var volcanoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = UIColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 0.3)
        let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
        iv.image = UIImage(systemName: "flame.fill", withConfiguration: config)
        return iv
    }()
    
    init(viewModel: MainMenuViewModel) {
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
        gradientLayer.frame = view.bounds
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func setupUI() {
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(volcanoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(displayLabel)
        view.addSubview(playButton)
        view.addSubview(statisticsButton)
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            volcanoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            volcanoImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 50),
            volcanoImageView.widthAnchor.constraint(equalToConstant: 250),
            volcanoImageView.heightAnchor.constraint(equalToConstant: 250),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            displayLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            displayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            displayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            displayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            statisticsButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
            statisticsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statisticsButton.widthAnchor.constraint(equalToConstant: 180),
            statisticsButton.heightAnchor.constraint(equalToConstant: 44),
            
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 140),
            resetButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        animateVolcano()
    }
    
    private func bindViewModel() {
        viewModel.$displayText
            .combineLatest(viewModel.$displaySize)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text, size in
                guard let self = self else { return }
                if let text = text, text.count >= 2, let size = size {
                    self.displayLabel.text = text
                    self.displayLabel.font = UIFont.systemFont(ofSize: size, weight: .medium)
                    self.displayLabel.isHidden = false
                } else {
                    self.displayLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func animateVolcano() {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.volcanoImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.volcanoImageView.alpha = 0.5
        })
    }
    
    @objc private func playTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.playButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playButton.transform = .identity
            }
            self.onPlayTapped?()
        }
    }
    
    @objc private func statisticsTapped() {
        onStatisticsTapped?()
    }
    
    @objc private func resetTapped() {
        let alert = UIAlertController(
            title: "Reset All Data",
            message: "This will delete all progress, statistics and unlocked levels. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            StorageService.shared.clearAllData()
            
            let confirmAlert = UIAlertController(
                title: "Done",
                message: "All data has been deleted",
                preferredStyle: .alert
            )
            confirmAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(confirmAlert, animated: true)
        })
        
        present(alert, animated: true)
    }
}

