import UIKit
import Combine

final class LevelSelectViewController: UIViewController {
    
    private let viewModel: LevelSelectViewModel
    private var cancellables = Set<AnyCancellable>()
    
    var onLevelSelected: ((Level) -> Void)?
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
        label.text = "SELECT LEVEL"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(LevelCell.self, forCellWithReuseIdentifier: LevelCell.identifier)
        return cv
    }()
    
    init(viewModel: LevelSelectViewModel) {
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
        viewModel.loadLevels()
        collectionView.reloadData()
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
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        viewModel.$levels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    @objc private func backTapped() {
        onBackTapped?()
    }
}

extension LevelSelectViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.levels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LevelCell.identifier, for: indexPath) as? LevelCell else {
            return UICollectionViewCell()
        }
        let level = viewModel.levels[indexPath.item]
        let status = viewModel.getLevelStatus(level)
        cell.configure(with: level, status: status)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20) / 2
        return CGSize(width: width, height: width * 1.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = viewModel.levels[indexPath.item]
        viewModel.selectLevel(level) { [weak self] selectedLevel in
            self?.onLevelSelected?(selectedLevel)
        }
    }
}

final class LevelCell: UICollectionViewCell {
    static let identifier = "LevelCell"
    
    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.28, alpha: 1.0)
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var levelNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var levelNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var starsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        sv.distribution = .equalSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var lockImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        iv.image = UIImage(systemName: "lock.fill", withConfiguration: config)
        iv.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    private lazy var difficultyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(levelNumberLabel)
        containerView.addSubview(levelNameLabel)
        containerView.addSubview(starsStackView)
        containerView.addSubview(lockImageView)
        containerView.addSubview(difficultyLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            levelNumberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            levelNumberLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            levelNameLabel.topAnchor.constraint(equalTo: levelNumberLabel.bottomAnchor, constant: 8),
            levelNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            levelNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            difficultyLabel.topAnchor.constraint(equalTo: levelNameLabel.bottomAnchor, constant: 8),
            difficultyLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            starsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            starsStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            starsStackView.heightAnchor.constraint(equalToConstant: 20),
            
            lockImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with level: Level, status: LevelStatus) {
        levelNumberLabel.text = "\(level.id)"
        levelNameLabel.text = level.name
        
        let difficultyTexts = ["Very Easy", "Easy", "Medium", "Hard", "Very Hard"]
        difficultyLabel.text = difficultyTexts[level.difficulty.rawValue - 1]
        
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch status {
        case .locked:
            containerView.layer.borderColor = UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0).cgColor
            containerView.alpha = 0.6
            lockImageView.isHidden = false
            levelNumberLabel.isHidden = true
            levelNameLabel.isHidden = true
            difficultyLabel.isHidden = true
            
        case .unlocked:
            containerView.layer.borderColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0).cgColor
            containerView.alpha = 1.0
            lockImageView.isHidden = true
            levelNumberLabel.isHidden = false
            levelNameLabel.isHidden = false
            difficultyLabel.isHidden = false
            addStars(count: 0, total: 3)
            
        case .attempted:
            containerView.layer.borderColor = UIColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0).cgColor
            containerView.alpha = 1.0
            lockImageView.isHidden = true
            levelNumberLabel.isHidden = false
            levelNameLabel.isHidden = false
            difficultyLabel.isHidden = false
            addStars(count: 0, total: 3)
            
        case .completed(let stars):
            containerView.layer.borderColor = UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0).cgColor
            containerView.alpha = 1.0
            lockImageView.isHidden = true
            levelNumberLabel.isHidden = false
            levelNameLabel.isHidden = false
            difficultyLabel.isHidden = false
            addStars(count: stars, total: 3)
        }
    }
    
    private func addStars(count: Int, total: Int) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        for i in 0..<total {
            let iv = UIImageView()
            if i < count {
                iv.image = UIImage(systemName: "star.fill", withConfiguration: config)
                iv.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            } else {
                iv.image = UIImage(systemName: "star", withConfiguration: config)
                iv.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
            }
            starsStackView.addArrangedSubview(iv)
        }
    }
}

