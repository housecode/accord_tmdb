import UIKit

final class MovieDetailViewController: StatefulViewController, MovieDetailViewProtocol {
    private let presenter: MovieDetailPresenterProtocol
    private let scrollView = UIScrollView()
    private let backdropView = RemoteImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let genresLabel = UILabel()
    private let taglineLabel = UILabel()
    private let overviewLabel = UILabel()
    private let trailerButton = UIButton(type: .system)
    private let reviewsButton = UIButton(type: .system)
    private var trailerState: TrailerButtonState = .loading

    init(presenter: MovieDetailPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setUpContent()
        stateView.onRetry = { [weak self] in self?.presenter.retry() }
        presenter.viewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { presenter.viewDidClose() }
    }

    func render(_ state: ScreenState<MovieDetailViewModel>) {
        switch state {
        case .loading:
            stateView.showLoading()
        case .content(let model):
            title = model.title
            titleLabel.text = model.title
            metaLabel.text = model.metaLine
            metaLabel.isHidden = model.metaLine.isEmpty
            genresLabel.text = model.genresLine
            genresLabel.isHidden = model.genresLine == nil
            taglineLabel.text = model.tagline
            taglineLabel.isHidden = model.tagline == nil
            overviewLabel.text = model.overview
            backdropView.setImage(url: model.imageURL)
            Motion.crossFade(view) { self.stateView.hide() }
        case .empty(let message):
            stateView.showEmpty(message: message)
        case .error(let error):
            stateView.showError(error)
        }
    }

    func renderTrailer(_ state: TrailerButtonState) {
        trailerState = state
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "play.fill")
        configuration.imagePadding = 8
        switch state {
        case .loading:
            configuration.title = "Loading trailer"
            trailerButton.isEnabled = false
        case .available:
            configuration.title = "Watch Trailer"
            trailerButton.isEnabled = true
        case .unavailable:
            configuration.title = "Trailer not available"
            configuration.image = nil
            trailerButton.isEnabled = false
        case .failed(let message):
            configuration.title = "\(message). Retry"
            configuration.image = UIImage(systemName: "arrow.clockwise")
            trailerButton.isEnabled = true
        }
        trailerButton.configuration = configuration
    }

    private func setUpContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(scrollView, belowSubview: stateView)

        backdropView.translatesAutoresizingMaskIntoConstraints = false
        style(titleLabel, textStyle: .title2, weight: .bold)
        style(metaLabel, textStyle: .subheadline, color: .secondaryLabel)
        style(genresLabel, textStyle: .subheadline, color: .secondaryLabel)
        style(taglineLabel, textStyle: .callout, color: .secondaryLabel)
        taglineLabel.font = .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .callout).pointSize)
        style(overviewLabel, textStyle: .body)

        trailerButton.addAction(UIAction { [weak self] _ in self?.trailerTapped() }, for: .touchUpInside)
        var reviewsConfiguration = UIButton.Configuration.tinted()
        reviewsConfiguration.title = "Reviews"
        reviewsConfiguration.image = UIImage(systemName: "text.bubble")
        reviewsConfiguration.imagePadding = 8
        reviewsButton.configuration = reviewsConfiguration
        reviewsButton.addAction(UIAction { [weak self] _ in self?.presenter.didTapReviews() }, for: .touchUpInside)
        renderTrailer(.loading)

        let buttons = UIStackView(arrangedSubviews: [trailerButton, reviewsButton])
        buttons.axis = .vertical
        buttons.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [titleLabel, metaLabel, genresLabel, buttons, taglineLabel, overviewLabel])
        textStack.axis = .vertical
        textStack.spacing = 12
        textStack.isLayoutMarginsRelativeArrangement = true
        textStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

        let content = UIStackView(arrangedSubviews: [backdropView, textStack])
        content.axis = .vertical
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            backdropView.heightAnchor.constraint(equalTo: backdropView.widthAnchor, multiplier: 9.0 / 16.0),
            trailerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            reviewsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func trailerTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if case .failed = trailerState {
            presenter.retryTrailer()
        } else {
            presenter.didTapTrailer()
        }
    }

    private func style(_ label: UILabel, textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil, color: UIColor = .label) {
        let base = UIFont.preferredFont(forTextStyle: textStyle)
        if let weight {
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
            label.font = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
        } else {
            label.font = base
        }
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
    }
}
