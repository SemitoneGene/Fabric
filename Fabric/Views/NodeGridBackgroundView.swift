import SwiftUI

struct NodeGridBackground: View {
    // Logical grid spacing (in “world” units)
    var baseSpacing: CGFloat = 24
    var majorLineEvery: Int = 5

    // Visual styling
    var backgroundColor: Color = Color(.sRGB, red: 0.13, green: 0.13, blue: 0.15, opacity: 1)
    var minorLineColor: Color = Color.white.opacity(0.06)
    var majorLineColor: Color = Color.white.opacity(0.12)
    var axisLineColor:  Color = Color(.sRGB, red: 0.9, green: 0.5, blue: 0.3, opacity: 0.8)

    var body: some View {
        Canvas { context, size in

            // Derived spacing in screen points
            let spacing = baseSpacing
            guard spacing > 2 else { return } // too zoomed out, grid would be noise

            // How many lines we need to cover the view
            let maxDimension = max(size.width, size.height)
            let halfLines = Int(ceil(maxDimension / spacing)) + majorLineEvery

            var minorPath = Path()
            var majorPath = Path()
            var axisPath  = Path()

            // Vertical lines
            for i in -halfLines...halfLines {
                let x = CGFloat(i) * spacing
                guard x >= 0 && x <= size.width else { continue }

                let lineRect = CGRect(x: x, y: 0, width: 0, height: size.height)

                if abs(x) < 0.5 {
                    // Y-axis
                    axisPath.move(to: lineRect.origin)
                    axisPath.addLine(to: CGPoint(x: x, y: size.height))
                } else if i % majorLineEvery == 0 {
                    majorPath.move(to: lineRect.origin)
                    majorPath.addLine(to: CGPoint(x: x, y: size.height))
                } else {
                    minorPath.move(to: lineRect.origin)
                    minorPath.addLine(to: CGPoint(x: x, y: size.height))
                }
            }

            // Horizontal lines
            for j in -halfLines...halfLines {
                let y = CGFloat(j) * spacing
                guard y >= 0 && y <= size.height else { continue }

                let lineRect = CGRect(x: 0, y: y, width: size.width, height: 0)

                if abs(y) < 0.5 {
                    // X-axis
                    axisPath.move(to: lineRect.origin)
                    axisPath.addLine(to: CGPoint(x: size.width, y: y))
                } else if j % majorLineEvery == 0 {
                    majorPath.move(to: lineRect.origin)
                    majorPath.addLine(to: CGPoint(x: size.width, y: y))
                } else {
                    minorPath.move(to: lineRect.origin)
                    minorPath.addLine(to: CGPoint(x: size.width, y: y))
                }
            }

            context.stroke(minorPath, with: .color(minorLineColor), lineWidth: 1)
            context.stroke(majorPath, with: .color(majorLineColor), lineWidth: 1)
            context.stroke(axisPath,  with: .color(axisLineColor),  lineWidth: 1.5)
        }
        .background(backgroundColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
