import SwiftUI
import Security

// MARK: - Keychain（安全存储 token）

class Keychain {
    static let service = "com.lingdu.salesbook"

    static func save(_ key: String, _ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    static func load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - 用户会话管理

@MainActor
class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var user: User?

    init() {
        if !ApiConfig.token.isEmpty, let json = ApiConfig.userJSON,
           let data = json.data(using: .utf8),
           let u = try? JSONDecoder().decode(User.self, from: data) {
            self.user = u
            self.isLoggedIn = true
        }
    }

    func login(username: String, password: String) async throws {
        let resp: LoginResp = try await ApiService.shared.post(
            "/api/auth/login",
            body: ["username": username, "password": password],
            as: LoginResp.self)
        ApiConfig.token = resp.token
        if let data = try? JSONEncoder().encode(resp.user), let json = String(data: data, encoding: .utf8) {
            ApiConfig.userJSON = json
        }
        self.user = resp.user
        self.isLoggedIn = true
    }

    func logout() {
        ApiConfig.token = ""
        ApiConfig.userJSON = nil
        self.user = nil
        self.isLoggedIn = false
    }
}

// MARK: - 购物车状态

@MainActor
class CartManager: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var isLoaded = false

    var totalCount: Int { items.reduce(0) { $0 + $1.qty } }
    var totalAmount: Double { items.reduce(0.0) { $0 + $1.price * Double($1.qty) } }
    var totalAgentAmount: Double { items.reduce(0.0) { $0 + ($1.agentPrice ?? $1.price) * Double($1.qty) } }

    func qtyOf(productId: Int) -> Int {
        items.filter { $0.productId == productId }.reduce(0) { $0 + $1.qty }
    }

    func qtyOfSku(skuId: Int?) -> Int {
        guard let sid = skuId else { return 0 }
        return items.first { $0.skuId == sid }?.qty ?? 0
    }

    func load() async {
        do {
            // /api/cart 直接返回数组（不能走 getRaw：它只接受 JSON 对象）
            self.items = try await ApiService.shared.get("/api/cart", as: [CartItem].self)
            self.isLoaded = true
        } catch {
            // 静默失败（离线时用缓存）
        }
    }

    func add(productId: Int, delta: Int, skuId: Int? = nil) async throws {
        var body: [String: Any] = ["product_id": productId, "delta": delta]
        if let sid = skuId { body["sku_id"] = sid }
        _ = try await ApiService.shared.post("/api/cart", body: body, as: [CartItem].self)
        await load()
    }

    func clearLocal() {
        items = []
    }
}

// MARK: - 分类状态

@MainActor
class CategoryStore: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedL1: Int? = nil
    @Published var selectedL2: Int? = nil
    @Published var selectedBrand: String = ""

    var flatL2: [Category] {
        guard let l1 = categories.first(where: { $0.id == selectedL1 }) else { return [] }
        return l1.children ?? []
    }

    func load() async {
        do {
            // /api/categories 直接返回数组
            self.categories = try await ApiService.shared.get("/api/categories", as: [Category].self)
        } catch { }
    }

    func loadBrands(catId: Int) async -> [CategoryBrand] {
        do {
            return try await ApiService.shared.get("/api/categories/\(catId)/brands", as: [CategoryBrand].self)
        } catch { }
        return []
    }
}
