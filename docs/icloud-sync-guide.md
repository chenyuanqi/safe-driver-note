# iCloud 同步功能指南

## 概述

安全驾驶助手的 iCloud 同步功能允许您在多设备间同步您的驾驶数据，确保数据安全且随时可访问。所有数据都存储在您的私有 iCloud 数据库中，只有您能够访问。

## 同步的数据类型

### 1. 驾驶日志 (LogEntries)
- **数据类型**: SafeDriverNote_LogEntry
- **内容**:
  - 日志ID、创建时间
  - 日志类型（失误/成功）
  - 位置注释、场景描述
  - 详细描述、原因分析、改进措施
  - 标签、图片ID列表
  - 语音文件名、语音转写文本

### 2. 检查记录 (ChecklistRecords)
- **数据类型**: SafeDriverNote_ChecklistRecord
- **内容**:
  - 记录ID、日期
  - 行前检查状态列表
  - 行后检查状态列表
  - 检查得分

### 3. 检查项目 (ChecklistItems)
- **数据类型**: SafeDriverNote_ChecklistItem
- **内容**:
  - 项目ID、标题、详细描述
  - 检查模式（行前/行后）
  - 优先级（高/中/低）
  - 置顶状态、排序顺序
  - 是否为自定义项目
  - 创建和更新时间

### 4. 打卡记录 (ChecklistPunches)
- **数据类型**: SafeDriverNote_ChecklistPunch
- **内容**:
  - 打卡ID、创建时间
  - 检查模式（行前/行后）
  - 已选检查项目ID列表
  - 是否快速完成
  - 本次得分、位置信息

### 5. 学习进度 (KnowledgeProgress)
- **数据类型**: SafeDriverNote_KnowledgeProgress
- **内容**:
  - 进度ID、知识卡片ID
  - 已掌握日期列表

### 6. 行驶路线 (DriveRoutes)
- **数据类型**: SafeDriverNote_DriveRoute
- **内容**:
  - 路线ID、开始和结束时间
  - 起点和终点位置信息
  - 中间路径点
  - 距离、时长
  - 驾驶状态（进行中/已完成/已取消）
  - 备注信息

### 7. 用户资料 (UserProfile)
- **数据类型**: SafeDriverNote_UserProfile
- **内容**:
  - 用户ID、用户名、年龄
  - 驾龄、车辆类型
  - 头像图片路径
  - 创建和更新时间

## 数据结构

### iCloud 存储结构
```
📁 iCloud.com.safedrivnote.app
└── 📁 私有数据库 (Private Database)
    ├── 📊 SafeDriverNote_LogEntry (驾驶日志表)
    ├── 📊 SafeDriverNote_ChecklistRecord (检查记录表)
    ├── 📊 SafeDriverNote_ChecklistItem (检查项目表)
    ├── 📊 SafeDriverNote_ChecklistPunch (打卡记录表)
    ├── 📊 SafeDriverNote_KnowledgeProgress (学习进度表)
    ├── 📊 SafeDriverNote_DriveRoute (行驶路线表)
    └── 📊 SafeDriverNote_UserProfile (用户资料表)
```

### 记录字段映射

#### LogEntry 字段映射
```
本地字段              → CloudKit 字段
id (UUID)           → id (String)
createdAt (Date)    → createdAt (Date)
type (LogType)      → type (String)
locationNote        → locationNote (String)
scene              → scene (String)
detail             → detail (String)
cause              → cause (String?)
improvement        → improvement (String?)
tags               → tags ([String])
photoLocalIds      → photoLocalIds ([String])
audioFileName      → audioFileName (String?)
transcript         → transcript (String?)
```

#### ChecklistRecord 字段映射
```
本地字段              → CloudKit 字段
id (UUID)           → id (String)
date (Date)         → date (Date)
pre ([ChecklistItemState]) → pre (Data - JSON编码)
post ([ChecklistItemState]) → post (Data - JSON编码)
score (Int)         → score (Int)
```

