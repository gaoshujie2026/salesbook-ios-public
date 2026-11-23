import SwiftUI

// MARK: - 我的页（完整版）

struct MineView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var cart: CartManager
    @State private var showLogout = false
    @State private var showPwd = false
    @State private var showSkin = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // 账号卡
                    accountCard

                    // 功能入口
                    VStack(spacing: 0) {
                        if auth.user?.isAdmin == true {
                            menuItem(icon: "person.2.fill", title: "员工账号管理", sub: "添加 / 停用 / 重置密码") {
                                ComingSoonView(title: "员工账号管理")
                            }
                            menuItem(icon: "doc.text.fill", title: "Excel 批量导入", sub: "模板下载 · 校验 · 双模式导入") {
                                ComingSoonView(title: "Excel 批量导入")
                            }
                        }
                        menuItem(icon: "square.and.pencil", title: "产品信息补充", sub: "检测缺失信息，点击去补充") {
                            ComingSoonView(title: "产品信息补充")
                        }
                        if auth.user?.isAdmin == true {
                            menuItem(icon: "doc.text.magnifyingglass", title: "操作日志查询", sub: "全员操作留痕") {
                                ComingSoonView(title: "操作日志查询")
                            }
                            menuItem(icon: "arrow.up.arrow.down", title: "排序管理", sub: "分类 / 品牌 / 产品排序") {
                                ComingSoonView(title: "排序管理")
                            }
                        }
                        menuItem(icon: "globe", title: "网页端入口", sub: "复制网页端地址，浏览器粘贴打开") {
                            CopyLinkView(label: "网页端地址已复制", url: "\(ApiConfig.baseURL)/admin/")
                        }
                        menuItem(icon: "square.and.arrow.down.fill", title: "APP 下载", sub: "复制下载链接，发给同事即可安装") {
                            CopyLinkView(label: "下载链接已复制", url: "\(ApiConfig.baseURL)/downloads/app-latest.apk")
                        }
                        menuAction(icon: "paintpalette.fill", title: "界面风格", sub: "iOS 毛玻璃 / 轻奢玻璃 15 款") {
                            showSkin = true
                        }
                        menuAction(icon: "lock.fill", title: "修改密码", sub: "定期修改更安全") {
                            showPwd = true
                        }
                        menuItem(icon: "arrow.up.circle.fill", title: "检查更新", sub: "获取最新版本") {
                            ComingSoonView(title: "检查更新")
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(14)

                    // 退出登录
                    Button { showLogout = true } label: {
                        Text("退出登录")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#F53F3F"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .cornerRadius(14)
                    }

                    Text("公司产品手册 · 内部使用 · v1.0")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#C4CBD8"))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
            .background(Color(hex: "#F5F6FA"))
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("退出登录", isPresented: $showLogout) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                cart.clearLocal()
                auth.logout()
            }
        } message: {
            Text("确定退出当前账号吗？")
        }
        .sheet(isPresented: $showPwd) { ChangePasswordView() }
        .sheet(isPresented: $showSkin) { ThemePickerView() }
    }

    /// 角色显示名（User 模型里没有现成字段）
    private var roleLabel: String {
        let role = auth.user?.role ?? ""
        switch role {
        case "admin": return "管理员"
        case "editor": return "编辑者"
        case "viewer": return "查看者"
        case "": return ""
        default: return role
        }
    }

    private var accountCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Text(auth.user.map { String($0.name.prefix(1)) } ?? "?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(auth.user?.name ?? "—")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#1F2329"))
                Text("\(roleLabel)\(auth.user?.canAgent == true ? " · 渠道价" : "")")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8F959E"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }

    private func menuItem<Detail: View>(icon: String, title: String, sub: String? = nil,
                                        @ViewBuilder destination: @escaping () -> Detail) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "#3370FF"))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#1F2329"))
                    if let s = sub {
                        Text(s)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8F959E"))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#C4CBD8"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 56)
        }
    }

    /// 不跳转页面、只执行一个动作的功能行（弹出窗口等）。
    /// menuItem 的末参是「要跳转的页面」，不能用来放赋值语句。
    private func menuAction(icon: String, title: String, sub: String? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "#3370FF"))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#1F2329"))
                    if let s = sub {
                        Text(s)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8F959E"))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#C4CBD8"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 56)
        }
    }
}

// MARK: - 修改密码

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var oldPwd = ""
    @State private var newPwd = ""
    @State private var newPwd2 = ""
    @State private var saving = false
    @State private var msg = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                VStack(spacing: 0) {
                    pwdField(placeholder: "当前密码", text: $oldPwd)
                    Divider().padding(.leading, 16)
                    pwdField(placeholder: "新密码（至少 6 位）", text: $newPwd)
                    Divider().padding(.leading, 16)
                    pwdField(placeholder: "再次输入新密码", text: $newPwd2)
                }
                .background(Color.white)
                .cornerRadius(12)

                if !msg.isEmpty {
                    Text(msg).font(.system(size: 13)).foregroundColor(.red)
                }

                Button {
                    Task { await save() }
                } label: {
                    Text(saving ? "保存中…" : "确定")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .background(Color(hex: "#3370FF"))
                .cornerRadius(12)
                .disabled(saving)

                Spacer()
            }
            .padding(14)
            .background(Color(hex: "#F5F6FA"))
            .navigationTitle("修改密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func pwdField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(.system(size: 15))
            .padding(.horizontal, 16).padding(.vertical, 13)
    }

    private func save() async {
        guard !oldPwd.isEmpty, !newPwd.isEmpty else { msg = "请填写完整"; return }
        guard newPwd.count >= 6 else { msg = "新密码至少 6 位"; return }
        guard newPwd == newPwd2 else { msg = "两次输入的新密码不一致"; return }
        saving = true
        msg = ""
        do {
            let _: ChangePwdResp = try await ApiService.shared.post(
                "/api/auth/change_password",
                body: ["old_password": oldPwd, "new_password": newPwd],
                as: ChangePwdResp.self)
            saving = false
            dismiss()
        } catch {
            saving = false
            msg = error.localizedDescription
        }
    }
}

/// 修改密码接口的返回是 {"ok": true, "message": "..."}，其中 ok 是布尔值，不能按字符串字典解析
private struct ChangePwdResp: Decodable {
    let ok: Bool
}

// MARK: - 复制链接

struct CopyLinkView: View {
    let label: String
    let url: String
    @State private var copied = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.system(size: 48))
                .foregroundColor(copied ? .green : Color(hex: "#3370FF"))

            Text(copied ? label : "点击复制")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(copied ? .green : Color(hex: "#1F2329"))

            Text(url)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: "#8F959E"))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button {
                UIPasteboard.general.string = url
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copied = false }
                }
            } label: {
                Text("复制")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40).padding(.vertical, 12)
                    .background(Color(hex: "#3370FF"))
                    .cornerRadius(10)
            }
        }
        .padding(20)
    }
}

// MARK: - 开发中占位

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#C4CBD8"))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Text("此功能正在开发中")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8F959E"))
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
