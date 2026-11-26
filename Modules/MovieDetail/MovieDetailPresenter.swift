import Foundation

@MainActor
final class MovieDetailPresenter: MovieDetailPresenterProtocol {
    weak var view: MovieDetailViewProtocol?
    private let movieID: Int
    private let interactor: MovieDetailInteractorProtocol
    private let router: MovieDetailRouterProtocol
    private var title = ""
    private var trailerKey: String?
    private var detailTask: Task<Void, Never>?
    private var trailerTask: Task<Void, Never>?

    init(movieID: Int, interactor: MovieDetailInteractorProtocol, router: MovieDetailRouterProtocol) {
        self.movieID = movieID
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        loadDetail()
        loadTrailer()
    }

    func retry() {
        loadDetail()
    }

    func retryTrailer() {
        loadTrailer()
    }

    func didTapTrailer() {
        guard let trailerKey else { return }
        router.showTrailer(videoKey: trailerKey, movieTitle: title)
    }

    func didTapReviews() {
        router.showReviews(movieID: movieID)
    }

    func viewDidClose() {
        detailTask?.cancel()
        trailerTask?.cancel()
    }

    // Detail and videos run as separate tasks so one failure never cancels the other.
    private func loadDetail() {
        detailTask?.cancel()
        view?.render(.loading)
        detailTask = Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await interactor.fetchDetail()
                title = detail.title
                view?.render(.content(makeViewModel(detail)))
            } catch is CancellationError {
                return
            } catch {
                view?.render(.error(LoadError(error)))
            }
        }
    }

    private func loadTrailer() {
        trailerTask?.cancel()
        trailerKey = nil
        view?.renderTrailer(.loading)
        trailerTask = Task { [weak self] in
            guard let self else { return }
            do {
                if let key = try await interactor.fetchTrailerKey() {
                    trailerKey = key
                    view?.renderTrailer(.available)
                } else {
                    view?.renderTrailer(.unavailable)
                }
            } catch is CancellationError {
                return
            } catch {
                view?.renderTrailer(.failed(LoadError(error).message))
            }
        }
    }

    private func makeViewModel(_ detail: MovieDetail) -> MovieDetailViewModel {
        var meta: [String] = []
        if let rating = MovieFormatter.rating(detail.voteAverage) {
            if let count = detail.voteCount, count > 0 {
                meta.append("★ \(rating) (\(count))")
            } else {
                meta.append("★ \(rating)")
            }
        }
        if let runtime = detail.runtime, runtime > 0 { meta.append("\(runtime / 60)h \(runtime % 60)m") }
        if let date = detail.releaseDate, !date.isEmpty { meta.append(date) }

        let tagline = detail.tagline.flatMap { $0.isEmpty ? nil : $0 }
        let overview = detail.overview.flatMap { $0.isEmpty ? nil : $0 } ?? "No overview available"
        let genres = detail.genres.map(\.name).joined(separator: ", ")
        return MovieDetailViewModel(title: detail.title,
                                    tagline: tagline,
                                    overview: overview,
                                    metaLine: meta.joined(separator: " · "),
                                    genresLine: genres.isEmpty ? nil : genres,
                                    imageURL: ImageURL.make(path: detail.backdropPath ?? detail.posterPath, size: .backdrop))
    }
}
