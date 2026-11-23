import SwiftUI

// MARK: - 全屏图片查看器（左右滑动翻页 + 页码指示）

struct ImageViewer: View {
    let images: [String]
    @State var startIndex: Int
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if images.isEmpty {
                    Text("无图片").foregroundColor(.gray)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { idx, img in
                            AsyncImage(url: URL(string: "\(ApiConfig.baseURL)/uploads/\(img)")) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                case .failure:
                                    Text("加载失败").foregroundColor(.gray)
                                default:
                                    ProgressView().tint(.white)
                                }
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _ in }

                    // 页码指示
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<min(images.count, 10), id: \.self) { i in
                                Capsule()
                                    .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: i == currentIndex ? 20 : 6, height: 4)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex + 1) / \(images.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveCurrentImage()
                    } label: {
                        Image(systemName: "square.and.arrow.down").foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear { currentIndex = startIndex }
    }

    private func saveCurrentImage() {
        guard currentIndex < images.count else { return }
        let fileName = images[currentIndex]
        Task {
            do {
                let data = try await ApiService.shared.download("/uploads/\(fileName)")
                let dir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
                let file = dir.appendingPathComponent(fileName)
                try data.write(to: file)
            } catch { }
        }
    }
}

// MARK: - 搜索页

struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var keyword = ""
    @State private var results: [Product] = []
    @State private var loading = false
    @State private var searchTimer: Timer?
    @State private var selectedProduct: Int?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("搜型号 / 名称 / 品牌", text: $keyword)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { search() }
                        .onChange(of: keyword) { _ in search() }   // 边输入边搜（函数内已做 0.35 秒防抖）
                    if !keyword.isEmpty {
                        Button { keyword = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(hex: "#F3F4F8"))
                .cornerRadius(12)
                .padding(.horizontal, 14).padding(.vertical, 8)

                // 结果
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if loading {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "#EEF0F5"))
                                    .frame(height: 90)
                            }
                        } else if results.isEmpty && !keyword.isEmpty {
                            VStack(spacing: 8) {
                                Text("没有匹配「\(keyword)」的产品")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#8F959E"))
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(results) { p in
                                NavigationLink(destination: ProductDetailView(productId: p.id)) {
                                    SearchResultRow(product: p)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .background(Color(hex: "#F5F6FA"))
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .onAppear { focused = true }   // 打开即聚焦搜索框，直接弹键盘
    }

    private func search() {
        searchTimer?.invalidate()
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else { results = []; loading = false; return }
        // 已有结果时不清屏：输入过程中保留旧结果，等新结果到了再替换
        if results.isEmpty { loading = true }
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { _ in
            Task {
                do {
                    let resp: ProductListResp = try await ApiService.shared.get(
                        "/api/products?keyword=\(kw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&page=1&page_size=20",
                        as: ProductListResp.self)
                    await MainActor.run { results = resp.items; loading = false }
                } catch {
                    await MainActor.run { loading = false }
                }
            }
        }
    }
}

// MARK: - 搜索结果行

struct SearchResultRow: View {
    let product: Product
    @EnvironmentObject var cart: CartManager

    var body: some View {
        HStack(spacing: 10) {
            ProductImage(url: product.images.first ?? "", size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(product.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(product.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#8F959E"))
                    .lineLimit(1)
                Text(product.priceLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#F53F3F"))
            }

            Spacer()

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
