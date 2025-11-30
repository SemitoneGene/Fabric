import Foundation

final class AppTheme: ObservableObject {
    @Published var style: ThemeStyle {
        didSet {
            ThemeManager.shared.save(style)
        }
    }

    init() {
        self.style = ThemeManager.shared.load()
    }
}
