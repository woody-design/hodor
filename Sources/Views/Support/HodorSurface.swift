import AppKit
import SwiftUI

enum HodorSurfaceStyle {
    case sidebar
    case control
    case interactiveControl
    case toast

    var isInteractiveGlass: Bool {
        switch self {
        case .interactiveControl:
            return true
        case .sidebar, .control, .toast:
            return false
        }
    }

    var material: NSVisualEffectView.Material {
        switch self {
        case .sidebar:
            return .sidebar
        case .control, .interactiveControl, .toast:
            return .popover
        }
    }

    var blendingMode: NSVisualEffectView.BlendingMode {
        switch self {
        case .sidebar, .toast:
            return .behindWindow
        case .control, .interactiveControl:
            return .withinWindow
        }
    }

    var tintColor: Color {
        switch self {
        case .sidebar, .toast:
            return Color(nsColor: .windowBackgroundColor)
        case .control, .interactiveControl:
            return Color(nsColor: .controlBackgroundColor)
        }
    }

    var tintOpacity: Double {
        switch self {
        case .sidebar:
            return 0.38
        case .control:
            return 0.20
        case .interactiveControl:
            return 0.14
        case .toast:
            return 0.52
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .sidebar:
            return 0.14
        case .control, .interactiveControl:
            return 0.10
        case .toast:
            return 0.16
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .sidebar, .toast:
            return 1
        case .control, .interactiveControl:
            return 0.75
        }
    }

    var shadow: (color: Color, radius: CGFloat, y: CGFloat)? {
        switch self {
        case .sidebar:
            return (Color.black.opacity(0.18), 18, 8)
        case .toast:
            return (Color.black.opacity(0.20), 16, 6)
        case .control, .interactiveControl:
            return nil
        }
    }
}

struct HodorSurfaceContainer<Content: View>: View {
    private let usesLiquidGlass: Bool
    private let content: Content

    init(
        usesLiquidGlass: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.usesLiquidGlass = usesLiquidGlass
        self.content = content()
    }

    var body: some View {
        if usesLiquidGlass, #available(macOS 26.0, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
    }
}

extension View {
    func hodorSurface<S: Shape>(
        _ style: HodorSurfaceStyle,
        in shape: S,
        usesLiquidGlass: Bool = true
    ) -> some View {
        modifier(
            HodorSurfaceModifier(
                style: style,
                shape: shape,
                usesLiquidGlass: usesLiquidGlass
            )
        )
    }
}

private struct HodorSurfaceModifier<S: Shape>: ViewModifier {
    let style: HodorSurfaceStyle
    let shape: S
    let usesLiquidGlass: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if usesLiquidGlass, #available(macOS 26.0, *) {
            liquidGlass(content: content)
        } else {
            fallback(content: content)
        }
    }

    @available(macOS 26.0, *)
    @ViewBuilder
    private func liquidGlass(content: Content) -> some View {
        if style.isInteractiveGlass {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }

    @ViewBuilder
    private func fallback(content: Content) -> some View {
        let fallback = content
            .background {
                ZStack {
                    HodorVisualEffectBackground(
                        material: style.material,
                        blendingMode: style.blendingMode
                    )
                    style.tintColor.opacity(style.tintOpacity)
                }
                .clipShape(shape)
            }
            .overlay {
                shape.stroke(
                    Color.primary.opacity(style.strokeOpacity),
                    lineWidth: style.strokeWidth
                )
            }
            .clipShape(shape)

        if let shadow = style.shadow {
            fallback.shadow(
                color: shadow.color,
                radius: shadow.radius,
                y: shadow.y
            )
        } else {
            fallback
        }
    }
}

private struct HodorVisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
    }
}
