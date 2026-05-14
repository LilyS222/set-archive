import SwiftData
import Foundation

@MainActor
final class SwiftDataStack {
    static let shared = SwiftDataStack()

    let container: ModelContainer

    private init() {
        let schema = Schema([Item.self, SACategory.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConfig.appGroupID)
        )
        do {
            container = try ModelContainer(for: schema, configurations: config)
            seedDefaultCategories()
        } catch {
            fatalError("SwiftData container 생성 실패: \(error)")
        }
    }

    var context: ModelContext { container.mainContext }

    private func seedDefaultCategories() {
        let descriptor = FetchDescriptor<SACategory>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (name, emoji, style, order) in SACategory.defaults {
            let cat = SACategory(name: name, emoji: emoji, viewStyle: style, sortOrder: order, isDefault: true)
            context.insert(cat)
        }
        try? context.save()
    }

    func unclassifiedCategory() -> SACategory? {
        var descriptor = FetchDescriptor<SACategory>(
            predicate: #Predicate { $0.name == SACategory.unclassifiedName }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func category(named name: String) -> SACategory? {
        var descriptor = FetchDescriptor<SACategory>(
            predicate: #Predicate { $0.name == name }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
