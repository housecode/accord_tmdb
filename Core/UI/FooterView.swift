import UIKit

/// Bottom row of a paged list: spinner while loading more, or a message with Retry after a failed page.
final class FooterView: UICollectionReusableView {
    static let reuseIdentifier = "FooterView"

    var onRetry: (() -> Void)?

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()
    private let retryButton = UIButton(type: .system)
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0

        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Retry"
        retryButton.configuration = configuration
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        [spinner, label, retryButton].forEach(stack.addArrangedSubview)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(_ footer: ListFooter) {
        switch footer {
        case .none:
            spinner.stopAnimating()
            stack.isHidden = true
        case .loadingMore:
            stack.isHidden = false
            spinner.startAnimating()
            spinner.isHidden = false
            label.isHidden = true
            retryButton.isHidden = true
        case .retry(let message):
            stack.isHidden = false
            spinner.stopAnimating()
            spinner.isHidden = true
            label.text = message
            label.isHidden = false
            retryButton.isHidden = false
        }
    }
}
