import Foundation

struct Review: Equatable {
    let id: String
    let author: String
    let rating: Double?
    let content: String
    let createdAt: String?
}

struct ReviewPage: Equatable {
    let reviews: [Review]
    let hasMore: Bool
}

struct ReviewDTO: Decodable {
    struct AuthorDetails: Decodable {
        let rating: Double?
    }

    let id: String
    let author: String?
    let authorDetails: AuthorDetails?
    let content: String?
    let createdAt: String?

    var entity: Review {
        Review(id: id,
               author: author ?? "Anonymous",
               rating: authorDetails?.rating,
               content: content ?? "",
               createdAt: createdAt)
    }
}

struct ReviewCellViewModel: Hashable {
    let id: String
    let author: String
    let ratingText: String?
    let content: String
    let dateText: String?
    let isTruncatable: Bool
    let isExpanded: Bool
}

enum ReviewsViewState {
    case loading
    case content(items: [ReviewCellViewModel], footer: ListFooter)
    case empty(String)
    case error(LoadError)
}
