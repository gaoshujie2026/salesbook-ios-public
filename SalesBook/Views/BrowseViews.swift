import SwiftUI

// MARK: - 分类浏览页（Tab 2）
// 搜索页（SearchView）、项目列表页（ProjectsListView）、项目卡（ProjectCard）
// 分别定义在 SearchView.swift / ProjectViews.swift，此处不再重复定义。

struct CategoryBrowseView: View {
    @EnvironmentObject var catStore: CategoryStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(catStore.categories) { c1 in
                    Section(c1.name) {
                        if let kids = c1.children, !kids.isEmpty {
                            ForEach(kids) { c2 in
                                NavigationLink(destination: CategoryProductList(catId: c2.id, title: c2.name)) {
                                    Text(c2.name)
                                        .font(.system(size: 15))
                                }
                            }
                        } else {
                            // 一级分类下没有二级：直接进该分类的产品
                            NavigationLink(destination: CategoryProductList(catId: c1.id, title: c1.name)) {
                                Text("全部")
                                    .font(.system(size: 15))
                            }
                        }
                    }
                }
            }
            .navigationTitle("分类")
            .onAppear {
                Task { await catStore.load() }
            }
        }
    }
}

struct CategoryProductList: View {
    let catId: Int
    let title: String
    @State private var products: [Product] = []
    @State private var loading = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if loading {
                    ProgressView().padding(.vertical, 30)
                } else if products.isEmpty {
                    Text("该分类暂无产品")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8F959E"))
                        .padding(.vertical, 30)
                }
                ForEach(products) { p in
                    NavigationLink(destination: ProductDetailView(productId: p.id)) {
                        ProductCard(product: p)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .background(Color(hex: "#F5F6FA"))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                let resp = try await ApiService.shared.get(
                    "/api/products?page=1&page_size=100&category_id=\(catId)&sort=smart",
                    as: ProductListResp.self)
                products = resp.items
            } catch { }
            loading = false
        }
    }
}
