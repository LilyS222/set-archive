import Foundation

struct ClassificationResult: Decodable {
    let category: String
    let confidence: Double
    let summary: String
    let suggestedTags: [String]
}

enum ClassificationError: LocalizedError {
    case invalidConfiguration
    case networkError(Error)
    case serverError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Supabase URL/Key가 설정되지 않았습니다"
        case .networkError(let e): return "네트워크 오류: \(e.localizedDescription)"
        case .serverError(let code): return "서버 오류: \(code)"
        case .decodingError: return "응답 파싱 실패"
        }
    }
}

final class ClassificationClient {
    static let shared = ClassificationClient()

    private var classifyURL: URL? {
        guard !AppConfig.supabaseURL.isEmpty else { return nil }
        return URL(string: "\(AppConfig.supabaseURL)/functions/v1/classify")
    }

    func classify(url: String?, text: String?, imageData: Data?) async throws -> ClassificationResult {
        guard let endpoint = classifyURL else {
            throw ClassificationError.invalidConfiguration
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = ClassifyRequest(
            url: url,
            text: text,
            imageBase64: imageData?.base64EncodedString()
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClassificationError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ClassificationError.serverError(http.statusCode)
        }

        guard let result = try? JSONDecoder().decode(ClassificationResult.self, from: data) else {
            throw ClassificationError.decodingError
        }

        return result
    }
}

private struct ClassifyRequest: Encodable {
    let url: String?
    let text: String?
    let imageBase64: String?
}
