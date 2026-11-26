import Foundation

enum MovieFormatter {
    static func year(from releaseDate: String?) -> String? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return String(releaseDate.prefix(4))
    }

    static func rating(_ value: Double?) -> String? {
        guard let value, value > 0 else { return nil }
        return String(format: "%.1f", value)
    }

    static func subtitle(rating: Double?, releaseDate: String?) -> String {
        var parts: [String] = []
        if let rating = Self.rating(rating) { parts.append("★ \(rating)") }
        if let year = year(from: releaseDate) { parts.append(year) }
        return parts.joined(separator: " · ")
    }
}
