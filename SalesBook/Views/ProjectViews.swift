import SwiftUI

// MARK: - 项目列表页（Tab「项目」）

struct ProjectsListView: View {
    @EnvironmentObject var cart: CartManager
    @State private var projects: [Project] = []
    @State private var loading = true
    @State private var showForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 项目购物车卡
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🛒 项目购物车")
                            .font(.system(size: 14, weight: .bold))

                        if cart.items.isEmpty {
                            Text("购物车是空的：去首页/搜索列表点产品旁的「＋」即可加入")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F959E"))
                        } else {
                            ForEach(cart.items) { item in
                                CartItemRow(item: item)
                                Divider().padding(.leading, 76)
                            }
                            HStack {
                                Text("共 \(cart.totalCount) 件 · 合计 ¥\(Product.fmt(cart.totalAmount))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#F53F3F"))
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)

                            Button { showForm = true } label: {
                                Text("填写项目信息，生成销售单")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        LinearGradient(colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                                                       startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)

                    // 历史项目
                    VStack(alignment: .leading, spacing: 10) {
                        Text("历史项目")
                            .font(.system(size: 14, weight: .bold))

                        if loading {
                            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 30)
                        } else if projects.isEmpty {
                            Text("暂无项目")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F959E"))
                                .frame(maxWidth: .infinity).padding(.vertical, 20)
                        } else {
                            ForEach(projects) { prj in
                                NavigationLink(destination: ProjectDetailView(projectId: prj.id)) {
                                    ProjectCard(project: prj)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(Color(hex: "#F5F6FA"))
            .navigationTitle("项目 / 销售单")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showForm) { ProjectFormView() }
    }

    private func load() async {
        loading = true
        do {
            // /api/projects 直接返回数组
            projects = try await ApiService.shared.get("/api/projects", as: [Project].self)
        } catch { }
        loading = false
    }
}

// MARK: - 项目卡

struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top) {
                Text(project.name)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(2)
                Spacer()
                Text("¥\(Product.fmt(project.totalAmount))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#F53F3F"))
            }

            Text([project.customer.isEmpty ? nil : project.customer,
                  "\(project.items.count) 种 / \(project.totalQty) 件",
                  project.ownerName,
                  String(project.createdAt.prefix(16))]
                .compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#8F959E"))
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 0) }
    }
}

// MARK: - 新建项目表单

