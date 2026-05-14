import Foundation

enum AppConfig {
    // MARK: - Supabase
    // TODO: Supabase 프로젝트 생성 후 이 값들을 채우세요
    static let supabaseURL: String = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseAnonKey: String = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

    // MARK: - AI
    static let classifyConfidenceThreshold: Double = 0.7

    // MARK: - App Group
    static let appGroupID = "group.com.setarchive.shared"

    // MARK: - Background Task
    static let queueProcessTaskID = "com.setarchive.app.process-queue"
}
