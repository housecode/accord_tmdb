import Foundation

struct PageDTO<Item: Decodable>: Decodable {
    let page: Int
    let totalPages: Int
    let results: [Item]
}
