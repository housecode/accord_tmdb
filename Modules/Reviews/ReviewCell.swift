import UIKit

final class ReviewCell: UICollectionViewCell {
    static let reuseIdentifier = "ReviewCell"

    var onToggle: (() -> Void)?

    private let authorLabel = UILabel()
    private let ratingLabel = UILabel()
    private let dateLabel = UILabel()
    private let contentLabel = UILabel()
    private let toggleButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        authorLabel.font = .preferredFont(forTextStyle: .headline)
        ratingLabel.font = .preferredFont(forTextStyle: .subheadline)
        ratingLabel.textColor = .systemOrange
        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .secondaryLabel
        contentLabel.font = .preferredFont(forTextStyle: .body)
        [authorLabel, ratingLabel, dateLabel, contentLabel].forEach { $0.adjustsFontForContentSizeCategory = true }
        authorLabel.numberOfLines = 0
        contentLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero
        toggleButton.configuration = configuration
        toggleButton.contentHorizontalAlignment = .leading
        toggleButton.addAction(UIAction { [weak self] _ in self?.onToggle?() }, for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [authorLabel, ratingLabel])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .firstBaseline

        let stack = UIStackView(arrangedSubviews: [header, dateLabel, contentLabel, toggleButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggleButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(_ viewModel: ReviewCellViewModel) {
        authorLabel.text = viewModel.author
        ratingLabel.text = viewModel.ratingText
        ratingLabel.isHidden = viewModel.ratingText == nil
        dateLabel.text = viewModel.dateText
        dateLabel.isHidden = viewModel.dateText == nil
        contentLabel.text = viewModel.content
        contentLabel.numberOfLines = viewModel.isTruncatable && !viewModel.isExpanded ? 5 : 0
        toggleButton.isHidden = !viewModel.isTruncatable
        toggleButton.configuration?.title = viewModel.isExpanded ? "Show less" : "Read more"
    }
}
