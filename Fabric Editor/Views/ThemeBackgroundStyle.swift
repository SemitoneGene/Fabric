import SwiftUI

struct ThemedBackground<Style: ShapeStyle>: View {
    let style: Style

    var body: some View {
        Rectangle()
            .fill(style)
            .ignoresSafeArea()
    }
}

