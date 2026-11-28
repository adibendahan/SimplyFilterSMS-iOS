//
//  DynamicTypeLayout.swift
//  Simply Filter SMS
//
//  Shared adaptive layout for Large Text / accessibility Dynamic Type sizes.
//

import SwiftUI

enum DynamicTypeLayout {
    static let stackedThreshold: DynamicTypeSize = .xxLarge
    static let iconColumnWidth: CGFloat = IconSize.column
    static let stackedSpacing: CGFloat = Spacing.item
    static let stackedVerticalPadding: CGFloat = Spacing.tight

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
            .accessibilityElement(children: .combine)
            .modifier(AdaptiveStackedRowPadding())
        } else {
            Toggle(isOn: $isOn, label: label)
        }
    }
}

struct AdaptiveFlowRow<Content: View>: View {
    @Environment(\.needsStackedLayout) private var needsStackedLayout
    @ViewBuilder var content: () -> Content

    var body: some View {
        if needsStackedLayout {
            VStack(alignment: .leading, spacing: Spacing.tight, content: content)
        } else {
            HStack(alignment: .center, spacing: Spacing.tight, content: content)
        }
    }
}

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

struct FilterRowOptionChip: View {
    let systemName: String
    let isActive: Bool

    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = TextSize.description

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
        let icon = Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(width: iconSize, height: iconSize)
            .padding(Spacing.item)
        if #available(iOS 26.0, *) {
            icon.glassEffect(.regular, in: shape)
        } else {
            icon.background(Color.surfaceControl, in: shape)
        }
    }
}

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
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    Text(primary)
                    if !secondary.isEmpty {
                        Text(secondary)
                            .if(secondaryIsMuted) { $0.foregroundColor(.textSecondary) }
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
                        .if(secondaryIsMuted) { $0.foregroundColor(.textSecondary) }
                        .padding(.trailing, Spacing.item)
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

private struct AdaptiveLineLimit: ViewModifier {
    @Environment(\.needsStackedLayout) private var needsStackedLayout

    let limit: Int

    func body(content: Content) -> some View {
        if needsStackedLayout {
            content.lineLimit(nil)
        } else {
            content.lineLimit(limit)
        }
    }
}

extension View {
    func adaptiveLayoutEnvironment() -> some View {
        modifier(AdaptiveLayoutEnvironment())
    }

    func adaptiveIconColumn(width: CGFloat = DynamicTypeLayout.iconColumnWidth) -> some View {
        frame(width: width, alignment: .center)
    }

    func adaptiveLineLimit(_ limit: Int) -> some View {
        modifier(AdaptiveLineLimit(limit: limit))
    }

    func limitedDynamicTypeSize(_ max: DynamicTypeSize = .xxxLarge) -> some View {
        dynamicTypeSize(...max)
    }
}
