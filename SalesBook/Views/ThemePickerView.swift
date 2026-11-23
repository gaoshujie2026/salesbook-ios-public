import SwiftUI

// MARK: - 界面风格选择（15 款：iOS 毛玻璃 5 款 + 轻奢玻璃 10 款）
// 目前主题作用于：页面底色、强调色（按钮/选中态）、底部标签栏。各页面内部卡片仍是固定配色，待逐步接入。

struct ThemePickerView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(AppTheme.all) { t in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { theme.set(t) }
                        } label: {
                            row(t)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
            .navigationTitle("界面风格")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .background(theme.current.scene.ignoresSafeArea())
    }

    private func row(_ t: AppTheme) -> some View {
        let selected = t.id == theme.current.id
        let dark = theme.current.dark
        return HStack(spacing: 12) {
            // 缩略预览：场景渐变 + 玻璃小卡 + 强调色条
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(t.glassColor)
                    .frame(width: 44, height: 14)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.strokeColor, lineWidth: 1))
                RoundedRectangle(cornerRadius: 3)
                    .fill(t.accent)
                    .frame(width: 28, height: 6)
            }
            .frame(width: 64, height: 46)
            .background(
                LinearGradient(colors: [t.sceneTop, t.sceneMid, t.sceneBot],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(t.name)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(theme.current.ink)
                Text(t.dark ? "暗色氛围 · 白字玻璃" : "亮色氛围 · 墨字玻璃")
                    .font(.system(size: 11))
                    .foregroundColor(theme.current.sub)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(theme.current.accent)
            }
        }
        .padding(10)
        .background(
            // 行底色：亮色主题用白卡，暗色主题用淡白，保证与页面底色有层次
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected
                      ? (dark ? Color.white.opacity(0.16) : Color.white)
                      : (dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? theme.current.accent : Color.white.opacity(0.08),
                        lineWidth: selected ? 1.4 : 1)
        )
    }
}
