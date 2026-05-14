import SwiftUI

// 패션·카페용 — 핀터레스트 스타일 2열 그리드
struct GridLayout: View {
    let items: [Item]

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ScrollView {
            if items.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            GridItemCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "아직 저장된 항목이 없어요",
            systemImage: "square.grid.2x2",
            description: Text("공유 버튼을 눌러 첫 번째 아이템을 추가해보세요")
        )
    }
}

struct GridItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnail
            info
        }
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.1))
            .aspectRatio(0.85, contentMode: .fit)
            .overlay {
                if let data = item.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title = item.title {
                Text(title)
                    .font(.caption).bold()
                    .lineLimit(2)
            }
            if let summary = item.summary?.components(separatedBy: "\n").first {
                Text(summary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}
