import SwiftUI

struct ColorTheme: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
}

struct GradientTheme: Codable {
    let colors: [ColorTheme]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
}

enum ThemeStyle: Codable {
    case color(ColorTheme)
    case gradient(GradientTheme)

    enum CodingKeys: String, CodingKey {
        case type, color, gradient
    }

    enum StyleType: String, Codable {
        case color
        case gradient
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StyleType.self, forKey: .type)

        switch type {
        case .color:
            let c = try container.decode(ColorTheme.self, forKey: .color)
            self = .color(c)
        case .gradient:
            let g = try container.decode(GradientTheme.self, forKey: .gradient)
            self = .gradient(g)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .color(let c):
            try container.encode(StyleType.color, forKey: .type)
            try container.encode(c, forKey: .color)

        case .gradient(let g):
            try container.encode(StyleType.gradient, forKey: .type)
            try container.encode(g, forKey: .gradient)
        }
    }
}

extension ThemeStyle {
    func makeStyle() -> AnyShapeStyle {
        switch self {
        case .color(let c):
            let color = Color(red: c.r, green: c.g, blue: c.b, opacity: c.a)
            return AnyShapeStyle(color)

        case .gradient(let g):
            let gradient = LinearGradient(
                colors: g.colors.map {
                    Color(red: $0.r, green: $0.g, blue: $0.b, opacity: $0.a)
                },
                startPoint: g.startPoint,
                endPoint: g.endPoint
            )
            return AnyShapeStyle(gradient)
        }
    }
}

