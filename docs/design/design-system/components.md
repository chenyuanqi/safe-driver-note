# 组件库设计规范

## 基础组件

### 1. 按钮 (Buttons)

#### 主要按钮 (Primary Button)
```css
.btn-primary {
  background: #22C55E;
  color: #FFFFFF;
  border-radius: 12px;
  padding: 12px 24px;
  font-size: 16px;
  font-weight: 600;
  min-height: 48px;
  box-shadow: 0 2px 8px rgba(34, 197, 94, 0.2);
}

.btn-primary:hover {
  background: #16A34A;
  transform: translateY(-1px);
}

.btn-primary:active {
  background: #15803D;
  transform: translateY(0);
}
```

#### 次要按钮 (Secondary Button)
```css
.btn-secondary {
  background: #F1F5F9;
  color: #334155;
  border: 1px solid #CBD5E1;
  border-radius: 12px;
  padding: 12px 24px;
  font-size: 16px;
  font-weight: 500;
  min-height: 48px;
}

.btn-secondary:hover {
  background: #E2E8F0;
  border-color: #94A3B8;
}
```

#### 危险按钮 (Danger Button)
```css
.btn-danger {
  background: #EF4444;
  color: #FFFFFF;
  border-radius: 12px;
  padding: 12px 24px;
  font-size: 16px;
  font-weight: 600;
  min-height: 48px;
}
```

### 2. 卡片 (Cards)

#### 基础卡片
```css
.card {
  background: #FFFFFF;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  border: 1px solid #F1F5F9;
}

.card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
  transition: all 0.2s ease;
}
```

#### 状态卡片
```css
.card-success {
  border-left: 4px solid #22C55E;
  background: #F0FDF4;
}

.card-warning {
  border-left: 4px solid #F59E0B;
  background: #FFFBEB;
}

.card-error {
  border-left: 4px solid #EF4444;
  background: #FEF2F2;
}
```

### 3. 输入框 (Input Fields)

#### 文本输入框
```css
.input-field {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #CBD5E1;
  border-radius: 8px;
  font-size: 16px;
  background: #FFFFFF;
  transition: border-color 0.2s ease;
}

.input-field:focus {
  border-color: #22C55E;
  box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.1);
  outline: none;
}

.input-field::placeholder {
  color: #94A3B8;
}
```

#### 文本域
```css
.textarea {
  min-height: 80px;
  resize: vertical;
  font-family: inherit;
}
```

### 4. 开关 (Switches)

#### 切换开关
```css
.switch {
  width: 48px;
  height: 28px;
  background: #CBD5E1;
  border-radius: 14px;
  position: relative;
  cursor: pointer;
  transition: background 0.2s ease;
}

.switch.active {
  background: #22C55E;
}

.switch::after {
  content: '';
  width: 24px;
  height: 24px;
  background: #FFFFFF;
  border-radius: 50%;
  position: absolute;
  top: 2px;
  left: 2px;
  transition: transform 0.2s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.switch.active::after {
  transform: translateX(20px);
}
```

### 5. 标签 (Tags)

#### 分类标签
```css
.tag {
  display: inline-flex;
  align-items: center;
  padding: 4px 8px;
  background: #F1F5F9;
  color: #64748B;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  margin: 2px;
}

.tag-primary {
  background: #DBEAFE;
  color: #1D4ED8;
}

.tag-success {
  background: #DCFCE7;
  color: #166534;
}

.tag-warning {
  background: #FEF3C7;
  color: #92400E;
}

.tag-error {
  background: #FEE2E2;
  color: #991B1B;
}
```

### 6. 进度条 (Progress Bars)

#### 线性进度条
```css
.progress-bar {
  width: 100%;
  height: 8px;
  background: #F1F5F9;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #22C55E, #16A34A);
  border-radius: 4px;
  transition: width 0.3s ease;
}
```

#### 环形进度条
```css
.circular-progress {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: conic-gradient(#22C55E 0deg 180deg, #F1F5F9 180deg 360deg);
  display: flex;
  align-items: center;
  justify-content: center;
}

.circular-progress::after {
  content: '';
  width: 48px;
  height: 48px;
  background: #FFFFFF;
  border-radius: 50%;
}
```

## 复合组件

### 1. 导航栏 (Navigation)

#### 顶部导航
```css
.top-nav {
  height: 56px;
  background: #FFFFFF;
  border-bottom: 1px solid #F1F5F9;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
}

.nav-title {
  font-size: 18px;
  font-weight: 600;
  color: #0F172A;
}

.nav-button {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748B;
  cursor: pointer;
}

.nav-button:hover {
  background: #F1F5F9;
}
```

