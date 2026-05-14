import UIKit

final class BottomSheetView: UIView {

    var onCategorySelected: ((String?) -> Void)?
    var onCancel: (() -> Void)?

    // 최근 사용 3개 + 미분류함 (UserDefaults from App Group)
    private var recentCategories: [CategoryItem] = []

    private let containerView = UIView()
    private let handleView = UIView()
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private let aiMagicButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadRecentCategories()
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        handleView.backgroundColor = UIColor.tertiaryLabel
        handleView.layer.cornerRadius = 2.5
        handleView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(handleView)

        titleLabel.text = "어디에 저장할까요?"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        for item in recentCategories {
            stackView.addArrangedSubview(makeCategoryButton(item))
        }

        var aiConfig = UIButton.Configuration.filled()
        aiConfig.title = "📦  AI 매직박스에 넣기"
        aiConfig.baseBackgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)
        aiConfig.baseForegroundColor = .systemIndigo
        aiConfig.cornerStyle = .large
        aiConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        aiMagicButton.configuration = aiConfig
        aiMagicButton.addTarget(self, action: #selector(aiMagicTapped), for: .touchUpInside)
        aiMagicButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(aiMagicButton)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.tintColor = .secondaryLabel
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.heightAnchor.constraint(equalToConstant: 80),

            aiMagicButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            aiMagicButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            aiMagicButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            cancelButton.topAnchor.constraint(equalTo: aiMagicButton.bottomAnchor, constant: 8),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    private func makeCategoryButton(_ item: CategoryItem) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = item.name
        config.subtitle = item.emoji
        config.titleAlignment = .center
        config.baseBackgroundColor = UIColor.secondarySystemBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .large

        let btn = UIButton(configuration: config)
        btn.addAction(UIAction { [weak self] _ in
            self?.categoryTapped(item.name)
        }, for: .touchUpInside)
        return btn
    }

    // MARK: - Data

    private func loadRecentCategories() {
        guard let defaults = UserDefaults(suiteName: SharedQueue.appGroupID) else {
            recentCategories = defaultFallback()
            return
        }
        let recent = defaults.stringArray(forKey: "recent_categories") ?? []
        let all: [CategoryItem] = [
            ("패션", "🪞"), ("카페·맛집", "☕"), ("공부·자기계발", "📚"),
            ("여행", "✈️"), ("인테리어", "🏠"),
        ]
        let sorted = all.filter { recent.contains($0.name) } + all.filter { !recent.contains($0.name) }
        recentCategories = Array(sorted.prefix(3))
    }

    private func defaultFallback() -> [CategoryItem] {
        [("패션", "🪞"), ("카페·맛집", "☕"), ("공부·자기계발", "📚")]
    }

    private func saveRecentCategory(_ name: String) {
        guard let defaults = UserDefaults(suiteName: SharedQueue.appGroupID) else { return }
        var recent = defaults.stringArray(forKey: "recent_categories") ?? []
        recent.removeAll { $0 == name }
        recent.insert(name, at: 0)
        defaults.set(Array(recent.prefix(3)), forKey: "recent_categories")
    }

    // MARK: - Actions

    private func categoryTapped(_ name: String) {
        saveRecentCategory(name)
        onCategorySelected?(name)
    }

    @objc private func aiMagicTapped() {
        onCategorySelected?(nil)
    }

    @objc private func cancelTapped() {
        onCancel?()
    }
}

private typealias CategoryItem = (name: String, emoji: String)
