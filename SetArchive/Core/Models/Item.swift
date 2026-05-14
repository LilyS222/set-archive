import SwiftData
import Foundation

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var sourceURL: URL?
    var title: String?
    var thumbnailData: Data?
    var thumbnailRemoteURL: URL?
    var summary: String?
    var rawContent: String?
    var aiConfidence: Double
    var userOverrode: Bool
    var userNote: String?
    var createdAt: Date

    var category: SACategory?

    init(
        sourceURL: URL? = nil,
        title: String? = nil,
        rawContent: String? = nil
    ) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.title = title
        self.rawContent = rawContent
        self.aiConfidence = 0
        self.userOverrode = false
        self.createdAt = Date()
    }
}
