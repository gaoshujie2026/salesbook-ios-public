import Foundation

// MARK: - API 基础配置

enum ApiConfig {
    static let baseURL = "https://shanxilingdu.cn:9900"
    static var token: String {
        get { UserDefaults.standard.string(forKey: "token") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "token") }
    }
    static var userJSON: String? {
        get { UserDefaults.standard.string(forKey: "user") }
        set { UserDefaults.standard.set(newValue, forKey: "user") }
    }
}

// MARK: - 网络请求封装

enum ApiError: Error, LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case networkError(String)
    case decodeError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效地址"
        case .httpError(let code, let msg): return msg.isEmpty ? "请求失败(\(code))" : msg
        case .networkError(let msg): return msg
        case .decodeError(let msg): return "数据解析失败: \(msg)"
        }
    }
}

class ApiService {
    static let shared = ApiService()
    let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        // 忽略自签证书（与后端 HTTPS 配置匹配）
        let delegate = CertIgnoreDelegate()
        self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }

    private func makeRequest(_ method: String, _ path: String, body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: ApiConfig.baseURL + path) else { throw ApiError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !ApiConfig.token.isEmpty {
            req.setValue("Bearer \(ApiConfig.token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    private func execute(_ req: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw ApiError.networkError("网络连接失败，请检查网络")
        }
        guard let http = response as? HTTPURLResponse else {
            throw ApiError.networkError("服务器无响应")
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? ""
            if http.statusCode == 401 {
                NotificationCenter.default.post(name: .apiUnauthorized, object: nil)
            }
            throw ApiError.httpError(http.statusCode, msg)
        }
        return data
    }

    // MARK: - 通用 GET/POST/PUT/DELETE

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        let req = try makeRequest("GET", path)
        let data = try await execute(req)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ApiError.decodeError("\(error)")
        }
    }

    func getRaw(_ path: String) async throws -> [String: Any] {
        let req = try makeRequest("GET", path)
        let data = try await execute(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ApiError.decodeError("not a JSON object")
        }
        return json
    }

    func post<T: Decodable>(_ path: String, body: [String: Any]? = nil, as type: T.Type) async throws -> T {
        let req = try makeRequest("POST", path, body: body)
        let data = try await execute(req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func put<T: Decodable>(_ path: String, body: [String: Any]? = nil, as type: T.Type) async throws -> T {
        let req = try makeRequest("PUT", path, body: body)
        let data = try await execute(req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func delete(_ path: String) async throws {
        let req = try makeRequest("DELETE", path)
        _ = try await execute(req)
    }

    /** 下载文件（Excel 导出、图片保存等） */
    func download(_ path: String) async throws -> Data {
        guard let url = URL(string: ApiConfig.baseURL + path) else { throw ApiError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(ApiConfig.token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode < 400 else {
            throw ApiError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 500, "下载失败")
        }
        return data
    }

    // MARK: - 图片 URL

    static func imageUrl(_ filename: String) -> String {
        filename.hasPrefix("http") ? filename : "\(ApiConfig.baseURL)/uploads/\(filename)"
    }
}

// 忽略自签证书
class CertIgnoreDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension Notification.Name {
    static let apiUnauthorized = Notification.Name("apiUnauthorized")
}
