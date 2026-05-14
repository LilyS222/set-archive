import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    private var bottomSheet: BottomSheetView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        showBottomSheet()
    }

    private func showBottomSheet() {
        let sheet = BottomSheetView()
        sheet.onCategorySelected = { [weak self] categoryName in
            self?.saveAndDismiss(categoryName: categoryName)
        }
        sheet.onCancel = { [weak self] in
            self?.cancel()
        }
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)

        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        bottomSheet = sheet
    }

    private func saveAndDismiss(categoryName: String?) {
        Task { [weak self] in
            guard let self else { return }
            let item = await self.extractQueuedItem(targetCategory: categoryName)
            SharedQueue.enqueue(item)
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func extractQueuedItem(targetCategory: String?) async -> QueuedItem {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return QueuedItem(text: targetCategory)
        }

        for extensionItem in items {
            for provider in (extensionItem.attachments ?? []) {
                if let url = await loadURL(from: provider) {
                    return QueuedItem(sourceURL: url.absoluteString, text: targetCategory)
                }
                if let text = await loadText(from: provider) {
                    return QueuedItem(text: text)
                }
                if let imageData = await loadImage(from: provider) {
                    return QueuedItem(imageData: imageData)
                }
            }
        }
        return QueuedItem()
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: 0))
    }

    // MARK: - Item Extractors

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return nil }
        return try? await withCheckedThrowingContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, error in
                if let url = item as? URL { cont.resume(returning: url) }
                else { cont.resume(returning: nil) }
            }
        }
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) else { return nil }
        return try? await withCheckedThrowingContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, error in
                cont.resume(returning: item as? String)
            }
        }
    }

    private func loadImage(from provider: NSItemProvider) async -> Data? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return nil }
        return try? await withCheckedThrowingContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
                if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    cont.resume(returning: data)
                } else if let image = item as? UIImage {
                    cont.resume(returning: image.jpegData(compressionQuality: 0.7))
                } else {
                    cont.resume(returning: nil)
                }
            }
        }
    }
}
