import UIKit
import Combine

final class StatisticsViewController: UIViewController {
    
    private let viewModel: StatisticsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    var onBackTapped: (() -> Void)?
    
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1.0).cgColor
        ]
        return layer
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "STATISTICS"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private lazy var contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var overallStatsView: UIView = {
        let v = createStatCard(title: "OVERALL STATS")
        return v
    }()
    
    private lazy var gamesPlayedLabel: UILabel = createValueLabel()
    private lazy var gamesCompletedLabel: UILabel = createValueLabel()
    private lazy var completionRateLabel: UILabel = createValueLabel()
    private lazy var totalTimeLabel: UILabel = createValueLabel()
    
    init(viewModel: StatisticsViewModel) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh()
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
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupOverallStats()
        setupLevelStats()
    }
    
    private func setupOverallStats() {
        let card = createStatCard(title: "OVERALL STATISTICS")
        
        let statsStack = UIStackView()
        statsStack.axis = .vertical
        statsStack.spacing = 12
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        
        statsStack.addArrangedSubview(createStatRow(title: "Games Played:", valueLabel: gamesPlayedLabel))
        statsStack.addArrangedSubview(createStatRow(title: "Games Completed:", valueLabel: gamesCompletedLabel))
        statsStack.addArrangedSubview(createStatRow(title: "Completion Rate:", valueLabel: completionRateLabel))
        statsStack.addArrangedSubview(createStatRow(title: "Total Play Time:", valueLabel: totalTimeLabel))
        
        card.addSubview(statsStack)
        
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 50),
            statsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        contentStackView.addArrangedSubview(card)
    }
    
    private func setupLevelStats() {
        let sectionLabel = UILabel()
        sectionLabel.text = "LEVEL STATISTICS"
        sectionLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        sectionLabel.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sectionLabel)
        
        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            sectionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sectionLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        contentStackView.addArrangedSubview(container)
        
        for level in viewModel.levels {
            let levelCard = createLevelStatCard(for: level)
            contentStackView.addArrangedSubview(levelCard)
        }
    }
    
    private func createLevelStatCard(for level: Level) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.28, alpha: 1.0)
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Level \(level.id): \(level.name)"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statsStack = UIStackView()
        statsStack.axis = .vertical
        statsStack.spacing = 8
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        
        let stats = viewModel.getStatsForLevel(level.id)
        
        let timesPlayedLabel = createSmallValueLabel()
        timesPlayedLabel.text = "\(stats?.timesPlayed ?? 0)"
        statsStack.addArrangedSubview(createSmallStatRow(title: "Times Played:", valueLabel: timesPlayedLabel))
        
        let timesCompletedLabel = createSmallValueLabel()
        timesCompletedLabel.text = "\(stats?.timesCompleted ?? 0)"
        statsStack.addArrangedSubview(createSmallStatRow(title: "Completed:", valueLabel: timesCompletedLabel))
        
        let bestTimeLabel = createSmallValueLabel()
        bestTimeLabel.text = viewModel.formatTime(stats?.bestTime)
        statsStack.addArrangedSubview(createSmallStatRow(title: "Best Time:", valueLabel: bestTimeLabel))
        
        let lastPlayedLabel = createSmallValueLabel()
        lastPlayedLabel.text = viewModel.formatDate(stats?.lastPlayedDate)
        statsStack.addArrangedSubview(createSmallStatRow(title: "Last Played:", valueLabel: lastPlayedLabel))
        
        card.addSubview(titleLabel)
        card.addSubview(statsStack)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            
            statsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            statsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    private func createStatCard(title: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.28, alpha: 1.0)
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16)
        ])
        
        return card
    }
    
    private func createStatRow(title: String, valueLabel: UILabel) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLbl.textColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        
        row.addSubview(titleLbl)
        row.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 24),
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        
        return row
    }
    
    private func createSmallStatRow(title: String, valueLabel: UILabel) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLbl.textColor = UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        
        row.addSubview(titleLbl)
        row.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 20),
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        
        return row
    }
    
    private func createValueLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createSmallValueLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func bindViewModel() {
        viewModel.$statistics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStats()
            }
            .store(in: &cancellables)
    }
    
    private func updateStats() {
        gamesPlayedLabel.text = "\(viewModel.totalGamesPlayed)"
        gamesCompletedLabel.text = "\(viewModel.totalGamesCompleted)"
        completionRateLabel.text = String(format: "%.1f%%", viewModel.overallCompletionRate)
        totalTimeLabel.text = viewModel.totalPlayTimeString
    }
    
    @objc private func backTapped() {
        onBackTapped?()
    }
}

