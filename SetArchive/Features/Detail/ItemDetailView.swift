import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: Item
    @State private var showingCategoryPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroImage
                metaSection
                summarySection
                linkSection
                noteSection
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCategoryPicker = true
                } label: {
                    Label("카테고리 변경", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(item: item)
        }
    }

    // MARK: - Sections

    private var heroImage: some View {
        Group {
            if let data = item.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = item.title {
                Text(title)
                    .font(.title3).bold()
            }
            HStack {
                if let cat = item.category {
                    Label(cat.name, systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var summarySection: some View {
        Group {
            if let summary = item.summary {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI 요약", systemImage: "sparkles")
                        .font(.subheadline).bold()
                        .foregroundStyle(.indigo)

                    ForEach(summary.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.indigo)
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            Text(line)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(14)
                .background(Color.indigo.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var linkSection: some View {
        Group {
            if let url = item.sourceURL {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                        Text(url.host() ?? url.absoluteString)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.indigo)
                    .padding(12)
                    .background(Color.indigo.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("메모", systemImage: "pencil")
                .font(.subheadline).bold()
                .foregroundStyle(.secondary)
            TextField("한 줄 메모를 입력하세요...", text: Binding(
                get: { item.userNote ?? "" },
                set: { item.userNote = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .font(.subheadline)
            .padding(10)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Category Picker

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \SACategory.sortOrder) private var categories: [SACategory]
    @Bindable var item: Item

    var body: some View {
        NavigationStack {
            List(categories) { category in
                Button {
                    item.category = category
                    item.userOverrode = true
                    try? context.save()
                    dismiss()
                } label: {
                    HStack {
                        Text(category.emoji + " " + category.name)
                        Spacer()
                        if item.category?.id == category.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.indigo)
                        }
                    }
                }
                .tint(.primary)
            }
            .navigationTitle("카테고리 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }
}
