import UIKit

final class ReviewsViewController: StatefulViewController, ReviewsViewProtocol, UICollectionViewDelegate {
    private let presenter: ReviewsPresenterProtocol
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, ReviewCellViewModel>!
    private var footer: ListFooter = .none

    init(presenter: ReviewsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = presenter.title
        navigationItem.largeTitleDisplayMode = .never
        setUpCollectionView()
        stateView.onRetry = { [weak self] in self?.presenter.retry() }
        presenter.viewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { presenter.viewDidClose() }
    }

    func render(_ state: ReviewsViewState) {
        switch state {
        case .loading:
            stateView.showLoading()
        case .content(let items, let footer):
            self.footer = footer
            var snapshot = NSDiffableDataSourceSnapshot<Int, ReviewCellViewModel>()
            snapshot.appendSections([0])
            snapshot.appendItems(items)
            dataSource.apply(snapshot, animatingDifferences: !Motion.isReduced)
            collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter).forEach(configure)
            if !stateView.isHidden { Motion.crossFade(view) { self.stateView.hide() } }
        case .empty(let message):
            stateView.showEmpty(message: message)
        case .error(let error):
            stateView.showError(error)
        }
    }

    func endRefreshing() {
        collectionView.refreshControl?.endRefreshing()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        presenter.willDisplayItem(at: indexPath.item)
    }

    private func setUpCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .systemBackground
        // `footerMode = .supplementary` pins the footer to the screen; a boundary item stays at the end of the list.
        let layout = UICollectionViewCompositionalLayout { _, environment in
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            section.interGroupSpacing = 12
            section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64)),
                elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
            section.boundarySupplementaryItems = [footer]
            return section
        }
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in self?.presenter.refresh() }, for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.allowsSelection = false
        collectionView.register(ReviewCell.self, forCellWithReuseIdentifier: ReviewCell.reuseIdentifier)
        collectionView.register(FooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: FooterView.reuseIdentifier)
        view.insertSubview(collectionView, belowSubview: stateView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReviewCell.reuseIdentifier, for: indexPath)
            guard let reviewCell = cell as? ReviewCell else { return cell }
            reviewCell.configure(item)
            reviewCell.onToggle = { self?.presenter.toggleExpanded(id: item.id) }
            return reviewCell
        }
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: FooterView.reuseIdentifier, for: indexPath)
            self?.configure(footerView)
            return footerView
        }
    }

    private func configure(_ supplementary: UICollectionReusableView) {
        guard let footerView = supplementary as? FooterView else { return }
        footerView.configure(footer)
        footerView.onRetry = { [weak self] in self?.presenter.retry() }
    }
}
