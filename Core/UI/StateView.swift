import UIKit

/// Full-screen overlay for the loading, empty, and error states.
final class StateView: UIView {
    var onRetry: (() -> Void)?

    private let spinner = UIActivityIndicatorView(style: .large)
    private let iconView = UIImageView()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func showLoading() {
        stack.isHidden = true
        spinner.startAnimating()
        isHidden = false
        accessibilityLabel = "Loading"
    }

    func showEmpty(message: String) {
        show(symbol: "tray", message: message, canRetry: false)
    }

    func showError(_ error: LoadError) {
        show(symbol: "exclamationmark.triangle", message: error.message, canRetry: error.isRetryable)
    }

    func hide() {
        spinner.stopAnimating()
        isHidden = true
    }

    private func show(symbol: String, message: String, canRetry: Bool) {
        spinner.stopAnimating()
        iconView.image = UIImage(systemName: symbol)
        messageLabel.text = message
        retryButton.isHidden = !canRetry
        stack.isHidden = false
        isHidden = false
    }

    private func setUp() {
        backgroundColor = .systemBackground
        spinner.translatesAutoresizingMaskIntoConstraints = false

        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40)

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Retry"
        retryButton.configuration = configuration
        retryButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onRetry?()
        }, for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        [iconView, messageLabel, retryButton].forEach(stack.addArrangedSubview)

        addSubview(spinner)
        addSubview(stack)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        isAccessibilityElement = false
        accessibilityViewIsModal = true
    }
}
