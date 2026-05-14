import SwiftUI

// 공부·자기계발용 — 요약 텍스트 중심 리딩 카드
struct ReadingCardLayout: View {
    let items: [Item]

    var body: some View {
        ScrollView {
            if items.isEmpty {
                ContentUnavailableView(
                    "아직 저장된 항목이 없어요",
                    systemImage: "book",
                    description: Text("공유 버튼을 눌러 첫 번째 아이템을 추가해보세요")
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            ReadingCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
}

struct ReadingCard: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            content
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.12))
            .frame(width: 60, height: 60)
            .overlay {
                if let data = item.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.tertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = item.title {
                Text(title)
                    .font(.subheadline).bold()
                    .lineLimit(2)
            }
            if let summary = item.summary {
                ForEach(summary.components(separatedBy: "\n").prefix(3), id: \.self) { line in
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                            .foregroundStyle(.indigo)
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let raw = item.rawContent {
                Text(raw)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Text(item.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
