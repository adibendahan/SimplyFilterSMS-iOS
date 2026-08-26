//
//  DynamicTypeLayout.swift
//  Simply Filter SMS
//
//  Shared adaptive layout for Large Text / accessibility Dynamic Type sizes.
//

import SwiftUI

enum DynamicTypeLayout {
    static let stackedThreshold: DynamicTypeSize = .xxLarge
    static let iconColumnWidth: CGFloat = 28
    static let stackedSpacing: CGFloat = 8
    static let stackedVerticalPadding: CGFloat = 4

    static func needsStackedLayout(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize || size >= stackedThreshold
    }
}

private struct NeedsStackedLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var needsStackedLayout: Bool {
        get { self[NeedsStackedLayoutKey.self] }
        set { self[NeedsStackedLayoutKey.self] = newValue }
    }
}

struct AdaptiveLayoutEnvironment: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.environment(\.needsStackedLayout, DynamicTypeLayout.needsStackedLayout(dynamicTypeSize))
    }
}

private struct AdaptiveStackedRowPadding: ViewModifier {
    @Environment(\.needsStackedLayout) private var needsStackedLayout

    func body(content: Content) -> some View {
        if needsStackedLayout {
            content.padding(.vertical, DynamicTypeLayout.stackedVerticalPadding)
        } else {
            content
        }
    }
}

/// List row that stacks trailing content below the leading + primary column at large Dynamic Type sizes.
struct AdaptiveRow<Leading: View, Content: View, Trailing: View>: View {
    @Environment(\.needsStackedLayout) private var needsStackedLayout

    var stackedTrailingAlignment: HorizontalAlignment = .leading
    var compactAlignment: VerticalAlignment = .center
    var compactSpacing: CGFloat = DynamicTypeLayout.stackedSpacing
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var content: () -> Content
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        if needsStackedLayout {
            VStack(alignment: .leading, spacing: DynamicTypeLayout.stackedSpacing) {
                HStack(alignment: .top, spacing: DynamicTypeLayout.stackedSpacing) {
                    leading()
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                trailing()
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: stackedTrailingAlignment, vertical: .center))
            }
            .modifier(AdaptiveStackedRowPadding())
        } else {
            HStack(alignment: compactAlignment, spacing: compactSpacing) {
                leading()
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing()
            }
        }
    }
}

extension AdaptiveRow where Trailing == EmptyView {
    init(
        stackedTrailingAlignment: HorizontalAlignment = .leading,
        compactAlignment: VerticalAlignment = .center,
        compactSpacing: CGFloat = DynamicTypeLayout.stackedSpacing,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.stackedTrailingAlignment = stackedTrailingAlignment
        self.compactAlignment = compactAlignment
        self.compactSpacing = compactSpacing
        self.leading = leading
        self.content = content
        self.trailing = { EmptyView() }
    }
}

/// Toggle that moves the switch onto its own row at large Dynamic Type sizes.
struct AdaptiveToggle<Label: View>: View {
    @Binding var isOn: Bool
    @Environment(\.needsStackedLayout) private var needsStackedLayout
    @ViewBuilder var label: () -> Label

    var body: some View {
        if needsStackedLayout {
            VStack(alignment: .leading, spacing: DynamicTypeLayout.stackedSpacing) {
                label()
                Toggle(isOn: $isOn) { EmptyView() }
                    .labelsHidden()
            }
            .modifier(AdaptiveStackedRowPadding())
        } else {
            Toggle(isOn: $isOn, label: label)
        }
    }
}

/// Inline controls (caption + button) that stack vertically at large Dynamic Type sizes.
struct AdaptiveFlowRow<Content: View>: View {
    @Environment(\.needsStackedLayout) private var needsStackedLayout
    @ViewBuilder var content: () -> Content

    var body: some View {
        if needsStackedLayout {
            VStack(alignment: .leading, spacing: 4, content: content)
        } else {
            HStack(alignment: .center, spacing: 4, content: content)
        }
    }
}

/// Horizontal group that becomes vertical at large Dynamic Type sizes (e.g. tip cards).
struct AdaptiveStack<Content: View>: View {
    @Environment(\.needsStackedLayout) private var needsStackedLayout
    var spacing: CGFloat = DynamicTypeLayout.stackedSpacing
    @ViewBuilder var content: () -> Content

    var body: some View {
        if needsStackedLayout {
            VStack(spacing: spacing, content: content)
        } else {
            HStack(spacing: spacing, content: content)
        }
    }
}

/// Fixed-size filter option chip — does not scale with Dynamic Type (a11y labels live on the Menu).
struct FilterRowOptionChip: View {
    let systemName: String
    let isActive: Bool

    private let iconSize: CGFloat = 15
    private let buttonSize: CGFloat = 29

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: iconSize))
            .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(width: buttonSize, height: buttonSize)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
    }
}

/// Section column header with an optional leading accessory (e.g. select-all).
struct AdaptiveColumnHeader<Leading: View>: View {
    @Environment(\.needsStackedLayout) private var needsStackedLayout

    @ViewBuilder var leadingAccessory: () -> Leading
    let primary: String
    let secondary: String
    var secondaryIsMuted: Bool = true

    var body: some View {
        if needsStackedLayout {
            HStack(alignment: .top, spacing: DynamicTypeLayout.stackedSpacing) {
                leadingAccessory()
                VStack(alignment: .leading, spacing: 4) {
                    Text(primary)
                    if !secondary.isEmpty {
                        Text(secondary)
                            .if(secondaryIsMuted) { $0.foregroundColor(.secondary) }
                    }
                }
            }
        } else {
            HStack {
                leadingAccessory()
                Text(primary)
                if !secondary.isEmpty {
                    Spacer()
                    Text(secondary)
                        .if(secondaryIsMuted) { $0.foregroundColor(.secondary) }
                        .padding(.trailing, 8)
                }
            }
        }
    }
}

extension AdaptiveColumnHeader where Leading == EmptyView {
    init(primary: String, secondary: String, secondaryIsMuted: Bool = true) {
        self.leadingAccessory = { EmptyView() }
        self.primary = primary
        self.secondary = secondary
        self.secondaryIsMuted = secondaryIsMuted
    }

    init(leading: String, trailing: String, trailingSecondary: Bool = true) {
        self.init(primary: leading, secondary: trailing, secondaryIsMuted: trailingSecondary)
    }
}

extension View {
    func adaptiveLayoutEnvironment() -> some View {
        modifier(AdaptiveLayoutEnvironment())
    }

    func adaptiveIconColumn(width: CGFloat = DynamicTypeLayout.iconColumnWidth) -> some View {
        frame(width: width, alignment: .center)
    }

    func adaptiveStackedRowPadding() -> some View {
        modifier(AdaptiveStackedRowPadding())
    }

    /// Caps Dynamic Type for decorative chrome (footer, toasts, badges) that must stay compact.
    /// VoiceOver labels remain fully accessible; only visual sizing is limited.
    func limitedDynamicTypeSize(_ max: DynamicTypeSize = .xxxLarge) -> some View {
        dynamicTypeSize(...max)
    }
}
