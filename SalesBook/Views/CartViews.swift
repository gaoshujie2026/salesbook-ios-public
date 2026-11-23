import SwiftUI

// MARK: - 悬浮购物车栏（首页/分类底部）

struct CartBarView: View {
    @EnvironmentObject var cart: CartManager
    @State private var showDetail = false
    @State private var showForm = false

    var body: some View {
        Group {
            if !cart.items.isEmpty {
                HStack(spacing: 10) {
                    Button { showDetail = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Text("🛒").font(.system(size: 24))
                            Text("\(cart.totalCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color(hex: "#F53F3F"))
                                .clipShape(Capsule())
                                .offset(x: 8, y: -4)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("¥\(Product.fmt(cart.totalAmount))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#F76965"))
                        .lineLimit(1)

                    Spacer()

                    Button { showForm = true } label: {
                        Text("生成方案")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18).padding(.vertical, 9)
                            .background(
                                LinearGradient(colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                                               startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 2)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            }
        }
        .sheet(isPresented: $showDetail) { CartDetailSheet() }
        .sheet(isPresented: $showForm) { ProjectFormView() }
    }
}

// MARK: - 购物车明细弹窗

struct CartDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cart: CartManager
    @State private var showForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(cart.items) { item in
                        CartItemRow(item: item)
                        Divider().padding(.leading, 76)
                    }

                    HStack {
                        Text("合计")
                        Spacer()
                        Text("¥\(Product.fmt(cart.totalAmount))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#F53F3F"))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(Color(hex: "#F5F6FA"))
            .navigationTitle("查看明细")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("生成销售单 →") { dismiss(); showForm = true }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#3370FF"))
                }
            }
        }
        .sheet(isPresented: $showForm) { ProjectFormView() }
    }
}

// MARK: - 购物车行

struct CartItemRow: View {
    let item: CartItem
    @EnvironmentObject var cart: CartManager
    @State private var qtyText = ""

    var body: some View {
        HStack(spacing: 10) {
            // 缩略图
            Group {
                if !item.image.isEmpty {
                    AsyncImage(url: URL(string: "\(ApiConfig.baseURL)/uploads/\(item.image)")) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { Color(hex: "#F5F7FA") }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))   // 填充模式必须裁切，否则图片会溢出方框
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#F5F7FA"))
                        .frame(width: 56, height: 56)
                        .overlay(Text("📦").font(.system(size: 20)))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.skuModel.isEmpty ? item.model : item.skuModel)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text([item.brand, item.style, item.color].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#8F959E"))
                    .lineLimit(1)
                Text("¥\(Product.fmt(item.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#F53F3F"))
            }

            Spacer()

            VStack(spacing: 6) {
                Stepper(qty: item.qty) { delta in
                    Task { try? await cart.add(productId: item.productId, delta: delta, skuId: item.skuId) }
                }
                Button("✕ 删除") {
                    Task {
                        try? await ApiService.shared.delete("/api/cart/\(item.id)")
                        await cart.load()
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#F53F3F"))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

// MARK: - 步进器组件（产品卡/购物车共用）

struct Stepper: View {
    let qty: Int
    var onDelta: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            if qty > 0 {
                Button { onDelta(-1) } label: {
                    Text("−").font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#5A5F6B"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#EFF1F6"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(qty)")
                    .font(.system(size: 15, weight: .bold))
                    .frame(minWidth: 24)

                Button { onDelta(1) } label: {
                    Text("＋").font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#3370FF"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Button { onDelta(1) } label: {
                    Text("＋").font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#3370FF"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - ProductImage 和 StatusTag 定义在 HomeView.swift（含图片缓存）
