import Foundation

// MARK: - 用户

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let name: String
    let phone: String?
    let role: String
    let canAgent: Bool
    let isActive: Bool
    let perms: [String]?

    var isAdmin: Bool { role == "admin" }
    var canEdit: Bool { isAdmin || (perms?.contains("product_edit") ?? false) }
    var hasPerm: (String) -> Bool { { key in isAdmin || (perms?.contains(key) ?? false) } }

    enum CodingKeys: String, CodingKey {
        case id, username, name, phone, role, perms
        case canAgent = "can_agent"
        case isActive = "is_active"
    }
}

// MARK: - 分类

struct Category: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let parentId: Int?
    let children: [Category]?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
}

// MARK: - 规格

struct Sku: Codable, Identifiable {
    let id: Int
    let brand: String
    let model: String
    let style: String
    let color: String
    let price: Double
    let agentPrice: Double?
    let stock: Int
    let images: [String]

    enum CodingKeys: String, CodingKey {
        case id, brand, model, style, color, price, stock, images
        case agentPrice = "agent_price"
    }

    var label: String {
        [brand, model, style, color].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

// MARK: - 产品

struct Product: Codable, Identifiable {
    let id: Int
    let model: String
    let name: String
    let brand: String
    let categoryId: Int?
    let categoryName: String?
    let unit: String
    let style: String
    let color: String
    let spec: String
    let warranty: String
    let description: String
    let stock: Int
    let price: Double
    let agentPrice: Double?
    let images: [String]
    let extraParams: [String: String]
    let isPush: Bool
    let isHot: Bool
    let status: String
    let updatedAt: String?
    let skus: [Sku]
    let priceMax: Double?

    enum CodingKeys: String, CodingKey {
        case id, model, name, brand, unit, style, color, spec, warranty, description
        case stock, price, images, skus, status
        case categoryId = "category_id"
        case categoryName = "category_name"
        case agentPrice = "agent_price"
        case extraParams = "extra_params"
        case isPush = "is_push"
        case isHot = "is_hot"
        case updatedAt = "updated_at"
        case priceMax = "price_max"
    }

    var displayName: String { name.isEmpty ? model : name }
    var subtitle: String {
        [brand, model, style, color].filter { !$0.isEmpty }.joined(separator: " ")
    }
    var priceLabel: String {
        if skus.count > 1, let max = priceMax, max > price {
            return "¥\(Product.fmt(price)) - \(Product.fmt(max))"
        }
        return "¥\(Product.fmt(price))"
    }
    var isMultiSku: Bool { skus.count > 1 }

    static func fmt(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d)
    }
}

// MARK: - 产品列表响应

struct ProductListResp: Codable {
    let total: Int
    let items: [Product]
}

// MARK: - 产品详情（含调价记录）

struct PriceHistory: Codable, Identifiable {
    let id: Int
    let oldPrice: Double
    let newPrice: Double
    let operatorName: String
    let note: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, note
        case oldPrice = "old_price"
        case newPrice = "new_price"
        case operatorName = "operator_name"
        case createdAt = "created_at"
    }
}

struct ProductDetailResp: Codable {
    let product: Product
    let priceHistory: [PriceHistory]?

    enum CodingKeys: String, CodingKey {
        case product
        case priceHistory = "price_history"
    }
}

// MARK: - 购物车

struct CartItem: Codable, Identifiable {
    let id: Int
    let productId: Int
    let skuId: Int?
    let qty: Int
    let name: String
    let model: String
    let unit: String
    let price: Double
    let agentPrice: Double?
    let image: String
    let brand: String
    let style: String
    let color: String
    let warranty: String
    let skuModel: String

    enum CodingKeys: String, CodingKey {
        case id, qty, name, model, unit, price, image, brand, style, color, warranty
        case productId = "product_id"
        case skuId = "sku_id"
        case agentPrice = "agent_price"
        case skuModel = "sku_model"
    }

    var specLabel: String { [brand, style, color].filter { !$0.isEmpty }.joined(separator: " ") }
}

// MARK: - 项目（销售单）

struct ProjectItem: Codable, Identifiable, Hashable {
    let id: Int
    let productId: Int?
    let skuId: Int?
    let name: String
    let model: String
    let brand: String
    let style: String
    let color: String
    let unit: String
    let price: Double
    let agentPrice: Double
    let qty: Int
    let image: String

    enum CodingKeys: String, CodingKey {
        case id, name, model, brand, style, color, unit, price, qty, image
        case productId = "product_id"
        case skuId = "sku_id"
        case agentPrice = "agent_price"
    }
}

struct Project: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let customer: String
    let contact: String
    let phone: String
    let note: String
    let ownerId: Int
    let ownerName: String
    let createdAt: String
    let totalQty: Int
    let totalAmount: Double
    let totalAgentAmount: Double
    let items: [ProjectItem]

    enum CodingKeys: String, CodingKey {
        case id, name, customer, contact, phone, note, items
        case ownerId = "owner_id"
        case ownerName = "owner_name"
        case createdAt = "created_at"
        case totalQty = "total_qty"
        case totalAmount = "total_amount"
        case totalAgentAmount = "total_agent_amount"
    }
}

// MARK: - 登录响应

struct LoginResp: Codable {
    let token: String
    let user: User
}

// MARK: - 分类品牌

struct CategoryBrand: Codable {
    let brand: String
    let count: Int
}
