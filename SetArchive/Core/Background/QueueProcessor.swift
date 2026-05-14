import BackgroundTasks
import SwiftData
import Foundation

@MainActor
final class QueueProcessor {
    static let shared = QueueProcessor()

    private let stack = SwiftDataStack.shared
    private let client = ClassificationClient.shared

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConfig.queueProcessTaskID, using: nil) { [weak self] task in
            self?.handleBackgroundTask(task as! BGProcessingTask)
        }
    }

    func scheduleIfNeeded() {
        guard SharedQueue.count() > 0 else { return }
        let request = BGProcessingTaskRequest(identifier: AppConfig.queueProcessTaskID)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    func processQueueNow() async {
        let queued = SharedQueue.dequeueAll()
        guard !queued.isEmpty else { return }

        for queuedItem in queued {
            await processItem(queuedItem)
        }

        try? stack.context.save()
    }

    private func processItem(_ queued: QueuedItem) async {
        let sourceURL = queued.sourceURL.flatMap { URL(string: $0) }
        let item = Item(sourceURL: sourceURL, title: nil, rawContent: queued.text)
        stack.context.insert(item)

        do {
            let result = try await client.classify(
                url: queued.sourceURL,
                text: queued.text,
                imageData: queued.imageData
            )
            applyResult(result, to: item)
        } catch {
            item.category = stack.unclassifiedCategory()
            item.aiConfidence = 0
        }
    }

    private func applyResult(_ result: ClassificationResult, to item: Item) {
        item.summary = result.summary
        item.aiConfidence = result.confidence

        let categoryName = result.confidence >= AppConfig.classifyConfidenceThreshold
            ? result.category
            : SACategory.unclassifiedName

        item.category = stack.category(named: categoryName) ?? stack.unclassifiedCategory()
    }

    private func handleBackgroundTask(_ task: BGProcessingTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task {
            await processQueueNow()
            task.setTaskCompleted(success: true)
        }
    }
}
