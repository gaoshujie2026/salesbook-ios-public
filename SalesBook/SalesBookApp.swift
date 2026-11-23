import SwiftUI

@main
struct SalesBookApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var cart = CartManager()
    @StateObject private var catStore = CategoryStore()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(cart)
                .environmentObject(catStore)
                .environmentObject(theme)
                .tint(theme.current.accent)
                .background(theme.current.scene.ignoresSafeArea())
        }
    }
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let h = hex.replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - 根视图（登录态路由）

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            theme.current.scene.ignoresSafeArea()
            if auth.isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
            ShortToastOverlay()
        }
        .environmentObject(theme)
    }
}

// MARK: - 主 TabBar

struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var cart: CartManager
    @EnvironmentObject var theme: ThemeManager
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(0)

            CategoryBrowseView()
                .tabItem { Label("分类", systemImage: "square.grid.2x2.fill") }
                .tag(1)

            ProjectsListView()
                .tabItem { Label("项目", systemImage: "doc.text.fill") }
                .tag(2)

            MineView()
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(3)
        }
        .onAppear {
            Task { await cart.load() }
        }
        .onChange(of: tab) { _ in
            Task { await cart.load() }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(theme.current.dark ? .dark : .light, for: .tabBar)
    }
}
