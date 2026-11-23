import SwiftUI

// MARK: - 首页（左分类右产品）

struct HomeView: View {
    @EnvironmentObject var cart: CartManager
    @EnvironmentObject var catStore: CategoryStore
    @State private var products: [Product] = []
    @State private var total = 0
    @State private var page = 1
    @State private var loading = false
    @State private var searchText = ""
    @State private var brandList: [CategoryBrand] = []
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar

                // 主体：左分类 + 右产品
                HStack(spacing: 0) {
                    // 左侧分类栏
                    CategorySidebar()
                        .frame(width: 100)

                    Divider()

                    // 右侧产品列表（滑到底部自动加载下一页）
                    ProductListView(products: $products, loading: $loading, hasMore: page * 20 < total,
                                    onLoadMore: { Task { await loadPage(page + 1) } })
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("产品手册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSearch = true }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
        }
        .onAppear {
            Task {
                await catStore.load()
                await loadPage(1)
            }
        }
        .onChange(of: catStore.selectedL1) { _ in Task { await onFilterChange() } }
        .onChange(of: catStore.selectedL2) { _ in Task { await onFilterChange() } }
        .onChange(of: catStore.selectedBrand) { _ in Task { await onFilterChange() } }
        .overlay(alignment: .bottom) {
            // 悬浮购物车栏
            if cart.totalCount > 0 {
                CartBarView()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: "#A6ACB8"))
                    .font(.system(size: 14))
                Text(searchText.isEmpty ? "搜型号 / 名称 / 品牌" : searchText)
                    .font(.system(size: 14))
                    .foregroundColor(searchText.isEmpty ? Color(hex: "#A6ACB8") : Color(hex: "#1F2329"))
                    .onTapGesture { showSearch = true }
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color.white)
            .cornerRadius(19)
            .shadow(color: .black.opacity(0.04), radius: 2)

