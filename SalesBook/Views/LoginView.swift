import SwiftUI

// MARK: - 登录页

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var remember = true
    @State private var isLoading = false
    @State private var errorMsg = ""
    @FocusState private var focusField: Field?

    enum Field { case user, pass }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo 区
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text("零")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    )
                Text("产品手册")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#1F2329"))
                Text("员工内部使用")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8F959E"))
            }
            .padding(.bottom, 48)

            // 表单区
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "person")
                        .foregroundColor(Color(hex: "#A6ACB8"))
                    TextField("请输入账号", text: $username)
                        .focused($focusField, equals: .user)
                        .submitLabel(.next)
                        .onSubmit { focusField = .pass }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !username.isEmpty {
                        Button(action: { username = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(hex: "#C4CBD8"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "#F2F3F5"))
                .cornerRadius(12)

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundColor(Color(hex: "#A6ACB8"))
                    SecureField("请输入密码", text: $password)
                        .focused($focusField, equals: .pass)
                        .submitLabel(.go)
                        .onSubmit { Task { await doLogin() } }
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "#F2F3F5"))
                .cornerRadius(12)

                // 记住密码（iOS 无 checkbox 样式，用 SF Symbol 自绘）
                HStack(spacing: 6) {
                    Button {
                        remember.toggle()
                    } label: {
                        Image(systemName: remember ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundColor(remember ? Color(hex: "#3370FF") : Color(hex: "#A6ACB8"))
                    }
                    Text("记住密码")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#646A73"))
                        .onTapGesture { remember.toggle() }
                    Spacer()
                }

                // 错误提示
                if !errorMsg.isEmpty {
                    Text(errorMsg)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 登录按钮
                Button(action: { Task { await doLogin() } }) {
                    HStack {
                        if isLoading { ProgressView().tint(.white) }
                        Text(isLoading ? "登录中…" : "登 录")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(colors: [Color(hex: "#3370FF"), Color(hex: "#5B84FF")],
                                       startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)
                .opacity(username.isEmpty || password.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("登录遇到问题请联系管理员重置密码")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#A6ACB8"))
                .padding(.bottom, 32)
        }
        .background(Color(hex: "#F5F6FA").ignoresSafeArea())
        .onAppear {
            // 恢复记住的密码
            let savedUser = UserDefaults.standard.string(forKey: "saved_user") ?? ""
            let savedPass = Keychain.load("saved_pass") ?? ""
            if !savedUser.isEmpty {
                username = savedUser
                password = savedPass
                remember = true
            }
        }
    }

    private func doLogin() async {
        isLoading = true
        errorMsg = ""
        defer { isLoading = false }

        // 记住密码
        if remember {
            UserDefaults.standard.set(username, forKey: "saved_user")
            Keychain.save("saved_pass", password)
        } else {
            UserDefaults.standard.removeObject(forKey: "saved_user")
            Keychain.delete("saved_pass")
        }

        do {
            try await auth.login(username: username, password: password)
        } catch let e as ApiError {
            errorMsg = e.errorDescription ?? "登录失败"
        } catch {
            errorMsg = "网络连接失败，请检查网络"
        }
    }
}

// MARK: - Checkbox Toggle 样式

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 18))
                .foregroundColor(configuration.isOn ? Color(hex: "#3370FF") : Color(hex: "#C4CBD8"))
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { .init() }
}