## 同步功能

### 1. 完整同步
- **功能**: 上传本地数据到 iCloud，同时下载云端数据到本地
- **使用场景**: 初次设置同步或需要双向同步时
- **操作**: 设置 → 数据管理 → iCloud 同步 → 完整同步

### 2. 备份到云端
- **功能**: 仅上传本地数据到 iCloud
- **使用场景**: 定期备份本地数据
- **操作**: 设置 → 数据管理 → iCloud 同步 → 备份到云端

### 3. 从云端恢复
- **功能**: 从 iCloud 下载数据并合并到本地
- **使用场景**: 新设备恢复数据或数据丢失后恢复
- **操作**: 设置 → 数据管理 → iCloud 同步 → 从云端恢复

## 数据恢复流程

### 新设备恢复步骤
1. **登录 iCloud**: 确保设备已登录相同的 iCloud 账户
2. **打开应用**: 启动安全驾驶助手应用
3. **进入设置**: 导航到设置页面
4. **选择 iCloud 同步**: 点击"iCloud 同步"选项
5. **检查状态**: 确认 iCloud 连接状态正常
6. **执行恢复**: 点击"从云端恢复"
7. **确认操作**: 在弹出的确认对话框中点击"确认恢复"
8. **等待完成**: 等待数据下载和恢复完成

### 数据合并规则
- **唯一性**: 基于记录的 UUID 进行去重
- **时间戳**: 保留最新的记录版本
- **冲突解决**: 本地数据优先，云端数据作为补充

## 注意事项

### 前置条件
- ✅ 设备已登录 iCloud 账户
- ✅ iCloud Drive 已启用
- ✅ 网络连接正常
- ✅ iCloud 存储空间充足

### 数据安全
- 🔒 所有数据存储在私有 iCloud 数据库
- 🔒 数据传输过程加密
- 🔒 只有您的设备可以访问您的数据
- 🔒 Apple 无法访问您的个人驾驶数据

### 存储空间
- 📊 驾驶日志：平均每条 ~1-5KB
- 📊 检查记录：平均每条 ~2-8KB
- 📊 行驶路线：平均每条 ~3-10KB
- 📊 用户资料：平均 ~1-2KB
- 📊 **预估总量**: 1000条记录约占用 5-20MB

### 网络建议
- 📶 建议在 WiFi 环境下进行同步
- 📶 避免在数据流量有限的网络下大量同步
- 📶 首次同步可能需要较长时间

### 故障排除

#### 同步失败原因
1. **iCloud 不可用**
   - 解决方案: 检查 iCloud 登录状态和网络连接

2. **网络连接失败**
   - 解决方案: 检查网络连接，尝试切换到 WiFi

3. **存储空间不足**
   - 解决方案: 清理 iCloud 存储空间或升级存储计划

4. **权限不足**
   - 解决方案: 在系统设置中确认应用的 iCloud 权限

#### 常见问题
**Q: 同步需要多长时间？**
A: 取决于数据量和网络速度，通常几秒到几分钟不等。

**Q: 会产生重复数据吗？**
A: 系统会基于 UUID 进行去重，但从云端恢复时可能产生部分重复，建议谨慎使用。

**Q: 可以选择性同步特定数据吗？**
A: 当前版本暂不支持选择性同步，会同步所有类型的数据。

**Q: 多设备间数据会自动同步吗？**
A: 需要手动触发同步，建议定期执行"完整同步"以保持数据一致性。

## 版本兼容性

- **最低支持**: iOS 17.0+
- **iCloud**: 需要 CloudKit 支持
- **Swift**: Swift 5.9+
- **SwiftData**: 需要 SwiftData 框架支持

## 更新日志

### v1.0.0 (2025-09-15)
- ✨ 初始版本发布
- ✨ 支持全量数据同步
- ✨ 支持单向上传和下载
- ✨ 完整的错误处理机制
- ✨ 同步进度和状态显示