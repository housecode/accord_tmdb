import UIKit

final class GenresViewController: StatefulViewController, GenresViewProtocol, UITableViewDelegate {
    private let presenter: GenresPresenterProtocol
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var dataSource = makeDataSource()

    init(presenter: GenresPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = presenter.title
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in self?.presenter.refresh() }, for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GenreCell")
        view.insertSubview(tableView, belowSubview: stateView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        stateView.onRetry = { [weak self] in self?.presenter.retry() }
        presenter.viewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { presenter.viewDidClose() }
    }

    func render(_ state: ScreenState<[GenreRowViewModel]>) {
        switch state {
        case .loading:
            stateView.showLoading()
        case .content(let rows):
            var snapshot = NSDiffableDataSourceSnapshot<Int, GenreRowViewModel>()
            snapshot.appendSections([0])
            snapshot.appendItems(rows)
            dataSource.apply(snapshot, animatingDifferences: false)
            Motion.crossFade(view) { self.stateView.hide() }
        case .empty(let message):
            stateView.showEmpty(message: message)
        case .error(let error):
            stateView.showError(error)
        }
    }

    func endRefreshing() {
        tableView.refreshControl?.endRefreshing()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return }
        presenter.didSelectGenre(id: row.id)
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Int, GenreRowViewModel> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, row in
            let cell = tableView.dequeueReusableCell(withIdentifier: "GenreCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = row.name
            content.textProperties.adjustsFontForContentSizeCategory = true
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
}