#### 底部导航
```css
.bottom-nav {
  height: 80px;
  background: #FFFFFF;
  border-top: 1px solid #F1F5F9;
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 8px 0;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  min-width: 64px;
  padding: 8px;
  color: #94A3B8;
  cursor: pointer;
}

.nav-item.active {
  color: #22C55E;
}

.nav-icon {
  width: 24px;
  height: 24px;
}

.nav-label {
  font-size: 10px;
  font-weight: 500;
}
```

### 2. 列表项 (List Items)

#### 基础列表项
```css
.list-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  background: #FFFFFF;
  border-bottom: 1px solid #F1F5F9;
  cursor: pointer;
}

.list-item:hover {
  background: #F8FAFC;
}

.list-item:active {
  background: #F1F5F9;
}
```

#### 复杂列表项
```css
.complex-list-item {
  display: flex;
  align-items: flex-start;
  padding: 16px;
  gap: 12px;
}

.item-icon {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #F1F5F9;
  flex-shrink: 0;
}

.item-content {
  flex: 1;
  min-width: 0;
}

.item-title {
  font-size: 16px;
  font-weight: 600;
  color: #0F172A;
  margin-bottom: 4px;
}

.item-subtitle {
  font-size: 14px;
  color: #64748B;
  line-height: 1.4;
}

.item-meta {
  font-size: 12px;
  color: #94A3B8;
  margin-top: 8px;
}
```

### 3. 模态框 (Modals)

#### 基础模态框
```css
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #FFFFFF;
  border-radius: 16px;
  max-width: 90vw;
  max-height: 90vh;
  overflow: hidden;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-header {
  padding: 20px 24px 0;
  text-align: center;
}

.modal-title {
  font-size: 18px;
  font-weight: 600;
  color: #0F172A;
}

.modal-body {
  padding: 20px 24px;
}

.modal-actions {
  padding: 0 24px 24px;
  display: flex;
  gap: 12px;
}
```

### 4. 通知提示 (Notifications)

#### Toast 提示
```css
.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: #FFFFFF;
  border-radius: 8px;
  padding: 12px 16px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  z-index: 1001;
  max-width: 320px;
}

.toast-success {
  border-left: 4px solid #22C55E;
}

.toast-error {
  border-left: 4px solid #EF4444;
}

.toast-warning {
  border-left: 4px solid #F59E0B;
}
```

## 动画规范

### 1. 过渡动画
```css
/* 标准过渡 */
.transition-standard {
  transition: all 0.2s ease;
}

/* 慢速过渡 */
.transition-slow {
  transition: all 0.3s ease;
}

/* 弹性动画 */
.transition-bounce {
  transition: all 0.3s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}
```

### 2. 加载动画
```css
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.loading-spinner {
  animation: spin 1s linear infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.loading-pulse {
  animation: pulse 2s ease-in-out infinite;
}
```

### 3. 滑入动画
```css
@keyframes slideInUp {
  from {
    transform: translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.slide-in-up {
  animation: slideInUp 0.3s ease-out;
}
```

## 响应式规范

### 1. 断点定义
```css
/* 小屏设备 */
@media (max-width: 375px) {
  .container { padding: 12px; }
  .card { padding: 12px; }
}

/* 标准设备 */
@media (min-width: 376px) and (max-width: 768px) {
  .container { padding: 16px; }
  .card { padding: 16px; }
}

/* 大屏设备 */
@media (min-width: 769px) {
  .container { padding: 24px; }
  .card { padding: 24px; }
}
```

### 2. 字体缩放
```css
@media (max-width: 375px) {
  .text-4xl { font-size: 28px; }
  .text-3xl { font-size: 24px; }
  .text-2xl { font-size: 20px; }
}
```

## 暗色模式

### 1. 颜色覆盖
```css
@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #000000;
    --bg-secondary: #1C1C1E;
    --text-primary: #FFFFFF;
    --text-secondary: #8E8E93;
    --border-color: #38383A;
  }
}

.dark .card {
  background: var(--bg-secondary);
  border-color: var(--border-color);
  color: var(--text-primary);
}
```

## 使用指南

### 1. 组件命名规范
- 使用BEM命名方式：`.block__element--modifier`
- 保持语义化和可读性
- 避免过度嵌套

### 2. 组合使用
- 优先使用基础组件组合
- 保持设计系统的一致性
- 遵循既定的间距和颜色规范

### 3. 自定义扩展
- 基于现有组件进行扩展
- 保持视觉风格的统一性
- 文档化新增组件的使用方法 