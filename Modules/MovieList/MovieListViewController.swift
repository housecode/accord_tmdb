import UIKit

final class MovieListViewController: StatefulViewController, MovieListViewProtocol, UICollectionViewDelegate {
    private let presenter: MovieListPresenterProtocol
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, MovieCellViewModel>!
    private var footer: ListFooter = .none

    init(presenter: MovieListPresenterProtocol) {
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

    func render(_ state: MovieListViewState) {
        switch state {
        case .loading:
            stateView.showLoading()
        case .content(let items, let footer):
            self.footer = footer
            var snapshot = NSDiffableDataSourceSnapshot<Int, MovieCellViewModel>()
            snapshot.appendSections([0])
            snapshot.appendItems(items)
            dataSource.apply(snapshot, animatingDifferences: !Motion.isReduced)
            updateVisibleFooter()
            if !stateView.isHidden { Motion.crossFade(view) { self.stateView.hide() } }
        case .empty(let message):
            stateView.showEmpty(message: message)
        case .error(let error):
            stateView.showError(error)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        presenter.didSelectMovie(id: item.id)
    }

    func endRefreshing() {
        collectionView.refreshControl?.endRefreshing()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        presenter.willDisplayItem(at: indexPath.item)
    }

    private func setUpCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in self?.presenter.refresh() }, for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseIdentifier)
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

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseIdentifier, for: indexPath)
            (cell as? MovieCell)?.configure(item)
            return cell
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

    private func updateVisibleFooter() {
        collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter).forEach(configure)
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let columns = environment.container.effectiveContentSize.width > 700 ? 4 : 2
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                                                                heightDimension: .estimated(280)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                             heightDimension: .estimated(280)),
                                                           repeatingSubitem: item, count: columns)
            group.interItemSpacing = .fixed(16)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64)),
                elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
            section.boundarySupplementaryItems = [footerItem]
            return section
        }
    }
}