            // 分类/品牌筛选按钮
            Menu {
                ForEach(brandList, id: \.brand) { b in
                    Button(action: {
                        catStore.selectedBrand = b.brand
                    }) {
                        if catStore.selectedBrand == b.brand {
                            Label("\(b.brand) (\(b.count))", systemImage: "checkmark")
                        } else {
                            Text("\(b.brand) (\(b.count))")
                        }
                    }
                }
                if !catStore.selectedBrand.isEmpty {
                    Button(role: .destructive, action: { catStore.selectedBrand = "" }) {
                        Text("清除品牌筛选")
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                    .foregroundColor(catStore.selectedBrand.isEmpty ? Color(hex: "#646A73") : Color(hex: "#3370FF"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "#F5F6FA"))
    }

    private func onFilterChange() async {
        await loadPage(1)
        // 加载当前分类的品牌列表
        let catId = catStore.selectedL2 ?? catStore.selectedL1
        if let cid = catId {
            brandList = await catStore.loadBrands(catId: cid)
        } else {
            brandList = []
        }
    }

    private func loadPage(_ p: Int) async {
        guard !loading else { return }
        loading = true
        defer { loading = false }

        var path = "/api/products?page=\(p)&page_size=20&sort=smart&push_top=1"
        let catId = catStore.selectedL2 ?? catStore.selectedL1
        if let cid = catId { path += "&category_id=\(cid)" }
        if !catStore.selectedBrand.isEmpty {
            path += "&brand=\(catStore.selectedBrand.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        do {
            let resp = try await ApiService.shared.get(path, as: ProductListResp.self)
            if p == 1 { products = resp.items }
            else { products.append(contentsOf: resp.items) }
            total = resp.total
            page = p
        } catch { }
    }
}

// MARK: - 左侧分类栏

struct CategorySidebar: View {
    @EnvironmentObject var catStore: CategoryStore
    @State private var expandedL1: Set<Int> = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 全部产品
                catRow(name: "全部产品", id: nil, isL1: true)

                ForEach(catStore.categories) { c1 in
                    catRow(name: c1.name, id: c1.id, isL1: true)

                    // 展开的二级
                    if expandedL1.contains(c1.id) {
                        ForEach(c1.children ?? []) { c2 in
                            catRow(name: c2.name, id: c2.id, isL1: false, indent: true)
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }

    private func catRow(name: String, id: Int?, isL1: Bool, indent: Bool = false) -> some View {
        let isSelected = isL1 ? catStore.selectedL1 == id && catStore.selectedL2 == nil
                              : catStore.selectedL2 == id
        let isExpanded = id != nil && expandedL1.contains(id!)

        return Button(action: {
            if isL1 {
                catStore.selectedL1 = id
                catStore.selectedL2 = nil
                catStore.selectedBrand = ""
                if let cid = id {
                    if isExpanded { expandedL1.remove(cid) }
                    else { expandedL1.insert(cid) }
                }
            } else {
                catStore.selectedL2 = id
                catStore.selectedBrand = ""
            }
        }) {
            HStack(spacing: 4) {
                if indent { Color.clear.frame(width: 14) }
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#3370FF"))
                        .frame(width: 3, height: 16)
                }
                Text(name)
                    .font(.system(size: indent ? 12 : 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "#3370FF") : Color(hex: "#8F959E"))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isL1 && id != nil && !(catStore.firstCategoryChildren(id: id!).isEmpty) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#C4CBD8"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#E8F0FF") : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

extension CategoryStore {
    func firstCategoryChildren(id: Int) -> [Category] {
        categories.first { $0.id == id }?.children ?? []
    }
}

// MARK: - 产品列表

struct ProductListView: View {
    @Binding var products: [Product]
    @Binding var loading: Bool
    var hasMore: Bool
    var onLoadMore: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(products) { p in
                    NavigationLink(destination: ProductDetailView(productId: p.id)) {
                        ProductCard(product: p)
                    }
                    .buttonStyle(.plain)
                }

                if loading {
                    ProgressView("加载中…")
                        .padding(.vertical, 16)
                } else if hasMore {
                    Text("上滑加载更多")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#A6ACB8"))
                        .padding(.vertical, 12)
                        .onAppear { onLoadMore?() }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
        }
        .background(Color(hex: "#F5F6FA"))
    }
}

// MARK: - 产品卡片

struct ProductCard: View {
    @EnvironmentObject var cart: CartManager
    let product: Product

    var body: some View {
        HStack(spacing: 10) {
            // 产品图
            ProductImage(url: product.images.first ?? "", size: 62)
                .overlay(alignment: .topLeading) {
                    if product.isPush {
                        Text("主推")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#3370FF"))
                            .cornerRadius(99)
                            .offset(x: -2, y: -2)
                    }
                }

            // 信息
            VStack(alignment: .leading, spacing: 3) {
                Text(product.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#1F2329"))
                    .lineLimit(1)

                Text(product.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#8F9599"))
                    .lineLimit(1)

                // 状态标签
                HStack(spacing: 4) {
                    if product.isHot { StatusTag(text: "🔥热门", color: "#FF7D00") }
                    if !product.status.isEmpty { StatusTag(text: product.status, color: "#FF7D00") }
                    if product.stock == 0 { StatusTag(text: "缺货", color: "#F53F3F") }
                }

                Text(product.priceLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#F53F3F"))
            }

            Spacer(minLength: 0)

            // 加购步进器（多规格取第一个规格的 skuId）
            Stepper(qty: cart.qtyOf(productId: product.id)) { delta in
                let skuId = product.skus.first?.id
                Task { try? await cart.add(productId: product.id, delta: delta, skuId: skuId) }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - 产品图片（异步加载+缓存）

struct ProductImage: View {
    let url: String
    var size: CGFloat = 62
    var corner: CGFloat = 10

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "#F0F2F7"))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Color(hex: "#C4CBD8"))
                            .font(.system(size: size * 0.3))
                    )
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(corner)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .task {
            guard image == nil, !url.isEmpty else { return }
            if let cached = ImageCache.shared.get(url) {
                image = cached
                return
            }
            if let data = try? await ApiService.shared.downloadImage(url),
               let img = UIImage(data: data) {
                ImageCache.shared.put(url, img)
                image = img
            }
        }
    }
}

// MARK: - 图片缓存（内存+磁盘）

class ImageCache {
    static let shared = ImageCache()
    private let mem = NSCache<NSString, UIImage>()
    private let diskDir: URL

    init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskDir = cacheDir.appendingPathComponent("imgs", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)
    }

    private func diskFile(_ url: String) -> URL {
        let hash = url.sha256 ?? url.replacingOccurrences(of: "/", with: "_")
        return diskDir.appendingPathComponent("\(hash).img")
    }

    func get(_ url: String) -> UIImage? {
        if let img = mem.object(forKey: url as NSString) { return img }
        let f = diskFile(url)
        if let data = try? Data(contentsOf: f), let img = UIImage(data: data) {
            mem.setObject(img, forKey: url as NSString)
            return img
        }
        return nil
    }

    func put(_ url: String, _ img: UIImage) {
        mem.setObject(img, forKey: url as NSString)
        let f = diskFile(url)
        if let data = img.jpegData(compressionQuality: 0.9) {
            try? data.write(to: f)
        }
    }
}

extension String {
    var sha256: String? {
        guard let data = data(using: .utf8) else { return nil }
        // 简化版：用 md5-style hash
        return String(format: "%x", data.hashValue)
    }
}

// MARK: - 状态标签

struct StatusTag: View {
    let text: String
    let color: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(Color(hex: color))
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(Color(hex: color).opacity(0.1))
            .cornerRadius(99)
    }
}

// MARK: - ApiService 扩展：图片下载

extension ApiService {
    func downloadImage(_ path: String) async throws -> Data {
        let urlString = path.hasPrefix("http") ? path : ApiConfig.baseURL + "/uploads/" + path
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }
        let (data, _) = try await session.data(from: url)
        return data
    }
}
