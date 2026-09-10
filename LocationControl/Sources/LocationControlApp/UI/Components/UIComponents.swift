import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.medium))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

public struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let accentColor: Color

    public init(title: String, value: String, subtitle: String? = nil, icon: String, accentColor: Color = .blue) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.subheadline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.small))
    }
}

public struct StatusBadge: View {
    let text: String
    let isPositive: Bool

    public init(text: String, isPositive: Bool) {
        self.text = text
        self.isPositive = isPositive
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isPositive ? DesignTokens.Colors.emeraldSuccess : DesignTokens.Colors.amberWarning)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2)
                .bold()
                .foregroundStyle(isPositive ? DesignTokens.Colors.emeraldSuccess : DesignTokens.Colors.amberWarning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (isPositive ? DesignTokens.Colors.emeraldSuccess : DesignTokens.Colors.amberWarning).opacity(0.12)
        )
        .clipShape(Capsule())
    }
}
