import SwiftUI

// MARK: - 产品详情页

struct ProductDetailView: View {
    let productId: Int
    @EnvironmentObject var cart: CartManager
    @State private var product: Product?
    @State private var history: [PriceHistory] = []
    @State private var selectedSku: Sku?
    @State private var loading = true
    @State private var showImageViewer = false
    @State private var viewerIndex = 0

    var body: some View {
        ScrollView {
            if let p = product {
                VStack(alignment: .leading, spacing: 12) {
                    // 图片画廊（点击进全屏查看器）
                    if !p.images.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(p.images.enumerated()), id: \.offset) { idx, img in
                                    ProductImage(url: img, size: 200, corner: 0)
                                        .onTapGesture {
                                            viewerIndex = idx
                                            showImageViewer = true
                                        }
                                }
                            }
                            .padding(.horizontal, 14)
                        }
                        .frame(height: 210)
                        .background(Color(hex: "#22262E"))
                    } else {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color(hex: "#22262E"))
                            .frame(height: 200)
                            .overlay(Text("产品图 / 视频").foregroundColor(Color(hex: "#5B6270")))
                    }

                    // 信息头
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(p.displayName)
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(Color(hex: "#1F2329"))
                            if p.isPush { StatusTag(text: "• 主推", color: "#3370FF") }
                            if p.isHot { StatusTag(text: "• 热门", color: "#FF7D00") }
                            if !p.status.isEmpty { StatusTag(text: p.status, color: "#FF7D00") }
                        }
                        Text("\(p.categoryName ?? "未分类") · \(p.skus.count > 1 ? "\(p.skus.count) 个规格" : "单规格") · 质保\(p.warranty)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#8F959E"))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("¥")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#F53F3F"))
                            Text(Product.fmt(p.price))
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundColor(Color(hex: "#F53F3F"))
                            if p.skus.count > 1 { Text("起").font(.system(size: 12)).foregroundColor(Color(hex: "#F53F3F")) }
                            if let max = p.priceMax, max > p.price {
                                Text("(\(Product.fmt(p.price)) - \(Product.fmt(max)))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#8F959E"))
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 14)

                    // 规格选择
                    if p.isMultiSku {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("选择规格（品牌 × 款式 × 颜色）")
                                .font(.system(size: 14, weight: .semibold))
                            ForEach(p.skus) { sku in
                                skuRow(sku)
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 14)
                    }

                    // 属性宫格
                    attrGrid(p)

                    // 自定义参数
                    if !p.extraParams.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("产品参数")
                                .font(.system(size: 14, weight: .semibold))
                            ForEach(Array(p.extraParams.sorted(by: { $0.key < $1.key })), id: \.key) { k, v in
                                HStack(alignment: .top) {
                                    Text(k).font(.system(size: 12)).foregroundColor(Color(hex: "#8F959E"))
                                        .frame(width: 70, alignment: .leading)
                                    Text(v).font(.system(size: 13)).foregroundColor(Color(hex: "#1F2329"))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 14)
                    }

                    // 产品说明
                    if !p.description.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("产品说明")
                                .font(.system(size: 14, weight: .semibold))
                            Text(p.description)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#4E5969"))
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 14)
                    }

                    // 调价记录
                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("调价记录")
                                .font(.system(size: 14, weight: .semibold))
                            ForEach(history) { h in
                                HStack {
                                    Text(String(h.createdAt.prefix(10)))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#8F959E"))
                                    Spacer()
                                    Text("¥\(Product.fmt(h.oldPrice)) → ¥\(Product.fmt(h.newPrice)) · \(h.operatorName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#F53F3F"))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 14)
                    }

                    Color.clear.frame(height: 70)
                }
            } else if loading {
                ProgressView().padding(.top, 100)
            }
        }
        .background(Color(hex: "#F5F6FA"))
        .navigationTitle("产品详情")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let p = product {
                addToCartBar(p)
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if let p = product {
                ImageViewer(images: p.images, startIndex: viewerIndex)
            }
        }
        .task { await load() }
    }

    // MARK: - 子视图

    private func skuRow(_ sku: Sku) -> some View {
        let isSelected = selectedSku?.id == sku.id || (selectedSku == nil && p_skus.first?.id == sku.id)
        return Button(action: { selectedSku = sku }) {
            HStack {
                Text(sku.label.isEmpty ? "默认规格" : sku.label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "#3370FF") : Color(hex: "#4E5969"))
                Spacer()
                Text("¥\(Product.fmt(sku.price))")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#F53F3F"))
                if sku.stock == 0 {
                    Text("缺货").font(.system(size: 10)).foregroundColor(Color(hex: "#F53F3F"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "#E8F0FF") : Color(hex: "#F5F6FA"))
            )
        }
        .buttonStyle(.plain)
    }

    private var p_skus: [Sku] { product?.skus ?? [] }

    private func attrGrid(_ p: Product) -> some View {
        let brands = Array(Set(p.skus.map(\.brand).filter { !$0.isEmpty })).sorted()
        let models = Array(Set(p.skus.map(\.model).filter { !$0.isEmpty })).sorted()
        let attrs: [(String, String)] = [
            ("品牌", brands.joined(separator: " / ")),
            ("型号", models.joined(separator: " / ")),
            ("质保", p.warranty),
            ("单位", p.unit),
            ("风格", p.style),
            ("颜色", p.color),
            ("图片", p.images.isEmpty ? "无" : "\(p.images.count) 张"),
            ("更新", p.updatedAt.map { String($0.prefix(10)) } ?? ""),
        ].filter { !$1.isEmpty }

        // 视图构建器（ViewBuilder）里不允许写「let (k, v) = ...」这种元组解构，改为按索引取值
        return VStack(spacing: 0) {
            ForEach(0..<attrs.count, id: \.self) { i in
                HStack(alignment: .top) {
                    Text(attrs[i].0)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8F959E"))
                        .frame(width: 56, alignment: .leading)
                    Text(attrs[i].1)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#1F2329"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if i < attrs.count - 1 { Divider().padding(.leading, 14) }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 14)
    }

    private func addToCartBar(_ p: Product) -> some View {
        let skuId = p.isMultiSku ? (selectedSku?.id ?? p.skus.first?.id) : p.skus.first?.id

        return HStack(spacing: 12) {
            Stepper(qty: cart.qtyOfSku(skuId: skuId)) { delta in
                Task { try? await cart.add(productId: p.id, delta: delta, skuId: skuId) }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - 数据

    private func load() async {
        do {
            let resp = try await ApiService.shared.get("/api/products/\(productId)", as: ProductDetailResp.self)
            product = resp.product
            history = (resp.priceHistory ?? []).prefix(3).map { $0 }
        } catch { }
        loading = false
    }
}
