import SwiftUI
import AppKit
import Fabric

struct ContentView: View {

    @EnvironmentObject var appTheme: AppTheme

    @Binding var document: FabricDocument
    @Environment(\.undoManager) private var undoManager

    @GestureState private var magnifyBy = 1.0
    @State private var finalMagnification = 1.0
    @State private var magnifyAnchor: UnitPoint = .center
    @State private var scrollGeometry = ScrollGeometry(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
        containerSize: .zero
    )

    @State private var scrollProxy: ScrollViewProxy?

    @State private var isDraggingForPan = false
    @State private var panStartOffset: CGPoint = .zero
    @State private var handCursorActive = false

    @State private var hitTestEnable = true
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var inspectorVisibility = true
    @State private var scrollOffset: CGPoint = .zero

    private let canvasSize = 10000.0
    private let canvasSizeHalf = 5000.0
    private let inspectorWidth = 250.0
    private let inspectorWidthMax = 300.0
    private let navigationWidthMin = 150.0
    private let navigationWidth = 200.0
    private let navigationWidthMax = 250.0
    private let offsetX = 200.0
    private let zoomMin = 0.25
    private let zoomMax = 2.0

    
    private struct ScrollGeomHelper: Equatable {
        let offset: CGPoint
        let geometry: ScrollGeometry

        static func == (lhs: ScrollGeomHelper, rhs: ScrollGeomHelper) -> Bool {
            lhs.offset == rhs.offset && lhs.geometry == rhs.geometry
        }
    }


    private var trueContentOffset: CGPoint {
        CGPoint(
            x: scrollGeometry.contentOffset.x - scrollGeometry.contentInsets.leading,
            y: scrollGeometry.contentOffset.y - scrollGeometry.contentInsets.top
        )
    }

    private func zoom(by factor: CGFloat) {
        finalMagnification = min(max(finalMagnification * factor, zoomMin), zoomMax)
    }

    private func handleKeyEvents() {
        guard let event = NSApp.currentEvent else { return }
        guard event.type == .keyDown else { return }

        if event.modifierFlags.contains(.command) {
            if event.characters == "=" { zoom(by: 1.1) }
            else if event.characters == "-" { zoom(by: 0.9) }
        }
    }

    private func scrollTo(_ desiredTopLeft: CGPoint) {
        guard let scrollProxy = scrollProxy else { return }

        let contentSize = scrollGeometry.contentSize
        let containerSize = scrollGeometry.containerSize

        guard contentSize.width > 0, contentSize.height > 0 else { return }

        // Clamp to scrollable bounds
        let maxX = max(0, contentSize.width  - containerSize.width)
        let maxY = max(0, contentSize.height - containerSize.height)

        let clampedTopLeft = CGPoint(
            x: max(0, min(desiredTopLeft.x, maxX)),
            y: max(0, min(desiredTopLeft.y, maxY))
        )

        // Convert "top-left desired offset" back into contentOffset including insets
        let realContentOffset = CGPoint(
            x: clampedTopLeft.x + scrollGeometry.contentInsets.leading + offsetX,
            y: clampedTopLeft.y + scrollGeometry.contentInsets.top
        )

        // Compute center point for scrollTo anchor
        let centerPoint = CGPoint(
            x: realContentOffset.x + containerSize.width  / 2,
            y: realContentOffset.y + containerSize.height / 2
        )

        let anchor = UnitPoint(
            x: centerPoint.x / contentSize.width,
            y: centerPoint.y / contentSize.height
        )

        NSAnimationContext.current.allowsImplicitAnimation = false
        scrollProxy.scrollTo("canvas", anchor: anchor)
    }

    // MARK: - Cursor helpers

    private func applyOpenHandCursor() {
        if !handCursorActive {
            NSCursor.openHand.push()
            handCursorActive = true
        }
    }

    private func applyClosedHandCursor() {
        if !handCursorActive {
            NSCursor.closedHand.push()
            handCursorActive = true
        } else {
            NSCursor.closedHand.set()
        }
    }

