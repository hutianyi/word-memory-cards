# WordMemoryCards 上游复用计划

## 审计基线

- 上游项目：TOEFL Vocab
- 仓库：<https://github.com/a1mohamad/toefl-vocabs-ios-app>
- 审计提交：`ef329ac9ebe416cc2231155a4cd50efe7d4a3bfb`
- 审计日期：2026-09-01
- 许可证：MIT，原作者版权声明已保留在本项目 `LICENSE` 与 `NOTICE`

## 保留或直接改造

- `project.yml` 的 XcodeGen 组织、iOS 16 deployment target 和单元测试 target。
- `Haptics.swift` 的 UIKit 反馈生成器封装，保持无触觉硬件时自然 no-op。
- `PronunciationService.swift` 的长生命周期 `AVSpeechSynthesizer`、停止旧朗读和 delegate 状态管理思路。
- `AdaptiveOrdering.swift` 的平滑错误率、最近错误加权、连续答对惩罚和完整 deterministic tie-break 思路。
- `PracticeViewModel.swift` 的 Session 状态机、开局冻结队列、即时写入和退出确认结构。
- `PracticeView.swift` 的固定退出入口、进度文字、细进度条、大点击区域和 Reduce Motion 处理。
- `ReportsView.swift` 的最近 Session 趋势、薄弱项列表和 Extra Practice 入口结构。
- `ProgressBackup.swift` 的 app marker、格式版本、完整 decode 后再恢复、可读 JSON、`fileExporter` / `fileImporter` 和 security-scoped URL 处理。
- `SettingsView.swift` 的语速滑杆、试听和设置分组方式。
- DesignSystem 中动态颜色、卡片、按钮和可访问性组合的通用做法。

## 必须重写

- `Book / Section / Main / Extra` 教材模型改为单一动态 `Word` 词库。
- 单方向 `VocabItem` 改为一个 Word 对应两个独立 `ReviewState`。
- 五次 cycle 算法改为日期型 Level 0...9 SRS。
- 上游 Codable 单文件进度改为 Core Data + SQLite：`Word`、`ReviewState`、`ReviewEvent`、`StudySession`。
- 队列改为 due-date 主规则、方向级 weakness、防反向答案污染、base queue 冻结和 same-session retry。
- Extra Practice 改为只写独立事件，严格禁止修改正式 SRS 状态或 weakness。
- 单英文 TTS 改为英文/中文双 voice identifier、双语速、正反面自动朗读和真机 voice picker。
- 恢复流程改为 Core Data DTO 的事务化替换，并增加恢复前安全备份。
- iPhone-first 页面改为 iPad-only 横竖屏布局。
- 所有上游业务测试按 WordMemoryCards 规则重写。

## 删除或不引入

- `Resources/VocabData/` 中的 TOEFL / 504 词库和目录数据。
- `BookIntroView`、`SectionIntroView`、教材目录 loader 和 heat grid。
- Persian / RTL 专属内容。
- 五格 cycle、run number、教材分类和 iPhone-only 限制。
- 上游截图、内容迁移脚本和 GitHub Actions 发布流程。

## 新增

- Markdown / 纯文本解析、预览、去重、冲突与无法识别行处理。
- 单词库搜索、编辑、删除及 normalizedEnglish 唯一性校验。
- `SRSScheduler`、`WeaknessScorer`、`ReviewQueueBuilder` 和双向隔离测试。
- Session 中断、最近五次正式首答、正式统计与 streak。
- weakest 20 / 50 / allWeak 的 Extra Practice。
- 完整 backup envelope、schema version、恢复摘要和 round-trip 测试。

## Phase 1 骨架决策

- App：`WordMemoryCards`；显示名称：`单词卡片`。
- Bundle ID：`com.hutianyi.WordMemoryCards`。
- 最低系统：iOS / iPadOS 16.0；设备族：iPad only（`TARGETED_DEVICE_FAMILY = 2`）。
- SwiftUI 使用 iOS 16 可用的 `ObservableObject`、`@StateObject` 和 `NavigationStack`。
- 共享依赖只在 App 根部创建；功能级状态使用显式注入，避免无边界的全局对象。
- 正式数据使用 Core Data SQLite；简单设置使用 `UserDefaults`。
- 不增加第三方运行时依赖。
