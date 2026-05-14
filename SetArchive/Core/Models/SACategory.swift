import SwiftData
import Foundation

enum ViewStyle: String, Codable {
    case grid
    case list
}

@Model
final class SACategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var viewStyleRaw: String
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .cascade, inverse: \Item.category)
    var items: [Item] = []

    var viewStyle: ViewStyle {
        get { ViewStyle(rawValue: viewStyleRaw) ?? .grid }
        set { viewStyleRaw = newValue.rawValue }
    }

    init(name: String, emoji: String, viewStyle: ViewStyle = .grid, sortOrder: Int = 0, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.viewStyleRaw = viewStyle.rawValue
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }
}

extension SACategory {
    static let defaults: [(name: String, emoji: String, style: ViewStyle, order: Int)] = [
        ("패션",        "🪞", .grid, 0),
        ("카페·맛집",   "☕", .grid, 1),
        ("공부·자기계발","📚", .list, 2),
        ("여행",        "✈️", .grid, 3),
        ("인테리어",    "🏠", .grid, 4),
        ("미분류함",    "📦", .list, 5),
    ]

    static var unclassifiedName: String { "미분류함" }
}
