import SwiftUI

// MARK: - 主题模型（15 套：iOS 毛玻璃 5 款 + 轻奢玻璃 10 款，与安卓体验版一致）

struct AppTheme: Identifiable {
    let id: String
    let name: String
    let dark: Bool
    let sceneTop: Color
    let sceneMid: Color
    let sceneBot: Color
    let glassAlpha: Double          // 玻璃卡不透明度（白基色）
    let strokeAlpha: Double         // 描边不透明度
    let ink: Color                  // 主文字
    let sub: Color                  // 次级文字
    let faint: Color                // 辅助文字 / 未选中
    let accent: Color               // 唯一强调色（按钮/选中）
    let price: Color                // 价格/关键数字
    let danger: Color
    let inkOnAccent: Color

    var scene: LinearGradient {
        LinearGradient(colors: [sceneTop, sceneMid, sceneBot],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    /// 玻璃卡底色（白基色 + 不透明度；暗色主题低不透明度白 = 提亮效果）
    var glassColor: Color { Color.white.opacity(glassAlpha) }
    var strokeColor: Color { Color.white.opacity(strokeAlpha) }
    /// 实色面板（对话框/悬浮栏等不能半透明的地方）= 场景中段实色
    var panelColor: Color { sceneMid }

    static func c(_ hex: String) -> Color { Color(hex: hex) }

    static let all: [AppTheme] = [
        // ===== iOS 毛玻璃 5 款 =====
        AppTheme(id: "ioscloud", name: "iOS · 云雾白", dark: false,
                 sceneTop: c("#EEF1F8"), sceneMid: c("#E9EDF4"), sceneBot: c("#E3E8F2"),
                 glassAlpha: 0.60, strokeAlpha: 0.65,
                 ink: c("#1C1C1E"), sub: c("#5F626B"), faint: c("#75777F"),
                 accent: c("#0F5FCC"), price: c("#1C1C1E"), danger: c("#E0443C"),
                 inkOnAccent: .white),
        AppTheme(id: "iosspace", name: "iOS · 深空悬浮", dark: true,
                 sceneTop: c("#0A0E1A"), sceneMid: c("#070A16"), sceneBot: c("#04060D"),
                 glassAlpha: 0.08, strokeAlpha: 0.13,
                 ink: c("#F5F7FA"), sub: c("#A8B0C6"), faint: c("#8D94AD"),
                 accent: c("#2470E0"), price: c("#9ABAFF"), danger: c("#E06A6A"),
                 inkOnAccent: .white),
        AppTheme(id: "iostitan", name: "iOS · 钛黑金", dark: true,
                 sceneTop: c("#17181C"), sceneMid: c("#131316"), sceneBot: c("#0A0A0C"),
                 glassAlpha: 0.58, strokeAlpha: 0.09,
                 ink: c("#F5F5F7"), sub: c("#A9A69E"), faint: c("#8D8A83"),
                 accent: c("#D3B57C"), price: c("#D9BC8B"), danger: c("#E06A6A"),
                 inkOnAccent: c("#241D10")),
        AppTheme(id: "iossunset", name: "iOS · 日落珊瑚", dark: false,
                 sceneTop: c("#FFF1E6"), sceneMid: c("#FFD9CE"), sceneBot: c("#FFC9BD"),
                 glassAlpha: 0.58, strokeAlpha: 0.70,
                 ink: c("#4A2C24"), sub: c("#7D584C"), faint: c("#8D675A"),
                 accent: c("#C74530"), price: c("#A83325"), danger: c("#E0443C"),
                 inkOnAccent: .white),
        AppTheme(id: "iosmint", name: "iOS · 薄荷晨雾", dark: false,
                 sceneTop: c("#F0F9F3"), sceneMid: c("#E4F1EA"), sceneBot: c("#DCEFE6"),
                 glassAlpha: 0.60, strokeAlpha: 0.72,
                 ink: c("#14352A"), sub: c("#4F6B60"), faint: c("#6F9384"),
                 accent: c("#0D7450"), price: c("#0F7A55"), danger: c("#E0443C"),
                 inkOnAccent: .white),
        // ===== 轻奢玻璃 10 款 =====
        AppTheme(id: "l1", name: "雾灰铂银", dark: false,
                 sceneTop: c("#F0F3F7"), sceneMid: c("#E9EDF2"), sceneBot: c("#E2E8EF"),
                 glassAlpha: 0.42, strokeAlpha: 0.10,
                 ink: c("#1C2430"), sub: c("#5D697A"), faint: c("#6E7B8F"),
                 accent: c("#4A6C93"), price: c("#4A6B8F"), danger: c("#D94040"),
                 inkOnAccent: .white),
        AppTheme(id: "l2", name: "烟墨银线", dark: true,
                 sceneTop: c("#1A1C20"), sceneMid: c("#141619"), sceneBot: c("#101215"),
                 glassAlpha: 0.045, strokeAlpha: 0.09,
                 ink: c("#F2F4F7"), sub: c("#8A93A6"), faint: c("#77818C"),
                 accent: c("#2470E0"), price: c("#C9D1DB"), danger: c("#E06A6A"),
                 inkOnAccent: .white),
        AppTheme(id: "l3", name: "月白青金", dark: false,
                 sceneTop: c("#F5F3EE"), sceneMid: c("#F2F0EA"), sceneBot: c("#EBE8E0"),
                 glassAlpha: 0.50, strokeAlpha: 0.10,
                 ink: c("#232A28"), sub: c("#5E6661"), faint: c("#6F7971"),
                 accent: c("#1B4F56"), price: c("#1E5A62"), danger: c("#D94040"),
                 inkOnAccent: .white),
        AppTheme(id: "l4", name: "深海雾金", dark: true,
                 sceneTop: c("#131B2E"), sceneMid: c("#0E1524"), sceneBot: c("#0A0F1C"),
                 glassAlpha: 0.045, strokeAlpha: 0.09,
                 ink: c("#EEF1F6"), sub: c("#747D91"), faint: c("#818CA4"),
                 accent: c("#0A5AC8"), price: c("#D6BB84"), danger: c("#E06A6A"),
                 inkOnAccent: .white),
        AppTheme(id: "l5", name: "鼠尾草灰绿", dark: false,
                 sceneTop: c("#EBEFE9"), sceneMid: c("#E6EAE4"), sceneBot: c("#DEE4DC"),
                 glassAlpha: 0.46, strokeAlpha: 0.10,
                 ink: c("#26302B"), sub: c("#556058"), faint: c("#677369"),
                 accent: c("#3B5745"), price: c("#3D5C49"), danger: c("#D94040"),
                 inkOnAccent: .white),
        AppTheme(id: "l6", name: "暖灰陶土", dark: false,
                 sceneTop: c("#F3F0EB"), sceneMid: c("#EFECE7"), sceneBot: c("#E8E3DC"),
                 glassAlpha: 0.48, strokeAlpha: 0.10,
                 ink: c("#2E2A26"), sub: c("#5E564D"), faint: c("#83796A"),
                 accent: c("#8A4A35"), price: c("#95503A"), danger: c("#D94040"),
                 inkOnAccent: .white),
        AppTheme(id: "l7", name: "深咖奶沫", dark: true,
                 sceneTop: c("#221B16"), sceneMid: c("#1B1512"), sceneBot: c("#14100D"),
                 glassAlpha: 0.05, strokeAlpha: 0.09,
                 ink: c("#F5F0E9"), sub: c("#938878"), faint: c("#A59886"),
                 accent: c("#B29B7E"), price: c("#E0D0BC"), danger: c("#E06A6A"),
                 inkOnAccent: c("#1B1512")),
        AppTheme(id: "l8", name: "雾紫烟灰", dark: true,
                 sceneTop: c("#1F1C2B"), sceneMid: c("#191722"), sceneBot: c("#131119"),
                 glassAlpha: 0.045, strokeAlpha: 0.09,
                 ink: c("#F0EFF5"), sub: c("#878299"), faint: c("#9C94B5"),
                 accent: c("#7A6CAD"), price: c("#B3A6D8"), danger: c("#E06A6A"),
                 inkOnAccent: .white),
        AppTheme(id: "l9", name: "石墨靛光", dark: true,
                 sceneTop: c("#141922"), sceneMid: c("#101418"), sceneBot: c("#0C0F13"),
                 glassAlpha: 0.045, strokeAlpha: 0.09,
                 ink: c("#EFF2F7"), sub: c("#717B8C"), faint: c("#88919F"),
                 accent: c("#4763B8"), price: c("#7E97DB"), danger: c("#E06A6A"),
                 inkOnAccent: .white),
        AppTheme(id: "l10", name: "燕麦深驼", dark: false,
                 sceneTop: c("#F4F0E8"), sceneMid: c("#F0EBE3"), sceneBot: c("#E9E2D6"),
                 glassAlpha: 0.50, strokeAlpha: 0.10,
                 ink: c("#2B2620"), sub: c("#5E564B"), faint: c("#837968"),
                 accent: c("#5F4730"), price: c("#6B4F34"), danger: c("#D94040"),
                 inkOnAccent: .white),
    ]
}

// MARK: - 主题管理器（UserDefaults 持久化；上一版默认 l1 自动迁移到 iOS 云雾白）

final class ThemeManager: ObservableObject {
    @Published var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.id, forKey: "theme.key")
        }
    }

    init() {
        var key = UserDefaults.standard.string(forKey: "theme.key") ?? "ioscloud"
        if key == "l1" {   // 上一版默认迁移
            key = "ioscloud"
            UserDefaults.standard.set(key, forKey: "theme.key")
        }
        current = AppTheme.all.first { $0.id == key } ?? AppTheme.all[0]
    }

    func set(_ theme: AppTheme) {
        current = theme
        UserDefaults.standard.set(theme.id, forKey: "theme.key")
    }
}