    private func restoreCursor() {
        if handCursorActive {
            NSCursor.pop()
            handCursorActive = false
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {

            NodeRegisitryView(graph: document.graph, scrollOffset: $scrollOffset)
                .navigationSplitViewColumnWidth(min: navigationWidthMin,
                                                ideal: navigationWidth,
                                                max: navigationWidthMax)

        } detail: {

            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Spacer()

                HStack(spacing: 5) {
                    Text("Root Patch")
                        .font(.headline)
                        .onTapGesture { document.graph.activeSubGraph = nil }

                    if document.graph.activeSubGraph != nil {
                        Text(">").font(.headline)
                        Text("Todo: Graphs Need Names").font(.headline)
                    }
                }
                .padding(.horizontal)

                Spacer()
                Divider()

                ZStack {

                    ThemedBackground(style: appTheme.style.makeStyle())

                    ScrollViewReader { proxy in
                        ScrollView([.horizontal, .vertical]) {
                            NodeCanvas()
                                .frame(width: canvasSize, height: canvasSize)
                                .environment(document.graph)
                                .scaleEffect(finalMagnification * magnifyBy, anchor: magnifyAnchor)
                                .allowsHitTesting(hitTestEnable)
                                .id("canvas")
                                .onAppear {
                                    self.scrollProxy = proxy
                                    document.graph.undoManager = undoManager

                                    // Center on first node after appearance
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
                                        if let firstNode = document.graph.nodes.first {
                                            let target = UnitPoint(
                                                x: (canvasSizeHalf + firstNode.offset.width) / canvasSize,
                                                y: (canvasSizeHalf + firstNode.offset.height) / canvasSize
                                            )
                                            proxy.scrollTo("canvas", anchor: target)
                                        }
                                    }
                                }
                        }
                        .defaultScrollAnchor(.center)
                    }
                    .onScrollGeometryChange(for: ScrollGeomHelper.self) { geometry in
                        let center = CGPoint(x: geometry.contentSize.width / 2,
                                             y: geometry.contentSize.height / 2)
                        let offset = (geometry.contentOffset - center) + (geometry.containerSize / 2)
                        return ScrollGeomHelper(offset: offset, geometry: geometry)
                    } action: { _, newScrollOffset in
                        scrollGeometry = newScrollOffset.geometry
                        scrollOffset = newScrollOffset.offset
                    }
                    .onScrollPhaseChange { _, newPhase in
                        hitTestEnable = !newPhase.isScrolling
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard NSEvent.modifierFlags.contains(.command) else { return }

                            if !isDraggingForPan {
                                panStartOffset = trueContentOffset
                                applyClosedHandCursor()
                                isDraggingForPan = true
                            }

                            hitTestEnable = false

                            let translation = value.translation

                            let newTopLeft = CGPoint(
                                x: panStartOffset.x - translation.width,
                                y: panStartOffset.y - translation.height
                            )

                            scrollTo(newTopLeft)
                        }
                        .onEnded { _ in
                            hitTestEnable = true
                            isDraggingForPan = false
                            restoreCursor()
                        }
                )
                .onHover { inside in
                    if inside && NSEvent.modifierFlags.contains(.command) && !isDraggingForPan {
                        applyOpenHandCursor()
                    } else if !isDraggingForPan {
                        restoreCursor()
                    }
                }
                .onDisappear {
                    restoreCursor()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification)) { _ in
                    handleKeyEvents()
                }
            }
            .inspector(isPresented: $inspectorVisibility) {
                NodeSelectionInspector()
                    .environment(document.graph)
                    .inspectorColumnWidth(min: inspectorWidth,
                                          ideal: inspectorWidthMax,
                                          max: inspectorWidthMax)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Parameters", systemImage: "sidebar.right") {
                        inspectorVisibility.toggle()
                    }
                }
            }
        }
    }
}
