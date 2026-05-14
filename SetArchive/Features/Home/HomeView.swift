import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \SACategory.sortOrder) private var categories: [SACategory]
    @State private var selectedCategory: SACategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    recentSection
                    categoryGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("셋아카이브")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    pendingBadge
                }
            }
        }
        .tint(.indigo)
    }

    // MARK: - Sections

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("최근 추가", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.secondary)

            let allItems = categories.flatMap { $0.items }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(6)

            if allItems.isEmpty {
                emptyRecentPlaceholder
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(allItems)) { item in
                        ItemThumbView(item: item)
                    }
                }
            }
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("내 방", systemImage: "square.grid.2x2")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(destination: CategoryView(category: category)) {
                        CategoryCardView(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyRecentPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.08))
            .frame(height: 80)
            .overlay {
                Text("인스타, 사파리에서 공유해보세요 👆")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
    }

    private var pendingBadge: some View {
        let count = SharedQueue.count()
        return Group {
            if count > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolEffect(.pulse)
                    .foregroundStyle(.indigo)
                    .overlay(alignment: .topTrailing) {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .padding(3)
                            .background(Color.red)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                            .offset(x: 6, y: -6)
                    }
            }
        }
    }
}

// MARK: - Item Thumb

struct ItemThumbView: View {
    let item: Item

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.secondary.opacity(0.1))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let data = item.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "link")
                        .foregroundStyle(.tertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Category Card

struct CategoryCardView: View {
    let category: SACategory

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.secondary.opacity(0.08))
            .frame(height: 100)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.emoji)
                        .font(.title2)
                    Text(category.name)
                        .font(.subheadline).bold()
                    Text("\(category.items.count)개")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
    }
}