// MARK: - 毛玻璃卡（iOS 原生 Material + 主题描边）

struct GlassCard<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    let corner: CGFloat
    let content: Content

    init(corner: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.corner = corner
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(theme.current.strokeColor, lineWidth: 1)
            )
    }
}

// MARK: - 短提示（0.9 秒自动消失，新提示替换旧提示）

final class ToastCenter {
    static let shared = ToastCenter()
    private var hideWork: DispatchWorkItem?

    func show(_ text: String) {
        hideWork?.cancel()
        NotificationCenter.default.post(name: .shortToast, object: text)
        let w = DispatchWorkItem { NotificationCenter.default.post(name: .shortToastHide, object: nil) }
        hideWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: w)
    }
}

extension Notification.Name {
    static let shortToast = Notification.Name("shortToast")
    static let shortToastHide = Notification.Name("shortToastHide")
}

/// 挂在任意页面的短提示浮层（监听 ToastCenter）
struct ShortToastOverlay: View {
    @State private var text: String?
    @State private var visible = false

    var body: some View {
        VStack {
            Spacer()
            if visible {
                Text(text ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.78)))
                    .transition(.opacity)
                    .padding(.bottom, 90)
            }
        }
        .allowsHitTesting(false)
        .onReceive(NotificationCenter.default.publisher(for: .shortToast)) { n in
            text = n.object as? String
            withAnimation(.easeIn(duration: 0.12)) { visible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .shortToastHide)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { visible = false }
        }
    }
}
