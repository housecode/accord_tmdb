import Foundation

struct Genre: Equatable, Hashable {
    let id: Int
    let name: String
}

struct GenreDTO: Decodable {
    let id: Int
    let name: String

    var entity: Genre { Genre(id: id, name: name) }
}
