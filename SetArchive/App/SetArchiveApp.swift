import SwiftUI
import SwiftData

@main
struct SetArchiveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(SwiftDataStack.shared.container)
                .task {
                    await QueueProcessor.shared.processQueueNow()
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        QueueProcessor.shared.registerBackgroundTask()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task {
            await QueueProcessor.shared.processQueueNow()
        }
    }
}
