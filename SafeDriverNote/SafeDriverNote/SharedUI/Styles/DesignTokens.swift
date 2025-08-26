import SwiftUI

// MARK: - Typography System
extension Font {
    // MARK: - Size Tokens
    /// 页面主标题 (32px)
    static let display = Font.system(size: 32, weight: .bold, design: .default)
    
    /// 模块标题 (28px)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    
    /// 卡片标题 (24px)
    static let title2 = Font.system(size: 24, weight: .semibold, design: .default)
    
    /// 次级标题 (20px)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// 大号正文 (18px)
    static let bodyLarge = Font.system(size: 18, weight: .medium, design: .default)
    
    /// 标准正文 (16px)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// 辅助信息 (14px)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    /// 标签、时间 (12px)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    
    /// 极小文字 (10px)
    static let caption2 = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Navigation Specific
    /// 导航栏标题 (24px)
    static let navTitle = Font.system(size: 24, weight: .semibold, design: .default)
    
    /// 底部导航标签 (10px)
    static let navLabel = Font.system(size: 10, weight: .medium, design: .default)
}

// MARK: - Spacing System
struct Spacing {
    /// 2px - 最小间距
    static let xs: CGFloat = 2
    
    /// 4px - 小间距
    static let sm: CGFloat = 4
    
    /// 8px - 标准小间距
    static let md: CGFloat = 8
    
    /// 12px - 中等间距
    static let lg: CGFloat = 12
    
    /// 16px - 标准间距
    static let xl: CGFloat = 16
    
    /// 20px - 大间距
    static let xxl: CGFloat = 20
    
    /// 24px - 很大间距
    static let xxxl: CGFloat = 24
    
    /// 32px - 超大间距
    static let xxxxl: CGFloat = 32
    
    // MARK: - Component Specific
    /// 卡片内边距
    static let cardPadding: CGFloat = 16
    
    /// 页面边距
    static let pagePadding: CGFloat = 16
    
    /// 按钮高度
    static let buttonHeight: CGFloat = 48
    
    /// 输入框高度
    static let inputHeight: CGFloat = 48
    
    /// 导航栏高度
    static let navBarHeight: CGFloat = 56
    
    /// 底部导航高度
    static let bottomNavHeight: CGFloat = 80
}

// MARK: - Corner Radius System
struct CornerRadius {
    /// 4px - 小圆角
    static let xs: CGFloat = 4
    
    /// 6px - 标签圆角
    static let sm: CGFloat = 6
    
    /// 8px - 小组件圆角
    static let md: CGFloat = 8
    
    /// 12px - 标准圆角（卡片、按钮）
    static let lg: CGFloat = 12
    
    /// 16px - 大圆角（模态框）
    static let xl: CGFloat = 16
    
    /// 20px - 超大圆角
    static let xxl: CGFloat = 20
    
    /// 胶囊形状 - 半高度
    static func capsule(height: CGFloat) -> CGFloat {
        return height / 2
    }
}

// MARK: - Shadow System
struct Shadow {
    /// 轻微阴影 - 卡片悬停
    static let sm = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    
    /// 标准阴影 - 卡片
    static let md = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    
    /// 中等阴影 - 按钮
    static let lg = (color: Color.brandPrimary500.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    
    /// 大阴影 - 模态框
    static let xl = (color: Color.black.opacity(0.15), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(8))
    
    /// 超大阴影 - 浮动元素
    static let xxl = (color: Color.black.opacity(0.25), radius: CGFloat(25), x: CGFloat(0), y: CGFloat(20))
}

// MARK: - Animation System
struct Animation {
    /// 标准过渡动画
    static let standard: SwiftUI.Animation = .easeInOut(duration: 0.2)
    
    /// 慢速过渡动画
    static let slow: SwiftUI.Animation = .easeInOut(duration: 0.3)
    
    /// 弹性动画
    static let bouncy: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)
    
    /// 快速淡入淡出
    static let quickFade: SwiftUI.Animation = .easeInOut(duration: 0.15)
}

// MARK: - Opacity System
struct Opacity {
    /// 禁用状态
    static let disabled: Double = 0.3
    
    /// 次要内容
    static let secondary: Double = 0.6
    
    /// 覆盖层
    static let overlay: Double = 0.8
    
    /// 悬停状态
    static let hover: Double = 0.9
    
    /// 按下状态
    static let pressed: Double = 0.7
}