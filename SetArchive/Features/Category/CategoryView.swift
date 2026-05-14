import SwiftUI
import SwiftData

struct CategoryView: View {
    let category: SACategory

    var body: some View {
        Group {
            if category.viewStyle == .grid {
                GridLayout(items: category.items.sorted { $0.createdAt > $1.createdAt })
            } else {
                ReadingCardLayout(items: category.items.sorted { $0.createdAt > $1.createdAt })
            }
        }
        .navigationTitle("\(category.emoji) \(category.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
