import Foundation

struct QueuedItem: Codable, Identifiable {
    let id: String
    let sourceURL: String?
    let text: String?
    let imageData: Data?
    let queuedAt: Date

    init(sourceURL: String? = nil, text: String? = nil, imageData: Data? = nil) {
        self.id = UUID().uuidString
        self.sourceURL = sourceURL
        self.text = text
        self.imageData = imageData
        self.queuedAt = Date()
    }
}

enum SharedQueue {
    static let appGroupID = "group.com.setarchive.shared"
    private static let queueKey = "pending_items"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func enqueue(_ item: QueuedItem) {
        var items = all()
        items.append(item)
        persist(items)
    }

    static func dequeueAll() -> [QueuedItem] {
        let items = all()
        persist([])
        return items
    }

    static func count() -> Int {
        all().count
    }

    private static func all() -> [QueuedItem] {
        guard let data = defaults?.data(forKey: queueKey),
              let items = try? JSONDecoder().decode([QueuedItem].self, from: data) else {
            return []
        }
        return items
    }

    private static func persist(_ items: [QueuedItem]) {
        let data = try? JSONEncoder().encode(items)
        defaults?.set(data, forKey: queueKey)
    }
}
