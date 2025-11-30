import Foundation

final class ThemeManager {
    static let shared = ThemeManager()

    private let defaultsKey = "app_theme_style"

    private init() {}

    func save(_ theme: ThemeStyle) {
        do {
            let data = try JSONEncoder().encode(theme)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            print("Error encoding theme: \(error)")
        }
    }

    func load() -> ThemeStyle {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let theme = try? JSONDecoder().decode(ThemeStyle.self, from: data) else {
            return ThemeManager.defaultTheme
        }
        return theme
    }

    static let defaultTheme: ThemeStyle = .color(
        ColorTheme(r: 0.118, g: 0.118, b: 0.118, a: 1.0)
    )
}
