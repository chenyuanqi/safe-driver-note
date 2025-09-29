# 字体系统

## 字体族
基于系统字体，确保各平台最佳显示效果

```css
--font-family-base: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
--font-family-mono: 'SF Mono', Consolas, 'Liberation Mono', Menlo, monospace;
```

## 字体尺寸系统
采用 8pt 网格系统，确保垂直韵律

### 标题层级
```css
--text-4xl: 32px;   /* 页面主标题 */
--text-3xl: 28px;   /* 模块标题 */
--text-2xl: 24px;   /* 卡片标题 */
--text-xl: 20px;    /* 次级标题 */
--text-lg: 18px;    /* 大号正文 */
```

### 正文层级
```css
--text-base: 16px;  /* 标准正文 */
--text-sm: 14px;    /* 辅助信息 */
--text-xs: 12px;    /* 标签、时间 */
--text-2xs: 10px;   /* 极小文字 */
```

## 字重系统
```css
--font-weight-normal: 400;    /* 正文 */
--font-weight-medium: 500;    /* 强调文字 */
--font-weight-semibold: 600;  /* 次级标题 */
--font-weight-bold: 700;      /* 主要标题 */
```

## 行高系统
```css
--leading-tight: 1.2;   /* 标题行高 */
--leading-normal: 1.5;  /* 正文行高 */
--leading-relaxed: 1.6; /* 长文本行高 */
```

## 使用规范

### 页面标题 (H1)
- **字号**: 32px (text-4xl)
- **字重**: 700 (bold)
- **行高**: 1.2 (tight)
- **颜色**: Secondary-900

### 模块标题 (H2)
- **字号**: 24px (text-2xl)
- **字重**: 600 (semibold)
- **行高**: 1.2 (tight)
- **颜色**: Secondary-900

### 卡片标题 (H3)
- **字号**: 18px (text-lg)
- **字重**: 600 (semibold)
- **行高**: 1.2 (tight)
- **颜色**: Secondary-700

### 正文内容
- **字号**: 16px (text-base)
- **字重**: 400 (normal)
- **行高**: 1.5 (normal)
- **颜色**: Secondary-700

### 辅助信息
- **字号**: 14px (text-sm)
- **字重**: 400 (normal)
- **行高**: 1.5 (normal)
- **颜色**: Secondary-500

### 标签文字
- **字号**: 12px (text-xs)
- **字重**: 500 (medium)
- **行高**: 1.2 (tight)
- **颜色**: Secondary-500 