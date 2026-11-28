//
//  DesignSystem.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 28/11/2026.
//

import SwiftUI


//MARK: - Apple Defaults -
enum SystemMetric {
    static let screenEdge: CGFloat = 16
    static let rowMargin: CGFloat = 20
    static let disclosureIndent: CGFloat = 20
    static let buttonHeight: CGFloat = 50
    static let minTapTarget: CGFloat = 44
    static let separatorWidth: CGFloat = 1
    static let pageDot: CGFloat = 7
    static let appIconCornerRatio: CGFloat = 0.225
}


//MARK: - System Text -
private enum SystemText {
    static func font(_ style: UIFont.TextStyle) -> UIFont {
        let defaultSize = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFont.preferredFont(forTextStyle: style, compatibleWith: defaultSize)
    }

    static func size(_ style: UIFont.TextStyle) -> CGFloat {
        return self.font(style).pointSize
    }

    static func capHeight(_ style: UIFont.TextStyle) -> CGFloat {
        return self.font(style).capHeight
    }

    static func lineHeight(_ style: UIFont.TextStyle) -> CGFloat {
        let font = self.font(style)
        return font.lineHeight + font.leading
    }
}

enum TextSize {
    static let description: CGFloat = SystemText.size(.subheadline)
}

enum CapHeight {
    static let emphasis: CGFloat = SystemText.capHeight(.headline)
}

enum LineHeight {
    static let heading: CGFloat = SystemText.lineHeight(.title2)
    static let description: CGFloat = SystemText.lineHeight(.subheadline)
}


//MARK: - Spacing -
enum Spacing {
    static let tight: CGFloat = 4
    static let item: CGFloat = 8
    static let edge: CGFloat = SystemMetric.screenEdge
    static let rowMargin: CGFloat = SystemMetric.rowMargin
}

enum LayoutOffset {
    static let disclosureFlush: CGFloat = -SystemMetric.disclosureIndent
    static let collapsedPeek: CGFloat = -20
    static let rowHeightMatch: CGFloat = 8.5
    static let shieldAlign: CGFloat = 12
}


//MARK: - Shape -
enum Radius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 14
    static let large: CGFloat = 24

    static func appIcon(side: CGFloat) -> CGFloat {
        return side * SystemMetric.appIconCornerRatio
    }

    static func nested(in outer: CGFloat, inset: CGFloat) -> CGFloat {
        return outer - inset
    }
}


//MARK: - Size -
enum IconSize {
    static let column: CGFloat = 28
    static let header: CGFloat = 64
    static let headerLandscape: CGFloat = 32
    static let featureMark: CGFloat = SystemText.size(.largeTitle)
    static let signature: CGFloat = SystemText.size(.title1)
}


//MARK: - Opacity -
enum Opacity {
    static let tintFill: Double = 0.12
    static let dim: Double = 0.35
    static let soft: Double = 0.6
}


//MARK: - Text Size -
extension Font {
    static let heading: Font = .title2.bold()
    static let emphasis: Font = .headline
    static let description: Font = .subheadline
    static let label: Font = .footnote
}


//MARK: - Text Color -
extension Color {
    static let text = Color.primary
    static let textSecondary = Color.secondary
    static let textError = Color.red
    static let textOnFill = Color.white
}


//MARK: - Surface -
extension Color {
    static let surfaceScreen = Color(.systemGroupedBackground)
    static let surfaceRow = Color(.secondarySystemGroupedBackground)
    static let surfaceControl = Color(.tertiarySystemFill)

    func highlight() -> Color {
        return self.opacity(Opacity.tintFill)
    }
}
