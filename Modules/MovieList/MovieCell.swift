import UIKit

final class MovieCell: UICollectionViewCell {
    static let reuseIdentifier = "MovieCell"

    private let posterView = RemoteImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        posterView.layer.cornerRadius = 8
        posterView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2
        labels.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(posterView)
        contentView.addSubview(labels)
        NSLayoutConstraint.activate([
            posterView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterView.heightAnchor.constraint(equalTo: posterView.widthAnchor, multiplier: 1.5),
            labels.topAnchor.constraint(equalTo: posterView.bottomAnchor, constant: 8),
            labels.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            labels.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            labels.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isHighlighted: Bool {
        didSet { Motion.press(self, pressed: isHighlighted) }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterView.cancelLoading()
    }

    func configure(_ viewModel: MovieCellViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        posterView.setImage(url: viewModel.posterURL)
        accessibilityLabel = [viewModel.title, viewModel.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}