struct ProjectFormView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cart: CartManager
    @State private var name = ""
    @State private var note = ""
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 项目信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text("项目信息").font(.system(size: 14, weight: .bold))
                        VStack(spacing: 0) {
                            HStack {
                                Text("项目名称").font(.system(size: 14)).frame(width: 80, alignment: .leading)
                                TextField("项目名称（必填）", text: $name)
                                    .font(.system(size: 15))
                            }
                            .padding(.vertical, 10)
                            Divider().padding(.leading, 80)
                            HStack(alignment: .top) {
                                Text("备注").font(.system(size: 14)).frame(width: 80, alignment: .leading)
                                TextField("备注", text: $note, axis: .vertical)
                                    .font(.system(size: 15))
                                    .lineLimit(2...4)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // 已选产品
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已选产品（\(cart.items.count) 种 · \(cart.totalCount) 件）")
                            .font(.system(size: 14, weight: .bold))
                        if cart.items.isEmpty {
                            Text("购物车是空的，先去首页加产品")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F959E"))
                                .padding(.vertical, 12)
                        } else {
                            ForEach(cart.items) { item in
                                CartItemRow(item: item)
                                Divider().padding(.leading, 76)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // 合计
                    VStack(spacing: 8) {
                        HStack {
                            Text("产品合计").font(.system(size: 13))
                            Spacer()
                            Text("¥\(Product.fmt(cart.totalAmount))").font(.system(size: 13, weight: .semibold))
                        }
                        HStack {
                            Text("报价合计").font(.system(size: 15, weight: .bold))
                            Spacer()
                            Text("¥\(Product.fmt(cart.totalAmount))")
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(Color(hex: "#F53F3F"))
                        }
                        Divider()
                        Text("生成后价格快照到项目；购物车保留，点「导出」才保存并清空。")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8F959E"))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // 生成按钮
                    Button {
                        Task { await save() }
                    } label: {
                        if saving {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity).frame(height: 48)
                        } else {
                            Text("生成销售单")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                    }
                    .background(
                        LinearGradient(colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                                       startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                    .disabled(saving || name.isEmpty || cart.items.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(Color(hex: "#F5F6FA"))
            .navigationTitle("新建项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard !name.isEmpty, !cart.items.isEmpty else { return }
        saving = true
        do {
            let _: Project = try await ApiService.shared.post(
                "/api/projects",
                body: ["name": name, "customer": "", "contact": "", "phone": "", "note": note],
                as: Project.self)
            saving = false
            dismiss()
        } catch {
            saving = false
        }
    }
}

// MARK: - 项目详情页

struct ProjectDetailView: View {
    let projectId: Int
    @State private var project: Project?
    @State private var loading = true
    @State private var showEdit = false
    @State private var exportMsg = ""

    var body: some View {
        ScrollView {
            if let p = project {
                VStack(spacing: 12) {
                    // 项目信息卡
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(p.name).font(.system(size: 17, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Color(hex: "#C4C8D0"))
                        }
                        Text([p.customer.isEmpty ? nil : "客户：\(p.customer)",
                              "经办人：\(p.ownerName)",
                              String(p.createdAt.prefix(16))]
                            .compactMap { $0 }.joined(separator: " · "))
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#8F959E"))
                        if !p.note.isEmpty {
                            Text("备注：\(p.note)").font(.system(size: 12)).foregroundColor(Color(hex: "#8F959E"))
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .onTapGesture { showEdit = true }

                    // 产品清单
                    VStack(alignment: .leading, spacing: 8) {
                        Text("产品清单").font(.system(size: 14, weight: .bold))
                        // 表头
                        HStack {
                            Text("产品信息").font(.system(size: 11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                            Text("数量").font(.system(size: 11, weight: .semibold)).frame(width: 44)
                            Text("单价").font(.system(size: 11, weight: .semibold)).frame(width: 54)
                            Text("金额").font(.system(size: 11, weight: .semibold)).frame(width: 60)
                        }
                        .foregroundColor(Color(hex: "#8F959E"))
                        Divider()

                        ForEach(p.items) { item in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                                    Text([item.brand, item.model].filter { !$0.isEmpty }.joined(separator: " "))
                                        .font(.system(size: 11)).foregroundColor(Color(hex: "#8F959E")).lineLimit(1)
                                }
                                Spacer()
                                Text("\(item.qty)").font(.system(size: 13)).frame(width: 44)
                                Text("¥\(Product.fmt(item.price))").font(.system(size: 12)).frame(width: 54)
                                Text("¥\(Product.fmt(item.price * Double(item.qty)))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: "#F53F3F"))
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 5)
                            Divider()
                        }

                        HStack {
                            Spacer()
                            Text("总数：\(p.totalQty)    总价：¥\(Product.fmt(p.totalAmount))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#F53F3F"))
                        }
                        .padding(.top, 6)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)

                    // 操作按钮
                    HStack(spacing: 10) {
                        Button {
                            Task { await exportProject(p) }
                        } label: {
                            Text("导出 Excel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .background(
                            LinearGradient(colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                                           startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            } else if loading {
                ProgressView().padding(.top, 60)
            }
        }
        .background(Color(hex: "#F5F6FA"))
        .navigationTitle(project?.name ?? "项目详情")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("导出", isPresented: .init(get: { !exportMsg.isEmpty }, set: { if !$0 { exportMsg = "" } })) {
            Button("知道了") { exportMsg = "" }
        } message: { Text(exportMsg) }
    }

    private func load() async {
        do {
            // 该接口直接返回项目对象（没有外层包裹）
            project = try await ApiService.shared.get("/api/projects/\(projectId)", as: Project.self)
        } catch { }
        loading = false
    }


    private func exportProject(_ p: Project) async {
        do {
            let data = try await ApiService.shared.download("/api/projects/\(p.id)/export?with_agent=0")
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safeName = p.name.replacingOccurrences(of: "[\\\\/:*?\"<>|]", with: "_", options: .regularExpression)
            let file = dir.appendingPathComponent("销售单-\(safeName)-\(p.id).xlsx")
            try data.write(to: file)
            exportMsg = "已导出到：\n\(file.lastPathComponent)\n\n可在「文件」App 中查看"
        } catch {
            exportMsg = "导出失败：\(error.localizedDescription)"
        }
    }
}
