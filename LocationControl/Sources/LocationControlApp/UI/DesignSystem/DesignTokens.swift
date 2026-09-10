import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum DesignTokens {
    public enum Colors {
        public static let primaryAccent = Color.blue
        public static let secondaryAccent = Color.indigo
        public static let emeraldSuccess = Color.green
        public static let amberWarning = Color.orange
        public static let crimsonError = Color.red
        
        #if canImport(UIKit)
        public static let cardBackground = Color(UIColor.secondarySystemBackground)
        public static let groupedBackground = Color(UIColor.systemGroupedBackground)
        public static let elevatedBackground = Color(UIColor.tertiarySystemBackground)
        public static let textMuted = Color(UIColor.tertiaryLabel)
        #else
        public static let cardBackground = Color.gray.opacity(0.15)
        public static let groupedBackground = Color.black.opacity(0.05)
        public static let elevatedBackground = Color.gray.opacity(0.1)
        public static let textMuted = Color.secondary.opacity(0.7)
        #endif
        
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
    }

    public enum Radii {
        public static let small: CGFloat = 8.0
        public static let medium: CGFloat = 14.0
        public static let large: CGFloat = 20.0
        public static let pill: CGFloat = 999.0
    }

    public enum Spacing {
        public static let xs: CGFloat = 4.0
        public static let sm: CGFloat = 8.0
        public static let md: CGFloat = 16.0
        public static let lg: CGFloat = 24.0
        public static let xl: CGFloat = 32.0
    }
}
