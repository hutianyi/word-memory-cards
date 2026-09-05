# WordMemoryCards — Codex 项目启动 Prompt / 产品与实现规格

> 版本：V1.1
> 目标设备：iPad 第五代
> 目标系统：iPadOS 16.7.16
> 项目根目录：本仓库根目录。

---

## 0. 给 Codex 的任务

请在以下目录中开发一个可实际安装到 iPad 第五代、运行于 iPadOS 16.7.16 的原生 SwiftUI 单词复习 App：

```text
<项目根目录>
```

项目工作名：

```text
WordMemoryCards
```

App 显示名称暂定：

```text
单词卡片
```

这是一个家庭自用、给小学生长期复习英语单词的极简 App。核心是：

1. 家长从电脑维护一个 Markdown / 纯文本总词库。
2. 将全文复制到 iPad App。
3. App 自动解析、查重，只加入新词。
4. 每个单词必须分别记忆两个方向：
   - 英文 → 中文
   - 中文 → 英文
5. 两个方向拥有**完全独立的记忆等级、复习日期和正确/错误历史**。
6. 使用简化的 spaced repetition（间隔重复）算法，让熟词越来越少出现，易错词频繁出现。
7. 提供与正式 SRS 完全隔离的 Extra Practice，用于临时加练薄弱卡片。
8. 全部数据只保存在本机，不需要账户、服务器、网络或 iCloud。
9. 使用 iPad 已安装的系统语音朗读：
   - 英文优先：`Zoe（优化）`
   - 中文优先：`语舒`
10. 英文与中文语音分别可调整语速。
11. 界面必须简单、字体大、适合孩子自己操作。
12. 使用免费 Apple ID / Personal Team 通过 Xcode 安装到家庭 iPad，不依赖付费开发者能力。

## 0.1 优先实施策略：直接 Fork / 参考 TOEFL Vocab

本项目**不要求从零开始写所有 SwiftUI 基础代码**。

优先研究并直接 Fork / clone 以下开源项目作为代码基础：

```text
https://github.com/a1mohamad/toefl-vocabs-ios-app
```

项目名称：

```text
TOEFL Vocab
```

该项目的关键技术条件与本项目高度吻合：

- SwiftUI；
- iOS 16.0 deployment target；
- 完全离线；
- `AVSpeechSynthesizer`；
- 两按钮自评；
- 本地学习进度；
- Statistics / Reports；
- JSON backup / restore；
- XcodeGen；
- unit tests；
- 免费 Apple ID / Personal Team 侧载思路；
- MIT License。

因此，Codex 开始工作时应先检查上游代码，再决定哪些文件直接保留、哪些改造、哪些删除，不要无意义地重写已经成熟的通用功能。

### 许可证要求

TOEFL Vocab 使用 MIT License。

允许使用、复制、修改、合并和再分发其代码，但如果本项目复制或实质复用了该项目代码：

- 保留原项目的 MIT `LICENSE` 文本；
- 保留原作者版权声明；
- 可以增加本项目自己的 NOTICE / attribution；
- 不得把原作者代码的版权声明删除后冒充完全原创代码。

原仓库：

```text
https://github.com/a1mohamad/toefl-vocabs-ios-app
```

### 推荐直接参考 / 复用的模块

优先阅读：

```text
Sources/TOEFLVocab/Core/Audio/PronunciationService.swift
Sources/TOEFLVocab/Core/Audio/Haptics.swift
Sources/TOEFLVocab/Core/Engine/AdaptiveOrdering.swift
Sources/TOEFLVocab/Core/Engine/StatsAggregator.swift
Sources/TOEFLVocab/Core/Persistence/ProgressBackup.swift
Sources/TOEFLVocab/Core/Persistence/SettingsStore.swift
Sources/TOEFLVocab/Features/Practice/PracticeView.swift
Sources/TOEFLVocab/Features/Practice/PracticeViewModel.swift
Sources/TOEFLVocab/Features/Practice/SessionSummaryView.swift
Sources/TOEFLVocab/Features/Reports/ReportsView.swift
Sources/TOEFLVocab/Features/Settings/SettingsView.swift
Sources/TOEFLVocab/DesignSystem/
Navigation/
Tests/TOEFLVocabTests/
project.yml
```

其中最值得直接借鉴的现成实现：

- `AVSpeechSynthesizer` 生命周期管理；
- speech rate slider + preview；
- iOS 16 可用的 haptics wrapper；
- Practice 状态机；
- 顶部退出按钮、进度文字、进度条；
- Session Summary；
- Extra Practice 独立统计思想；
- weakness score 思路；
- Reports 的最近 Session 趋势；
- backup envelope、app marker、format version、restore validation；
- Settings 的 `fileExporter` / `fileImporter`；
- XcodeGen 项目组织；
- iOS 16 unit-testable 架构。

### 必须重写或大幅改造的部分

不得直接沿用 TOEFL Vocab 的业务模型：

```text
Book / Section / Main / Extra 教材结构
内置 TOEFL / 504 JSON 词库
五次一个 cycle 的学习算法
单方向 term → definition 学习
iPhone-only layout
```

本项目必须改成：

```text
单一动态词库
+
Markdown / 文本批量导入
+
English ↔ Chinese 双向逻辑卡
+
两个方向独立 ReviewState
+
日期型 SRS
+
Extra Practice 与 SRS 隔离
+
Core Data
+
iPad-first UI
+
完整学习历史和备份
```

### 项目目录处理

如果目标目录为空，可以把上游项目 clone 到临时目录后复制 / 重构：

```text
<项目根目录>
```

如果目标目录已经有文件：

1. 先检查；
2. 不要直接删除已有内容；
3. 不要无条件覆盖；
4. 如需引入上游代码，保留清晰的 Git 历史或 attribution。

如果目录尚未是 Git 仓库，可以初始化本地 Git。

不要自动创建 GitHub remote，也不要自动 push。

请按照本文档直接实现 V1.1，不要主动扩张产品范围。

# 1. 产品定位

这是一个专门用于“长期复习已有英语单词”的家庭工具，不是完整语言学习平台。

产品目标只有三个：

- 输入和维护单词非常方便；
- 孩子每天几分钟即可完成到期复习；
- 早期已经熟练的词不会无意义地天天出现，而容易忘记的词会自动增加复习频率。

核心设计原则：

> 少功能、低干扰、低维护成本、离线可靠、长期可用。

---

# 2. 明确不做的功能

V1 不实现：

- 用户注册；
- 登录；
- 云同步；
- iCloud；
- 网络后端；
- 在线词典；
- 在线翻译；
- AI；
- 图片；
- 例句；
- 音标；
- 单词分类；
- Deck；
- Unit；
- 文件夹；
- 标签；
- 教材体系；
- 拼写测试；
- 听写测试；
- 选择题；
- 游戏化；
- 积分；
- 金币；
- 排行榜；
- 社交；
- 推送通知；
- App Store 发布流程；
- 任何付费 Apple Developer Program 专属能力。

V1 只完成本文档明确列出的需求。

---

# 3. 平台和兼容性硬约束

## 3.1 目标设备

主要真机：

```text
iPad 第五代
iPadOS 16.7.16
```

项目最低部署版本：

```text
iOS / iPadOS 16.0
```

目标设备族优先只做 iPad：

```text
TARGETED_DEVICE_FAMILY = 2
```

界面需要同时适配：

- iPad 竖屏；
- iPad 横屏。

## 3.2 禁止依赖 iOS 17+

不得使用只在 iOS 17 或更高版本可用、且没有兼容分支的 API。

尤其不要把以下技术作为 V1 基础：

- SwiftData；
- `@Observable` 宏；
- 其他 iOS 17+ 独占 UI API。

允许使用：

- Swift；
- SwiftUI；
- NavigationStack；
- Core Data；
- AVFoundation；
- Foundation；
- UniformTypeIdentifiers；
- UIKit 的必要桥接。

## 3.3 依赖原则

优先使用 Apple 原生框架。

V1 原则上不引入第三方运行时依赖。

如果使用 XcodeGen 生成项目是可以接受的；如果本机没有 XcodeGen，可通过 Homebrew 安装。项目运行本身不得依赖 XcodeGen。

---

# 4. 核心数据概念：一个 Word，两张逻辑卡片

这是本项目最重要的业务规则。

例如：

```text
apple 苹果
```

数据库中只存在一个 `Word`：

```text
English: apple
Chinese: 苹果
```

但它对应两张**逻辑复习卡片**：

```text
Card A: English → Chinese
正面：apple
背面：苹果

Card B: Chinese → English
正面：苹果
背面：apple
```

这两个方向必须独立记忆。

例如：

```text
apple → 苹果
Level 8
下次 180 天后

苹果 → apple
Level 3
下次 7 天后
```

这是合法而且正常的状态。

绝对禁止因为一个方向熟练，就自动认为另一个方向也熟练。

---

# 5. ReviewDirection

定义两个方向：

```swift
enum ReviewDirection: String, Codable {
    case englishToChinese
    case chineseToEnglish
}
```

每一个 `Word` 必须自动拥有两个独立 `ReviewState`。

---

# 6. 首页

首页必须极简。

建议结构：

```text
            单词卡片

       今天待复习 18 张

        [ 开始复习 ]

        [ 添加单词 ]

             ⚙︎
```

首页必须突出：

1. 今天还有多少张逻辑卡片到期；
2. 开始复习。

注意：

“今天待复习数量”按**复习方向 / 逻辑卡片**计数，而不是按唯一单词计数。

例如：

```text
apple → 苹果 到期
苹果 → apple 到期
```

算 2 张待复习卡。

---

# 7. Flashcard 复习界面

## 7.1 共同原则

- 一屏只处理一张卡；
- 字体大；
- 点击目标大；
- 无复杂工具栏；
- 无多余说明；
- 默认自动朗读正面；
- 点击卡片后显示答案；
- **答案出现以前不能选择“认识 / 不认识”**。

---

# 8. 英文 → 中文

初始状态：

```text
┌──────────────────────────────┐
│                              │
│            apple             │
│                              │
│              🔊              │
│                              │
└──────────────────────────────┘
```

行为：

1. 卡片出现；
2. 使用英文语音自动朗读 `apple`；
3. 孩子在脑中回忆中文；
4. 点击卡片；
5. 显示中文答案；
6. 自动朗读中文；
7. 出现“认识 / 不认识”。

答案状态：

```text
┌──────────────────────────────┐
│            apple             │
│                              │
│             苹果              │
│                              │
│              🔊              │
└──────────────────────────────┘

[ 不认识 ]               [ 认识 ]
```

---

# 9. 中文 → 英文

初始状态：

```text
┌──────────────────────────────┐
│                              │
│             苹果              │
│                              │
│              🔊              │
│                              │
└──────────────────────────────┘
```

行为：

1. 使用中文语音自动朗读 `苹果`；
2. 孩子回忆英文；
3. 点击卡片；
4. 显示 `apple`；
5. 自动朗读英文；
6. 出现“认识 / 不认识”。

答案状态：

```text
┌──────────────────────────────┐
│             苹果              │
│                              │
│            apple             │
│                              │
│              🔊              │
└──────────────────────────────┘

[ 不认识 ]               [ 认识 ]
```

---

# 10. 双向卡片必须防止“答案污染”

如果一个单词两个方向同一天都到期：

```text
apple → 苹果
苹果 → apple
```

不要把它们连续显示。

原因：

孩子刚刚看到：

```text
apple = 苹果
```

如果下一张立刻问：

```text
苹果 = ?
```

这个回答不能真实反映记忆。

## 10.1 排队规则

如果两个方向都在同一轮：

- 尽可能在两个方向之间插入至少 5 张其他卡；
- 绝对避免前后相邻；
- 如果本轮卡片太少，尽量把反向卡放到本轮末尾；
- 如果仍无法形成合理间隔，可以把其中一个方向留到下一轮。

该规则只影响队列排序，不改变其 SRS 到期时间。

---

# 11. 复习算法：简化 Spaced Repetition

V1 不实现完整 Anki / FSRS。

原因：

- 用户操作只有“认识 / 不认识”两个答案；
- 使用者是儿童；
- 算法需要透明、可预测、容易维护；
- V1 不需要复杂模型参数。

采用固定等级 SRS。

## 11.1 等级与间隔

```text
Level 0   新词 / 需要立即学习
Level 1   1 天
Level 2   3 天
Level 3   7 天
Level 4   14 天
Level 5   30 天
Level 6   60 天
Level 7   120 天
Level 8   180 天
Level 9   365 天
```

代码中使用单一常量表，例如：

```swift
let intervalsInDays = [
    0,
    1,
    3,
    7,
    14,
    30,
    60,
    120,
    180,
    365
]
```

---

# 12. 新卡规则

新导入单词自动建立两个方向：

```text
English → Chinese: Level 0
Chinese → English: Level 0
```

两张卡都从今天开始进入待复习集合。

但队列必须遵循前面的“双向防答案污染”规则，不能刚学完一个方向立刻出现反方向。

---

# 13. 点击“认识”

对于正式到期复习：

```text
newLevel = min(oldLevel + 1, 9)
nextReview = 今天 + intervalsInDays[newLevel]
```

例如：

```text
Level 3
当前间隔 7 天

认识
↓

Level 4
下次 14 天后
```

Level 9 再次认识：

```text
仍为 Level 9
下次 365 天后
```

不要永久删除熟练词。

---

# 14. 点击“不认识”

如果正式到期复习回答“不认识”：

```text
newLevel = floor(oldLevel / 2)
nextReview = 明天
```

例如：

```text
Level 8
↓ 不认识
Level 4
↓
明天再次正式复习
```

Level 1 不认识：

```text
Level 1 → Level 0
明天正式复习
```

Level 0 不认识：

```text
Level 0 → Level 0
明天正式复习
```

---

# 15. 当天错误后的再次出现

回答“不认识”以后：

1. 当前卡不能立即再次出现；
2. 把同一个方向重新插入当前轮；
3. 尽量间隔 5～10 张其他卡；
4. 标记为 `sameSessionRetry = true`。

如果孩子在这个当天重试中回答“认识”：

- 记录一次成功；
- 但**不要因此再次升级 Level**；
- 也不要取消“明天正式复习”；
- `nextReview` 仍然是明天。

这样避免：

```text
刚刚看过答案
→ 几分钟后记住
→ 被误判为长期掌握
```

当天重试主要用于巩固，而不是决定长期间隔。

如果当天重试再次“不认识”：

- 保持当前已经降低后的 Level；
- `nextReview` 仍为明天；
- 如果队列条件允许，可以再次在稍后插入；
- 同一张卡单轮最多重试 2 次，避免孩子陷入无限循环。

---

# 16. 日期计算

SRS 以用户本地日历日期为单位。

不要要求“精确到上一次回答后的 24 小时”。

例如：

```text
2026-09-01 晚上复习
nextReview = 2026-09-02
```

第二天即可复习。

使用 `Calendar.current` 进行日期归一化。

---

# 17. 熟练定义

## 17.1 单方向熟练

一个 ReviewDirection：

```text
Level >= 7
```

视为该方向熟练。

也就是下一次间隔已经达到至少 120 天。

## 17.2 整个单词熟练

只有：

```text
English → Chinese Level >= 7
AND
Chinese → English Level >= 7
```

才把整个 Word 统计为“已熟练单词”。

---

# 18. 每轮复习数量

设置项：

```text
每轮最多复习
20
30
50
不限
```

默认：

```text
30
```

这里的“30”指 30 张**逻辑复习卡**，不是 30 个唯一 Word。

例如：

```text
apple 英→中
apple 中→英
```

如果两个方向都进入一轮，算 2 张。

当天错误产生的 `sameSessionRetry` 不占用最初抽取的 30 张额度。

---

# 19. 待复习队列生成、Weakness Score 与队列冻结

正式待复习条件：

```text
nextReviewDate <= today
```

## 19.1 正式 SRS 是主规则

是否“今天应该出现”只由：

```text
nextReviewDate
```

决定。

Weakness Score **不能擅自让一个尚未到期的正式 SRS 卡提前进入正常复习**。

## 19.2 Weakness Score

借鉴 TOEFL Vocab 的 `AdaptiveOrdering.swift` 思路，为每一个**方向级逻辑卡**计算 weakness。

只使用：

```text
scheduled / 正式复习
+
isSameSessionRetry == false
```

的首答历史。

必须排除：

- Extra Practice；
- same-session retry；
- 仅仅因为刚刚看过答案而产生的短期正确。

建议：

```swift
smoothedErrorRate =
    (Double(unknownCount) + 0.5)
    / (Double(formalAttempts) + 1.0)

score = smoothedErrorRate

if lastFormalAnswerWasKnown == false {
    score += 0.35
}

score -= Double(min(consecutiveKnown, 5)) * 0.06
```

原则：

- 正式错误率越高，越弱；
- 最近刚答错，明显加权；
- 连续正式答对，会降低 weakness；
- 使用平滑错误率，避免“只答过 1 次且答错”永久显示为 100% 弱；
- `unseen` 可以内部使用约 0.5 的中性 score；
- 但“薄弱词排行榜”不得把从未正式回答过的卡当成薄弱卡。

该公式应集中在：

```text
WeaknessScorer.swift
```

并可单元测试。

## 19.3 正式到期队列优先级

从 due cards 中排序：

1. 逾期天数更多；
2. weakness score 更高；
3. Level 更低；
4. 稳定 deterministic tie-break。

不要依赖 Swift `sort` 的稳定性。

最终 tie-break 可以使用：

```text
normalizedEnglish
+
direction
+
ReviewState UUID
```

确保同一批历史数据每次生成基本一致的队列。

不要为了“随机感”引入不可预测的全量 shuffle。

## 19.4 双向防答案污染

随后应用：

- 同一个 Word 的两个方向绝对避免前后相邻；
- 尽量至少隔 5 张其他卡；
- 卡片过少时优先把反向卡推到本轮末尾；
- 必要时把其中一张留到下一轮。

## 19.5 Session 开始后冻结主队列

这是硬规则。

进入一轮正式复习时：

```text
选出本轮最多 N 张正式到期卡
↓
完成优先级排序
↓
完成双向防答案污染
↓
冻结 base queue
```

此后回答过程中：

> **不得因为刚刚的回答改变 weakness / Level 后重新排序剩余的 base queue。**

否则后续卡片会不断跳动，Session 不可预测。

一轮中只允许以下显式队列变化：

1. `sameSessionRetry` 插回；
2. 极少数为避免同 Word 双方向紧邻产生的局部位置调整。

下一轮开始时才重新根据最新历史构建新的 base queue。

## 19.6 same-session retry 插入

正式回答“不认识”后：

- 不立即再次出现；
- 尽量插入当前索引之后 5～10 张；
- 不修改 base queue 已有相对顺序；
- 同一张逻辑卡单轮最多 retry 2 次。

队列算法必须可单元测试。

# 20. 手工添加单词

“添加单词”页面支持两种方式。

## 20.1 单个添加

```text
英文
[ apple ]

中文
[ 苹果 ]

[ 添加 ]
```

添加前执行查重。

如果已存在：

```text
apple 已经存在
```

不要新建。

---

# 21. 批量文本 / Markdown 输入

主要使用方式：

用户在 Mac 上长期维护完整 Markdown 单词文档。

例如：

```md
# 英语单词总表

## 2026-09-01

apple 苹果
orange 橙子
banana 香蕉

## 2026-09-10

beautiful 美丽的
different 不同的
ice cream 冰淇淋
```

每次更新后，用户会：

1. Mac 上全文复制；
2. iPad 打开 App；
3. 进入“添加单词”；
4. 粘贴全部内容；
5. App 自动识别；
6. 自动查重；
7. 只加入真正的新词。

因此：

> 重复粘贴完整总词库必须是安全操作。

---

# 22. 文本 Parser

不要把这个功能做成完整 Markdown Parser。

只需要逐行扫描并提取“英文 + 中文”。

## 22.1 忽略

自动忽略：

```text
空行
# 标题
## 标题
### 标题
---
***
```

以及明显不包含有效中英文词条的行。

## 22.2 支持的常见形式

至少支持：

```text
apple 苹果
apple    苹果
apple<TAB>苹果
- apple 苹果
* apple 苹果
apple - 苹果
apple — 苹果
ice cream 冰淇淋
look after 照顾
```

## 22.3 推荐解析策略

优先：

1. 去掉行首 Markdown bullet；
2. trim；
3. 如果存在 Tab，尝试按第一个 Tab 分左右；
4. 如果存在明确分隔符 ` - ` / ` — `，尝试拆分；
5. 否则寻找第一个 CJK 中文字符的位置；
6. 中文第一个字符之前作为 English；
7. 从第一个中文字符开始作为 Chinese；
8. 两边 trim。

这样可以正确处理：

```text
ice cream 冰淇淋
look after 照顾
```

而不是只取第一个英文 token。

## 22.4 有效性校验

English：

- 至少包含一个英文字母；
- 不得为空。

Chinese：

- 至少包含一个 CJK 汉字；
- 不得为空。

无法确认的行进入“无法识别”列表，不要静默导入垃圾数据。

---

# 23. 英文查重规则

英文是词条唯一键。

生成：

```text
normalizedEnglish
```

标准化至少包括：

1. trim；
2. 转 lowercase；
3. 多个连续空格折叠成一个；
4. Unicode normalization；
5. 弯引号 `’` 统一为 `'`。

例如：

```text
Apple
apple
 APPLE
apple
```

全部视为同一个词。

例如：

```text
can't
can’t
```

也应视为同一个词。

不要为了查重而删除正常连字符、撇号或词内部空格。

---

# 24. 重复导入绝不能破坏学习记录

例如数据库已有：

```text
apple
English → Chinese Level 8
Chinese → English Level 6
累计复习 30 次
```

用户重新全文粘贴：

```text
apple 苹果
```

必须：

- 不创建第二个 apple；
- 不重置 Level；
- 不重置 nextReviewDate；
- 不重置统计；
- 不删除 ReviewEvent。

如果 English 相同，但 Chinese 与现有值不同：

例如：

```text
数据库：
apple 苹果

导入：
apple 苹果；苹果公司
```

V1 行为：

- 标记为“冲突”；
- 不自动覆盖；
- 保留数据库原内容；
- 提示用户可进入词库手工修改。

不要在批量导入时静默覆盖已有中文释义。

---

# 25. 导入预览

粘贴后不要立即写入数据库。

先点：

```text
[ 分析 ]
```

显示：

```text
共扫描：150 行
识别词条：127
新增：22
已存在：103
冲突：1
无法识别：1
```

提供：

```text
[ 查看新增 ]
[ 查看问题 ]
[ 导入 22 个新单词 ]
```

只有用户明确点击导入后才写入数据库。

导入完成：

```text
成功新增 22 个单词
自动创建 44 张双向复习卡
```

---

# 26. 词库管理

不需要单独“家长模式”。

在 Settings 中提供：

```text
词库
1,238 个单词
>
```

进入后：

- 搜索英文；
- 搜索中文；
- 查看列表；
- 点击进入编辑；
- 修改英文；
- 修改中文；
- 删除词条。

## 26.1 修改英文

修改英文时需要重新执行 normalizedEnglish 唯一性检查。

如果新英文已经存在：

- 禁止保存；
- 显示冲突提示。

## 26.2 修改中文

修改中文不能影响两个方向的 SRS 历史。

## 26.3 删除

删除前二次确认：

```text
删除 apple？

这会同时删除：
- 两个方向的复习状态
- 该单词的历史学习记录

此操作不可撤销。
```

---

# 27. TTS 发音

使用：

```text
AVSpeechSynthesizer
AVSpeechSynthesisVoice
AVSpeechUtterance
```

必须完全离线工作。

不要接入第三方 TTS。

## 27.1 首选声音

用户已经在 iPad 系统中下载了较高质量语音。

英文首选：

```text
Zoe（优化）
```

中文首选：

```text
语舒
```

## 27.2 不要硬猜 Voice Identifier

不要在代码里仅根据网上资料写死一个未经真机验证的 identifier。

启动后：

```swift
AVSpeechSynthesisVoice.speechVoices()
```

枚举设备实际可用的声音。

读取至少：

```text
identifier
name
language
quality
```

## 27.3 Voice Selection Service

实现独立：

```text
SpeechService
VoiceResolver
```

英文：

1. 优先寻找 name 对应 Zoe；
2. 优先 Enhanced / Premium / 更高 quality；
3. 如果找不到，使用用户设置中选定的 en-US 英文声音；
4. 再不行 fallback 到系统默认英文语音。

中文：

1. 优先寻找 `语舒` 对应的实际已安装 voice；
2. 如果系统 API 返回的 name 不是中文显示名，允许通过 Settings 手工从 zh-CN voice 列表选择；
3. 保存实际 `identifier`；
4. fallback 到 zh-CN 系统声音。

## 27.4 英文 / 中文语速必须分别可调

借鉴 TOEFL Vocab 的 speech-rate 设置。

英文和中文保存两个独立参数：

```text
englishSpeechRate
chineseSpeechRate
```

建议范围：

```text
0.30 ... 0.62
```

默认值：

```text
0.46
```

如果真机 Zoe / 语舒实际听感需要不同默认值，可以在真机调试阶段微调，但必须保留独立设置。

设置界面：

```text
英文语音
Zoe（优化） >

英文语速
🐢 ─────●───── 🐇
[ 试听英文 ]

中文语音
语舒 >

中文语速
🐢 ─────●───── 🐇
[ 试听中文 ]
```

试听必须使用当前：

```text
voice identifier
+
对应语言 speech rate
```

## 27.5 设置页必须可以测试语音

点入 voice picker 后，只列出对应语言的已安装 / 可用系统声音。

保存 identifier，而不只是 display name。

## 27.6 AVSpeechSynthesizer 生命周期

不要每次点击都临时创建新的 synthesizer。

使用长生命周期 `AVSpeechSynthesizer`，由 `SpeechService` 持有。

需要正确处理：

- 连续翻卡；
- 上一个声音仍在播放；
- 快速点击；
- App 进入后台 / 前台；
- 切换语音；
- 调整语速后立即试听。

必要时新朗读前停止旧朗读。

可以直接参考上游：

```text
Sources/TOEFLVocab/Core/Audio/PronunciationService.swift
Sources/TOEFLVocab/Features/Settings/SettingsView.swift
```

但需要改造成双语言、双 voice identifier、双 speech rate。

# 28. 自动朗读规则

## English → Chinese

卡片出现：

```text
自动朗读 English
```

翻面：

```text
自动朗读 Chinese
```

## Chinese → English

卡片出现：

```text
自动朗读 Chinese
```

翻面：

```text
自动朗读 English
```

每个可见内容旁保留扬声器按钮，用于重复播放当前文字。

设置里增加：

```text
自动朗读正面：开 / 关
自动朗读答案：开 / 关
```

默认都开启。

---

# 29. 本地数据模型

因为最低支持 iPadOS 16：

> 不使用 SwiftData。

推荐使用：

```text
Core Data + SQLite persistent store
```

原因：

- Apple 原生；
- iOS 16 支持；
- 数据量可长期增长；
- ReviewEvent 可能积累很多条；
- 比每次重写一个越来越大的 JSON 文件更可靠；
- 方便查询今日统计、错词和到期任务。

---

# 30. Core Data Entity 设计

## 30.1 Word

建议字段：

```text
id: UUID
english: String
normalizedEnglish: String   // unique
chinese: String
createdAt: Date
updatedAt: Date
```

约束：

```text
normalizedEnglish unique
```

关系：

```text
Word 1 -> 2 ReviewState
Word 1 -> many ReviewEvent
```

---

# 31. ReviewState

每一个 Word 固定两条 ReviewState。

字段：

```text
id: UUID
direction: String

level: Int16
nextReviewDate: Date
lastReviewDate: Date?

totalReviews: Int64
knownCount: Int64
unknownCount: Int64
consecutiveKnown: Int32
lapseCount: Int64

lastResult: String?
createdAt: Date
updatedAt: Date
```

关系：

```text
word -> Word
```

唯一逻辑约束：

```text
(word, direction)
```

必须只有一条。

---

# 32. ReviewEvent 与 StudySession

## 32.1 ReviewEvent

每一次点击“认识 / 不认识”都产生事件。

字段：

```text
id: UUID
reviewedAt: Date

direction: String
result: String              // known / unknown

practiceMode: String        // scheduled / extraPractice

levelBefore: Int16
levelAfter: Int16

isSameSessionRetry: Bool
sessionID: UUID

wordEnglishSnapshot: String
wordChineseSnapshot: String
```

关系：

```text
word -> Word
reviewState -> ReviewState
session -> StudySession
```

保存 snapshot，是为了将来修改词条后历史仍有基本可读性。

### scheduled 事件

正式 SRS 事件：

```text
practiceMode = scheduled
```

只有：

```text
scheduled
+
isSameSessionRetry == false
```

的首答可以：

- 驱动 Level；
- 驱动 nextReviewDate；
- 进入正式 weakness；
- 进入首答正确率；
- 进入最近 5 次正式结果。

### Extra Practice 事件

额外加练：

```text
practiceMode = extraPractice
```

Extra Practice：

- 可以保存自己的 known / unknown 历史；
- 可以显示本轮正确率；
- **绝对不能修改 ReviewState.level**；
- **绝对不能修改 nextReviewDate**；
- **绝对不能改变正式 SRS weakness score**；
- **不能把正式学习进度“刷高”或“刷低”**。

这是硬约束。

## 32.2 StudySession

为支持：

- 最近 10～12 次 Session 趋势；
- 完整退出 / 中断规则；
- Session Summary；
- scheduled / extra 分离；
- `8 / 30` 进度；

增加 Core Data Entity：

```text
StudySession
```

建议字段：

```text
id: UUID

mode: String                 // scheduled / extraPractice

startedAt: Date
finishedAt: Date?

completed: Bool

baseTaskCount: Int32
formalAnswered: Int32
formalKnown: Int32
formalUnknown: Int32

retryAnswered: Int32
extraAnswered: Int32
extraKnown: Int32
extraUnknown: Int32
```

`formal*` 只用于 scheduled Session 的正式首答。

一个 Session 即使中途退出，也保留：

```text
completed = false
```

的记录。

如果一张都没有回答，可以不保存空 Session，避免 timeline 垃圾数据。

# 33. App Settings

简单设置使用：

```text
UserDefaults / AppStorage
```

至少包括：

```text
sessionLimit

englishVoiceIdentifier
chineseVoiceIdentifier

englishSpeechRate
chineseSpeechRate

autoSpeakFront
autoSpeakBack

hapticsEnabled

extraPracticeScope
```

建议：

```text
englishSpeechRate = 0.46
chineseSpeechRate = 0.46
hapticsEnabled = true
```

Extra Practice scope 建议：

```text
weakest20
weakest50
allWeak
```

也可以提供：

```text
everything
```

但默认不要让孩子一次进入几百张。

不要把这些简单设置塞进 Core Data。

# 34. 学习统计与 Session 趋势

Settings / Statistics 显示：

```text
总单词
今日待复习卡
已熟练单词
今日已正式复习
今日首答正确率
连续学习天数
累计正式复习次数
累计不认识次数
```

## 34.1 今日首答正确率

为了避免：

- same-session retry；
- Extra Practice；

人为改变正式记忆判断：

```text
今日首答正确率
```

只统计：

```text
practiceMode == scheduled
AND
isSameSessionRetry == false
```

公式：

```text
known / (known + unknown)
```

## 34.2 最近 10～12 次正式 Session 趋势

借鉴 TOEFL Vocab Reports 的 recent-session trend。

显示最近：

```text
12 次
```

`scheduled` Session 的首答正确率。

不把 Extra Practice 混进去。

可以使用 iOS 16 自带：

```text
Swift Charts
```

做非常简单的 bar chart / line-like trend。

例如：

```text
最近复习正确率

82  76  85  88  91  89 ...
▅   ▃   ▆   ▇   █   ▇
```

目的只是让家长快速看到：

> 最近正式复习是在改善、持平还是下降。

不要做复杂 Dashboard。

如果 Session 不足 2 次：

- 不显示趋势图；
- 显示简单统计即可。

Extra Practice 可以在单独位置显示累计次数，但不进入正式趋势。

# 35. 连续学习天数

定义：

只要某个本地日历日存在至少一条：

```text
isSameSessionRetry == false
```

的 ReviewEvent，就算当天完成过学习。

根据本地 `Calendar.current` 连续日期计算 streak。

---

# 36. 薄弱卡片与 Extra Practice

## 36.1 薄弱度是方向级

因为：

```text
apple → 苹果
```

和：

```text
苹果 → apple
```

可能强弱完全不同。

所以 weakness 必须针对：

```text
ReviewState / direction
```

而不是只针对 Word。

例如：

```text
because

英 → 中   Level 7   weakness 0.18
中 → 英   Level 3   weakness 0.82
```

薄弱项应显示：

```text
because
中 → 英 较弱
```

## 36.2 薄弱卡排行榜

只包含：

```text
至少正式答错过 1 次
```

的逻辑卡。

从未正式见过：

```text
unseen
```

不等于：

```text
weak
```

使用 Section 19 的 `WeaknessScorer` 排序。

设置 / Statistics：

```text
容易忘记的卡片
>
```

例如：

```text
because        中 → 英
through        中 → 英
different      英 → 中
```

## 36.3 Extra Practice

这是 V1.1 必须功能。

入口建议放在：

```text
学习统计
```

或首页次级入口：

```text
[ 加练薄弱词 ]
```

不要让它抢占首页“开始正式复习”的主按钮。

进入：

```text
额外加练

最弱 20 张
最弱 50 张
全部薄弱卡

[ 开始 ]
```

可选：

```text
全部卡片
```

但默认 scope 使用最弱 20。

## 36.4 Extra Practice 队列

排序依据：

```text
正式 scheduled history 的 weakness
```

不是 Extra Practice 自己练出来的分数。

同 weakness 时：

1. Extra Practice 次数较少的优先；
2. stable tie-break。

仍然应用：

- 同 Word 双方向不相邻；
- 尽量间隔；
- Session 开局冻结队列。

## 36.5 Extra Practice 绝不改变 SRS

回答：

```text
认识
不认识
```

只写：

```text
ReviewEvent(practiceMode = extraPractice)
```

不得调用正式：

```text
SRSScheduler
```

不得修改：

```text
level
nextReviewDate
formalKnownCount
formalUnknownCount
formalConsecutiveKnown
formalWeakness
```

即使一天额外练 100 次：

> 正式 SRS 到期日也保持原样。

这是为了让临时强化不能污染长期记忆模型。

可以直接借鉴 TOEFL Vocab：

```text
PracticeMode.main / extra
ExtraPracticeScope
AdaptiveOrdering.extraPracticeQueue
Reports DrillCard
```

但需要改成我们的双向逻辑卡和正式 SRS 隔离模型。

# 37. 双向统计与最近 5 次结果

在单词详情里显示：

```text
apple

英文 → 中文
Level 8
下次：2027-03-01
正式认识：12
正式不认识：1

最近 5 次
✓ ✓ ✓ ✕ ✓


中文 → 英文
Level 5
下次：2026-10-01
正式认识：8
正式不认识：4

最近 5 次
✕ ✓ ✕ ✓ ✓
```

## 37.1 最近 5 次的定义

只取：

```text
practiceMode == scheduled
AND
isSameSessionRetry == false
```

的最近 5 次正式首答。

不把：

- same-session retry；
- Extra Practice；

放进这五格。

这样五格表示真正的长期记忆表现，而不是“刚看过答案后马上会了”。

如果不足 5 次：

```text
✓ ✕ · · ·
```

可以用空心格 / 中性占位。

## 37.2 展示位置

最近 5 次结果：

- 只放 Word detail / ReviewState detail；
- 可以放薄弱卡详情；
- **不要放儿童主 Flashcard**。

主复习界面继续保持极简。

# 38. 备份与恢复

必须实现。

Settings：

```text
数据管理

[ 导出完整备份 ]
[ 从备份恢复 ]
```

## 38.1 Backup Envelope

不要只导出裸数据库内容。

借鉴 TOEFL Vocab 的 `ProgressBackup.swift`，顶层加入身份标记和版本。

建议：

```json
{
  "app": "WordMemoryCards",
  "backupFormatVersion": 1,
  "schemaVersion": 1,
  "appVersion": "1.1",
  "exportedAt": "2026-09-01T10:30:00+08:00",
  "data": {}
}
```

其中：

```text
app
```

必须精确匹配：

```text
WordMemoryCards
```

这样误选其他 JSON 文件时要明确失败，而不是尝试半恢复。

## 38.2 导出内容

备份必须包含：

```text
Words
ReviewStates
ReviewEvents
StudySessions
AppSettings
```

目标：

> 即使 App 被误删，也能在重新安装后恢复全部学习状态。

导出文件名：

```text
WordMemoryCards-Backup-2026-09-01.json
```

建议：

```text
prettyPrinted
sortedKeys
ISO 8601 dates
```

让备份文件本身可读。

## 38.3 双版本号

区分：

```text
backupFormatVersion
```

和：

```text
schemaVersion
```

`backupFormatVersion`：

- backup envelope 本身格式变化时升级。

`schemaVersion`：

- App 内数据模型变化时升级。

不要把两个概念混为一个数字。

## 38.4 恢复前验证

顺序必须是：

1. 读取文件；
2. 完整 decode；
3. 验证 `app == WordMemoryCards`；
4. 验证 `backupFormatVersion`；
5. 验证 `schemaVersion`；
6. 验证基本数据完整性；
7. 显示摘要；
8. 用户确认；
9. 才允许替换当前数据库。

坏文件：

> 绝不能先改数据库再发现解码失败。

## 38.5 恢复摘要

确认弹窗显示例如：

```text
备份日期：2026-09-01 10:30
单词：1,238
双向复习状态：2,476
学习记录：18,520
Session：386
App 版本：1.1
```

然后：

```text
恢复会替换当前本地数据。
```

## 38.6 恢复前安全备份

正式覆盖前：

- 自动导出 / 生成一次当前数据库临时备份；
- 如果 restore transaction 失败，当前数据保持或可回滚。

恢复尽量事务化。

可以直接参考：

```text
Sources/TOEFLVocab/Core/Persistence/ProgressBackup.swift
Sources/TOEFLVocab/Features/Settings/SettingsView.swift
```

尤其借鉴：

- app marker；
- format validation；
- decode before overwrite；
- summary before restore；
- SwiftUI `fileExporter` / `fileImporter`；
- security-scoped file access。

但 backup data body 必须换成我们的 Core Data DTO。

# 39. UI 设计原则、进度与触觉

目标用户是儿童，优先级：

```text
可读性 > 简洁 > 动画 > 装饰
```

## 39.1 Flashcard

- 卡片占屏幕主体；
- 大圆角；
- 大字体；
- 足够留白；
- 英文单词建议约 52～72 pt，自适应；
- 中文建议约 44～64 pt，自适应；
- 长词 / phrase 使用 `minimumScaleFactor`；
- 不因为横屏而把卡片拉得过宽。

## 39.2 顶部 Session Bar

复习过程中始终显示轻量顶部栏：

```text
×                       8 / 30
━━━━━━━━━━━━━━━━━━━━━━━━━━
```

包括：

- 左侧退出；
- 当前正式 base card 进度；
- 细进度条。

`30` 是 Session 开始时冻结的：

```text
baseTaskCount
```

same-session retry 不增加 base denominator。

如果当前正在 retry，可以用很小的提示：

```text
重试
```

不要因为 retry 把：

```text
8 / 30
```

突然变成：

```text
8 / 34
```

正式 base progress 表示“这一轮原计划多少张”。

Extra Practice 也显示：

```text
8 / 20
```

但其 mode 明确是“额外加练”。

## 39.3 按钮

“认识 / 不认识”：

- 高度至少约 60 pt；
- 点击区域大；
- 两个按钮视觉区分明确；
- 不靠小 icon 判断；
- 答案出现之前隐藏或 disable。

## 39.4 触觉反馈

借鉴 TOEFL Vocab：

```text
Sources/TOEFLVocab/Core/Audio/Haptics.swift
```

为了兼容 iOS 16，使用：

```text
UINotificationFeedbackGenerator
UIImpactFeedbackGenerator
```

不要使用 iOS 17+ 才有的 `.sensoryFeedback`。

建议：

```text
认识       success-like
不认识     warning-like
普通点击   light impact
Session 完成 milestone success-like
```

设置：

```text
触觉反馈：开 / 关
```

默认开。

但必须：

> 如果具体 iPad 硬件不提供实际触觉能力，调用失败或无物理反馈时要自然 no-op，不能影响答题逻辑。

触觉只是附加反馈，绝不能成为判断答题成功与否的必要信号。

## 39.5 动画

翻面可以有简单动画，但：

- 不要复杂；
- 不要拖慢 iPad 第五代；
- 支持 Reduce Motion；
- 动画不是业务逻辑依赖。

可以参考 TOEFL Vocab 的 DesignSystem 和 PracticeView，但需要做成 iPad-first 布局。

# 40. 设置页面

建议结构：

```text
设置

复习
  每轮最多复习：30

发音
  自动朗读正面：开启
  自动朗读答案：开启

  英文语音：Zoe（优化）
  英文语速：正常
  [试听英文]

  中文语音：语舒
  中文语速：正常
  [试听中文]

反馈
  触觉反馈：开启

学习统计
  >

容易忘记的卡片
  >

额外加练
  最弱 20 / 最弱 50 / 全部薄弱
  [开始 Extra Practice]

词库
  1,238 个单词
  >

数据管理
  导出完整备份
  从备份恢复

关于
  数据仅保存在此 iPad
  Version ...
```

不需要单独家长密码。

App 可以自然跟随系统 Light / Dark appearance。

V1.1 不需要专门做复杂主题系统。

# 41. Session 完成、退出与中断

## 41.1 正式 Session 完成

例如：

```text
本轮完成

正式复习：30
认识：26
不认识：4
首答正确率：87%

今天还有 18 张待复习

[ 再来一轮 ]
[ 返回首页 ]
```

same-session retry 不计入：

```text
正式复习 30
首答正确率
```

如果需要，可以额外显示：

```text
当天重试：5 次
```

但不要让结束页过载。

如果今天无到期卡：

```text
今天的复习完成了
```

## 41.2 Extra Practice 完成

显示：

```text
额外加练完成

练习：20
认识：15
不认识：5
正确率：75%

正式 SRS 进度未被改变。

[ 再练一轮 ]
[ 返回 ]
```

不要把 Extra Practice accuracy 合并进正式首答正确率。

## 41.3 退出按钮

复习页面必须始终有：

```text
×
```

不能把用户困在 Session 里。

借鉴 TOEFL Vocab 的退出行为。

### 一张都没回答

如果：

```text
answered == 0
```

直接退出。

不要弹一个毫无意义的确认框。

### 已经回答过

如果已经完成部分：

```text
17 / 30
```

点击退出：

```text
退出本轮复习？

已经完成的回答会保留。
未完成的卡片下次会重新根据当前 SRS 状态进入队列。

[继续复习]
[退出]
```

## 41.4 回答必须即时保存

每次点击：

```text
认识 / 不认识
```

后：

1. 写 ReviewEvent；
2. 正式模式则更新 ReviewState；
3. 保存；
4. 再允许 advance。

不能把整轮回答只放内存，等到 Session 结束一次性保存。

因此中途退出时：

> 已经回答的内容不回滚。

## 41.5 中断 Session

如果用户退出了一个已经有回答的 Session：

```text
StudySession.completed = false
finishedAt = 当前时间
```

Session history 可以保留该条记录。

但是“最近 12 次正式正确率趋势”默认只使用：

```text
有足够 formalAnswered 的 Session
```

可以包含中断 Session，也可以在 chart 中用不同样式；V1.1 最简单做法：

> 趋势只统计 `formalAnswered > 0`，不要求 completed == true。

因为 17 张真实首答仍然是有效学习数据。

## 41.6 未完成卡片下次怎么处理

退出以后：

- 不保存剩余 in-memory queue；
- 不要求 Resume 原顺序；
- 下一次开始重新根据持久化状态 build queue。

因此：

- 已经正式答对并被排到未来的卡，不再出现；
- 已经正式答错的卡，其 `nextReviewDate = 明天` 保留；
- 根本没答到的 due cards 仍然 due；
- pending same-session retry 可以丢弃，因为长期状态已经安全保存。

不要用金币、烟花、积分等奖励机制。

# 42. 空状态

没有单词时：

```text
还没有单词

先添加一些单词开始学习。

[ 添加单词 ]
```

今天无到期卡：

```text
今天没有需要复习的单词。
```

---

# 43. 数据可靠性要求

这是长期学习 App，学习历史比 UI 动画重要。

必须：

- Core Data save 失败时不能静默吞掉；
- 添加 / 编辑失败给用户明确提示；
- 批量导入使用 background context 或合理批处理，避免 UI 卡死；
- 恢复备份尽量事务化；
- 批量导入中途失败不能留下明显的半完成脏状态；
- 唯一键冲突需要处理；
- 不要因为重复导入改变 ReviewState。

---

# 44. 性能要求

目标设备较老。

因此：

- 不使用重量级动画；
- 不加载网络；
- 不使用大型第三方框架；
- 词库列表使用 LazyVStack / List；
- 搜索做 debounce 或合理 fetch predicate；
- Statistics 查询不要每次无脑加载所有 ReviewEvent 到内存；
- Core Data 做合适的 fetch / aggregate；
- 预期支持至少几千 Word 和长期数万至十万级 ReviewEvent。

---

# 45. 隐私

App：

- 不联网；
- 不收集数据；
- 不上传学习记录；
- 不需要 Analytics SDK；
- 不需要广告；
- 不需要 tracking permission。

---

# 46. 推荐代码架构

不需要过度工程化。

建议：

```text
WordMemoryCards/
├── App/
│   └── WordMemoryCardsApp.swift
│
├── Core/
│   ├── Persistence/
│   │   ├── PersistenceController.swift
│   │   └── CoreData models
│   │
│   ├── Models/
│   │   ├── ReviewDirection.swift
│   │   ├── ReviewResult.swift
│   │   ├── PracticeMode.swift
│   │   └── DTOs.swift
│   │
│   ├── SRS/
│   │   ├── SRSScheduler.swift
│   │   ├── WeaknessScorer.swift
│   │   └── ReviewQueueBuilder.swift
│   │
│   ├── Import/
│   │   ├── VocabularyParser.swift
│   │   ├── ImportAnalyzer.swift
│   │   └── ImportModels.swift
│   │
│   ├── Speech/
│   │   ├── SpeechService.swift
│   │   └── VoiceResolver.swift
│   │
│   ├── Feedback/
│   │   └── Haptics.swift
│   │
│   ├── Backup/
│   │   ├── BackupService.swift
│   │   └── BackupModels.swift
│   │
│   └── Statistics/
│       └── StatisticsService.swift
│
├── Features/
│   ├── Home/
│   ├── Review/
│   ├── ExtraPractice/
│   ├── AddWords/
│   ├── WordLibrary/
│   ├── Statistics/
│   ├── Settings/
│   └── Backup/
│
├── Shared/
│   ├── Components/
│   └── Extensions/
│
└── Tests/
```

Core Data 至少：

```text
Word
ReviewState
ReviewEvent
StudySession
```

不要为了“Clean Architecture”再制造不必要的层。

## 46.1 与 TOEFL Vocab 的映射

优先借鉴：

```text
TOEFL Vocab                         WordMemoryCards

PronunciationService.swift    →     SpeechService.swift
Haptics.swift                 →     Haptics.swift
AdaptiveOrdering.swift        →     WeaknessScorer + queue ordering
StatsAggregator.swift         →     StatisticsService
ProgressBackup.swift          →     BackupService / BackupModels
PracticeView.swift            →     ReviewView
PracticeViewModel.swift       →     ReviewSessionViewModel
SessionSummaryView.swift      →     SessionSummaryView
ReportsView.swift             →     StatisticsView + ExtraPractice entry
SettingsView.swift            →     SettingsView
DesignSystem/                 →     Shared Components / Theme
Router.swift                  →     Navigation / Router
```

原则：

> 可以复用成熟的通用代码结构，但业务模型必须服从本文档，而不是为了少改代码反过来迁就 TOEFL Vocab。

# 47. SRS 必须与 UI 解耦

`SRSScheduler` 应该是纯业务逻辑，可直接单元测试。

类似：

```swift
struct SRSDecision {
    let newLevel: Int
    let nextReviewDate: Date
}

protocol SRSScheduling {
    func result(
        level: Int,
        answer: ReviewResult,
        date: Date,
        calendar: Calendar
    ) -> SRSDecision
}
```

same-session retry 逻辑可以由 Review Session ViewModel / Engine 管理。

---

# 48. Queue Builder 与 Weakness 必须单独测试

输入：

```text
一组 due ReviewState
sessionLimit
当前日期
正式学习历史
```

输出：

```text
冻结的 base ReviewTask[]
```

必须确保：

- limit 正确；
- 逾期更久优先；
- weakness 高优先；
- Level 更低作为后续优先级；
- stable tie-break；
- 双方向不相邻；
- 尽可能间隔 5 张；
- Session 开始以后 base queue 不因答题重新排序；
- same-session retry 能延后插入；
- retry 不破坏 base queue 剩余相对顺序；
- 不产生重复任务 bug。

WeaknessScorer 必须测试：

- unseen；
- 1 次错误；
- 多次历史；
- recent mistake bonus；
- consecutive-known penalty；
- Extra Practice 不影响 weakness；
- same-session retry 不影响 weakness。

# 49. Import Parser 必须单独测试

至少覆盖：

```text
apple 苹果
Apple 苹果
- apple 苹果
* apple 苹果
apple - 苹果
apple — 苹果
ice cream 冰淇淋
look after 照顾
can't 不能
can’t 不能

# Unit 1
---
空行
错误行
```

验证：

- 解析；
- normalization；
- duplicate；
- conflict；
- invalid line。

---

# 50. 双向 SRS 单元测试

这是最高优先级测试之一。

必须测试：

## Case A

```text
apple 英→中 Level 5
apple 中→英 Level 2
```

英→中回答认识后：

```text
英→中 Level 6
中→英仍 Level 2
```

## Case B

中→英回答不认识后：

```text
中→英下降
英→中完全不变
```

## Case C

两个方向同日到期：

不得在队列中相邻，除非实际卡片总量小到无法避免；即使无法避免也应优先推迟其中一个方向。

---

# 51. Backup / Session / Extra Practice 单元测试

## 51.1 Backup round-trip

构造：

```text
10 Words
20 ReviewStates
100 ReviewEvents
8 StudySessions
Settings
```

执行：

```text
export
→ clear test store
→ restore
```

结果必须完全一致。

特别验证：

- 双方向状态没有交换；
- Level；
- nextReview；
- knownCount；
- unknownCount；
- history；
- StudySession；
- voice identifiers；
- English / Chinese speech rate；
- haptics setting；
- Extra Practice settings；
- session limit。

## 51.2 Backup envelope

必须测试：

```text
正确 app marker
错误 app marker
较新 backupFormatVersion
坏 JSON
缺字段的旧兼容格式（如果支持）
```

坏文件不能修改当前数据库。

## 51.3 Extra Practice 隔离

构造：

```text
apple 中→英
Level 5
nextReview = 30 天后
```

Extra Practice 连续：

```text
错
错
对
对
```

验证：

```text
Level 仍 5
nextReview 完全不变
正式 weakness 不变
Extra ReviewEvent 有 4 条
```

## 51.4 Session 中断

开始 30 张：

```text
答 7 张
退出
```

验证：

- 7 张回答已经持久化；
- StudySession `completed == false`；
- 剩余 23 张未产生虚假 ReviewEvent；
- 下次重新生成队列，而不是依赖旧内存 queue。

# 52. 真机 TTS 与反馈验证

Simulator 不能作为最终语音验证依据。

在真机 iPad 上检查：

1. 能枚举系统安装声音；
2. 英文能选择用户已经下载的 Zoe 优化语音；
3. 中文能选择语舒；
4. 保存后重启 App 仍使用同一 identifier；
5. English speech rate 保存并生效；
6. Chinese speech rate 保存并生效；
7. 两种语速可以不同；
8. 正面自动朗读；
9. 翻面自动朗读；
10. 快速切换卡片不会发生明显串音；
11. 扬声器按钮可重复播放；
12. 调整语速后试听立即反映新值；
13. haptics 开关不会影响正常答题；
14. 如果设备没有实际触觉能力，功能自然 no-op。

如果无法通过 display name 自动匹配“语舒”，必须保证 Settings voice picker 可以手工选择正确实际 voice。

# 53. 安装方式

用户已经有 Xcode。

目标是：

```text
Xcode
+
免费 Apple ID / Personal Team
+
家庭 iPad
```

不需要：

- App Store；
- TestFlight；
- Paid Developer Program。

Bundle ID 使用一个稳定且不会随每次 build 改变的值，例如：

```text
com.hutianyi.WordMemoryCards
```

免费签名过期后用户重新通过 Xcode build / install。

重要：

> 重新签名和重新安装同一个 Bundle ID 时，不应主动清空本地 Core Data 数据。

仍然必须提供 JSON Backup，因为用户可能误删 App。

---

# 54. 项目构建方式

如果使用 XcodeGen，推荐：

```text
deploymentTarget:
  iOS: "16.0"
```

并设置：

```text
TARGETED_DEVICE_FAMILY: "2"
```

保证项目能：

```bash
xcodebuild
```

成功构建。

如果当前 Xcode 没有 iOS 16 Simulator，也必须至少：

- 使用当前可用 Simulator SDK 编译；
- Deployment Target 保持 16.0；
- 不出现 iOS 17+ API availability error。

最终兼容性以 iPadOS 16.7.16 真机为准。

---

# 55. Codex 执行流程

请按以下阶段执行，不要一次堆大量未经验证的代码。

## Phase 0 — Fork / 上游代码审计

先获取：

```text
https://github.com/a1mohamad/toefl-vocabs-ios-app
```

检查：

- LICENSE；
- project.yml；
- PronunciationService；
- Haptics；
- AdaptiveOrdering；
- ProgressBackup；
- Practice；
- Reports；
- Settings；
- Tests。

输出一份简短：

```text
REUSE_PLAN.md
```

列清楚：

```text
保留
改造
删除
新增
```

然后再动主代码。

## Phase 1 — iPad 项目骨架

完成：

- 从上游架构迁移 / 改名；
- SwiftUI App；
- iPadOS 16 target；
- `TARGETED_DEVICE_FAMILY = 2`；
- Core Data；
- 首页；
- Settings；
- 基础导航；
- 保留 MIT attribution。

构建通过。

## Phase 2 — 数据与导入

完成：

- Word；
- 两个 ReviewState；
- ReviewEvent；
- StudySession；
- VocabularyParser；
- Import Preview；
- 去重；
- conflict；
- 单词库 CRUD。

单元测试通过。

## Phase 3 — 正式 SRS + Weakness + Queue

完成：

- SRSScheduler；
- WeaknessScorer；
- ReviewQueueBuilder；
- 双方向独立状态；
- 防答案污染；
- Session base queue freeze；
- same-session retry；
- session limit；
- deterministic ordering。

单元测试通过。

## Phase 4 — Review UI + TTS + Haptics

完成：

- 双方向 Flashcard；
- 翻面；
- 两按钮；
- `8 / 30`；
- 进度条；
- 退出 / 中断；
- SpeechService；
- Voice picker；
- English / Chinese 独立 speech rate；
- 自动朗读；
- haptics。

## Phase 5 — Extra Practice

完成：

- weakest 20 / 50 / allWeak；
- direction-level weakness；
- Extra Practice queue；
- 独立 ReviewEvent；
- 不修改 SRS；
- Extra Session Summary。

隔离测试通过。

## Phase 6 — Statistics

完成：

- 今日到期；
- 总词；
- 熟练词；
- 今日首答正确率；
- streak；
- 薄弱卡；
- 单词双方向详情；
- 最近 5 次正式结果；
- 最近 12 次 scheduled Session 趋势。

## Phase 7 — Backup

完成：

- backup envelope；
- app marker；
- formatVersion；
- schemaVersion；
- JSON export；
- validate；
- restore；
- restore confirmation；
- pre-restore safety backup；
- round-trip tests。

## Phase 8 — 真机收尾

检查：

- iPad 第五代尺寸；
- 横竖屏；
- 大字体；
- Zoe；
- 语舒；
- 双语语速；
- 性能；
- haptics graceful no-op；
- Personal Team 安装。

# 56. Codex 工作纪律

每完成一个阶段：

1. build；
2. 运行相关 tests；
3. 修复 warning / error；
4. 再进入下一阶段。

不要在代码明显不能编译时继续向下堆功能。

任何业务逻辑不确定时，以本文档为准。

不要擅自把产品做成：

- Anki clone；
- Quizlet clone；
- 多 Deck 平台；
- 网络 App；
- AI App。

---

# 57. 推荐测试文件

至少包含：

```text
VocabularyParserTests.swift
ImportAnalyzerTests.swift
SRSSchedulerTests.swift
WeaknessScorerTests.swift
ReviewQueueBuilderTests.swift
BidirectionalReviewTests.swift
ExtraPracticeIsolationTests.swift
StudySessionTests.swift
StatisticsServiceTests.swift
RecentResultsTests.swift
BackupEnvelopeTests.swift
BackupServiceTests.swift
```

可以直接参考 TOEFL Vocab 已有 tests 的组织方式，但测试预期必须改成本文档的业务规则。

# 58. V1 验收场景

## 场景 1：首次导入

粘贴：

```text
apple 苹果
banana 香蕉
ice cream 冰淇淋
```

结果：

```text
3 Words
6 ReviewStates
```

首页出现待学习卡。

---

## 场景 2：重复导入

再次粘贴同样全文。

结果：

```text
新增 0
已有 3
```

原 ReviewState 不发生变化。

---

## 场景 3：增加一个单词

粘贴：

```text
apple 苹果
banana 香蕉
ice cream 冰淇淋
beautiful 美丽的
```

结果：

```text
新增 1
已有 3
```

只创建：

```text
beautiful → 美丽的
美丽的 → beautiful
```

两条新 ReviewState。

---

## 场景 4：英翻中熟练、中翻英不熟练

```text
apple → 苹果
连续答对

苹果 → apple
经常答错
```

一段时间以后：

```text
English → Chinese Level 7
Chinese → English Level 3
```

系统仍频繁测试中文 → 英文。

这就是预期行为。

---

## 场景 5：高等级单词遗忘

```text
Level 8
↓
不认识
```

结果：

```text
Level 4
明天到期
当前轮稍后再次出现
```

当前轮稍后回答“认识”：

```text
仍 Level 4
仍然明天正式复习
```

---

## 场景 6：双方向同时到期

```text
apple → 苹果
苹果 → apple
```

两张不能连续出现。

应尽可能：

```text
apple → 苹果
...
至少约 5 张其他卡
...
苹果 → apple
```

---

## 场景 7：备份

学习数月后导出 JSON。

删除测试数据后恢复。

恢复后：

- Word 数量相同；
- 两方向 Level 相同；
- nextReview 相同；
- 统计相同；
- 历史相同。

---


## 场景 8：Extra Practice 不污染 SRS

正式状态：

```text
because 中 → 英
Level 6
nextReview = 60 天后
```

进入 Extra Practice 连续练习。

结果：

- Extra Practice 事件正常记录；
- Level 仍为 6；
- nextReview 不变；
- 正式首答正确率不受影响；
- 正式 weakness 不受影响。

---

## 场景 9：主队列冻结

开始一轮：

```text
30 张
```

第 1 张答错以后：

- 可以安排该卡稍后 retry；
- 原第 2～30 张 base queue 不重新按 weakness 全量排序。

---

## 场景 10：中断 Session

完成：

```text
8 / 30
```

退出。

结果：

- 8 张回答已保存；
- Session `completed = false`；
- 未答卡不产生事件；
- 下次重新 build due queue。

---

## 场景 11：最近 5 次

同一方向正式首答：

```text
✓ ✓ ✕ ✓ ✕
```

中间穿插 10 次 Extra Practice 和 same-session retry。

Word detail 的最近 5 次仍然只显示：

```text
✓ ✓ ✕ ✓ ✕
```

---

## 场景 12：Backup marker

选择其他 App 的 JSON。

结果：

```text
这不是 WordMemoryCards 备份文件
```

并且：

> 当前数据库完全不变。

---

# 59. V1.1 完成定义 Definition of Done

只有以下全部满足才算 V1.1 完成：

- [ ] iPadOS Deployment Target = 16.0；
- [ ] 能在 iPad 第五代 / iPadOS 16.7.16 安装运行；
- [ ] 已审计 / Fork / 参考 TOEFL Vocab 上游代码；
- [ ] 直接复用上游代码时保留 MIT License 和 attribution；
- [ ] 完全离线；
- [ ] 无账号；
- [ ] 单个添加；
- [ ] 批量 Markdown / 文本粘贴；
- [ ] Import Preview；
- [ ] 自动查重；
- [ ] 重复导入不会破坏历史；
- [ ] 支持 English → Chinese；
- [ ] 支持 Chinese → English；
- [ ] 两方向 SRS 完全独立；
- [ ] 两方向不会紧邻造成答案污染；
- [ ] 认识 / 不认识；
- [ ] same-session retry；
- [ ] 固定日期 SRS；
- [ ] WeaknessScorer；
- [ ] weakness 只使用 scheduled 首答历史；
- [ ] Session 开始后冻结 base queue；
- [ ] deterministic stable ordering；
- [ ] 每轮默认 30；
- [ ] 复习中显示 `current / total`；
- [ ] 复习中显示细进度条；
- [ ] 支持安全退出 / 中断；
- [ ] 已回答内容即时持久化；
- [ ] StudySession 可区分 completed / interrupted；
- [ ] Extra Practice；
- [ ] Extra Practice 至少支持 weakest 20 / 50 / allWeak；
- [ ] Extra Practice 完全不改变 SRS Level / nextReview；
- [ ] Extra Practice 不改变正式 weakness；
- [ ] 使用系统 TTS；
- [ ] 能在真机选择 Zoe（优化）；
- [ ] 能在真机选择语舒；
- [ ] English speech rate 可调；
- [ ] Chinese speech rate 可独立调整；
- [ ] TTS 可试听；
- [ ] 自动朗读；
- [ ] 触觉反馈可开关；
- [ ] 无触觉硬件时 graceful no-op；
- [ ] 词库搜索；
- [ ] 编辑；
- [ ] 删除；
- [ ] 学习统计；
- [ ] direction-level 薄弱卡；
- [ ] 最近 5 次正式首答；
- [ ] 最近 10～12 次 scheduled Session 趋势；
- [ ] JSON 完整备份；
- [ ] Backup app marker；
- [ ] Backup formatVersion；
- [ ] 数据 schemaVersion；
- [ ] 恢复前完整验证；
- [ ] 恢复前显示摘要；
- [ ] JSON 恢复；
- [ ] Core Data 本地持久化；
- [ ] 关键业务单元测试通过；
- [ ] `xcodebuild` 成功；
- [ ] 无依赖 iOS 17+ API；
- [ ] 免费 Personal Team 可签名安装。

# 60. 首选 Fork 基础：TOEFL Vocab

## 60.1 上游仓库

首选：

```text
https://github.com/a1mohamad/toefl-vocabs-ios-app
```

不要只把它当作“看看 UI 的参考项目”。

对于 V1.1：

> **优先把它当作可 Fork 的 SwiftUI / iOS 16 代码骨架。**

其 `project.yml` 已经采用：

```text
deploymentTarget: iOS 16.0
```

但当前：

```text
TARGETED_DEVICE_FAMILY = 1
```

即 iPhone only。

本项目必须改为：

```text
TARGETED_DEVICE_FAMILY = 2
```

并重新设计 iPad 横竖屏布局。

## 60.2 License

TOEFL Vocab：

```text
MIT License
Copyright (c) 2026 Amir Mohammad Askari
```

MIT 允许修改和使用。

如果复制或 substantial reuse：

- 保留 MIT License；
- 保留 copyright notice；
- 可以修改 App 名、Bundle ID 和业务逻辑；
- 本项目的新增代码可以继续采用兼容许可证。

## 60.3 值得直接借鉴的代码

### Audio

```text
Core/Audio/PronunciationService.swift
```

借：

- `AVSpeechSynthesizer` wrapper；
- 长生命周期；
- rate；
- stop / speaking state。

改：

- 单英文 → 英文 + 中文；
- accent enum → actual voice identifier；
- 单 rate → English / Chinese 双 rate。

### Haptics

```text
Core/Audio/Haptics.swift
```

基本可以直接重命名 / 改造使用。

保留 iOS 16 UIKit implementation。

### AdaptiveOrdering

```text
Core/Engine/AdaptiveOrdering.swift
```

借：

- Laplace-smoothed error rate；
- recent mistake bonus；
- consecutive-correct penalty；
- deterministic sort；
- Extra Practice queue 的独立思路。

改：

- VocabItem → direction-level ReviewState / ReviewTask；
- 不再决定“是否到期”；
- weakness 只做 due-card tie ordering 和 Extra Practice；
- 正式 SRS 日期永远由 SRSScheduler 决定。

### StatsAggregator

```text
Core/Engine/StatsAggregator.swift
```

借：

- 纯函数统计；
- weakest list；
- recent sessions；
- aggregate 模式。

改：

- Book / Section → 单一词库；
- main / extra 教材分类 → scheduled / extraPractice mode；
- 单词级 → direction-level + word-level 双层统计。

### Practice

```text
Features/Practice/PracticeView.swift
Features/Practice/PracticeViewModel.swift
Features/Practice/SessionSummaryView.swift
```

借：

- question / revealed / finished 状态机；
- 顶部退出；
- current / total；
- progress bar；
- quit confirmation；
- Session Summary；
- Reduce Motion；
- safe scrolling；
- large tap target。

改：

- “先按认识再揭示答案” → 本项目必须“先翻面，再自评”；
- 单方向 → 双向；
- queue algorithm → 本项目 SRS；
- five-box cycle → 删除；
- Book / Section header → 删除；
- iPhone layout → iPad-first。

### Reports

```text
Features/Reports/ReportsView.swift
```

借：

- weakest drill；
- recent Session chart；
- compact Overview；
- Extra Practice entry。

不需要：

- Book heat grid；
- Main / Extra 教材 split；
- run number。

### Backup

```text
Core/Persistence/ProgressBackup.swift
Features/Settings/SettingsView.swift
```

非常值得直接参考：

- backup envelope；
- app marker；
- format version；
- app version；
- ISO dates；
- prettyPrinted JSON；
- decode before replace；
- restore confirmation；
- fileImporter / fileExporter；
- security-scoped URL。

数据 body 必须替换为本项目 DTO。

### DesignSystem / Router / Tests

可以大量保留架构思路：

```text
DesignSystem/
Navigation/Router.swift
Tests/
```

但不要因为复用方便而保留 Book / Section 业务概念。

## 60.4 建议删除的上游代码

在确认没有依赖后，可以删除：

```text
Resources/VocabData/
Book/
Section/
BookIntroView
SectionIntroView
VocabCatalogLoader 中与教材目录有关的逻辑
Persian / RTL 专属内容（如果不需要）
504 / TOEFL content model
```

不要把原项目自带 TOEFL / 504 词库打包进最终家庭 App。

## 60.5 Core Data 决策

TOEFL Vocab 为 iOS 16 使用 Codable 文件保存 progress。

本项目虽然可以参考其 persistence 思路，但最终继续采用：

```text
Core Data + SQLite
```

原因：

- 用户长期持续加词；
- ReviewEvent 长期积累；
- 双方向 state；
- Session history；
- 查询 weak cards / recent 5 / recent sessions；
- 数据规模比上游固定词库更动态。

因此：

> 不为了“Fork 改动少”而退回一个越来越大的单 JSON progress 文件。

## 60.6 另一个算法参考

```text
https://github.com/open-spaced-repetition/swift-fsrs
```

只作为未来算法研究。

V1.1：

> 不接 FSRS。

继续使用本文档固定等级 SRS。

## 60.7 Fork 的最终原则

Codex 的目标不是：

> 把 TOEFL Vocab 换个名字。

而是：

> 用 TOEFL Vocab 已经验证过的 iOS 16 / SwiftUI / TTS / Haptics / Practice / Reports / Backup 基础设施，重新实现本文档定义的家庭双向 SRS 单词卡产品。

如果上游代码与本文档冲突：

> 本文档优先。

# 61. 最终原则

如果实现中出现取舍，请按照以下顺序：

```text
数据可靠
>
iPadOS 16.7.16 兼容
>
复习逻辑正确
>
儿童操作简单
>
性能
>
界面美观
>
功能数量
```

这个 App 的成功标准不是功能多，也不是尽可能保留上游 TOEFL Vocab 的全部功能，而是：

> 孩子每天打开后不需要学习怎么使用，直接复习；
> 家长只需要维护一份 Markdown 单词总表；
> App 自动决定什么时候、用哪个方向再问一次这个单词；
> 熟词逐渐淡出，真正容易忘记的词不断被重新拉回来。

# 62. 项目实施进度（Codex 持续维护）

> 本节是项目恢复入口。每个阶段完成、关键决策变更、构建/测试结果或阻塞出现时更新。

## 62.1 当前状态

- 最后更新：2026-09-05
- 当前模型：GPT-5.6 Sol，High
- 当前阶段：FSRS-6 调度升级已完成，等待真机验收
- 总体状态：固定 Level 正式排期已替换；旧历史迁移、备份兼容、自动化测试和 Simulator build 均已验证
- 当前阻塞：无功能阻塞

## 62.2 已完成节点

### 2026-09-01 — Phase 0 上游审计完成

- 完整阅读 V1.1 产品与实现规格。
- 确认目标目录初始只有本需求文档，未覆盖任何既有工程。
- 初始化本地 Git `main` 仓库；未创建 remote，未 commit，未 push。
- 从官方仓库临时 clone TOEFL Vocab，审计基线提交：
  `ef329ac9ebe416cc2231155a4cd50efe7d4a3bfb`。
- 审计 MIT `LICENSE`、`NOTICE`、`project.yml`、Audio、Haptics、AdaptiveOrdering、StatsAggregator、Practice、Reports、Settings、Backup、Router 和 Tests。
- 生成 `REUSE_PLAN.md`，明确保留、改造、删除和新增范围。
- 在本项目保留上游 MIT License 与 attribution；不引入上游 TOEFL / 504 词库内容。

### 2026-09-01 — Phase 1 工程骨架完成

- 通过 Homebrew 安装 XcodeGen 2.46.0；它只用于生成工程，不是 App 运行时依赖。
- 创建 `project.yml` 并生成 `WordMemoryCards.xcodeproj`。
- 设置 Bundle ID `com.hutianyi.WordMemoryCards`、iPad-only、deployment target 16.0、横竖屏和自动签名。
- 建立 SwiftUI App 根依赖、`NavigationStack`、首页、设置页和阶段性占位页面。
- 建立 Core Data SQLite 模型：`WordEntity`、`ReviewStateEntity`、`ReviewEventEntity`、`StudySessionEntity`。
- 为 `normalizedEnglish` 添加数据库唯一约束；因 Core Data 模型限制，反向 Word 关系在 XML 层可空，业务写入层必须保证非空。
- 增加持久化模型测试：四实体存在、一个 Word 可拥有两条方向独立状态。

### 2026-09-01 — Phase 2 单词导入与词库管理完成

- 实现英文 Unicode 兼容归一化、大小写/空白/弯引号统一，以及数据库层 `normalizedEnglish` 唯一约束。
- 实现 Markdown / 纯文本词表解析：忽略空行、标题和分隔线，支持项目符号、Tab、短横线、长横线及中英文边界。
- 实现导入预分析：新增、已存在、释义冲突、无法识别四类结果；预览确认前不写数据库。
- 实现单个添加、批量粘贴、冲突不覆盖和单事务导入；每个新词同时创建两个 Level 0 方向状态。
- 实现词库搜索、编辑、重复校验、删除确认；修改词条不重置学习历史。
- 增加 Parser、Import Analyzer 与事务化 Repository 单元测试。

### 2026-09-01 — Phase 3 双向 SRS 与队列完成

- 实现固定 Level 0–9 间隔和本地日历日归一化；认识升级、不认识降级并次日正式复习。
- 实现 direction-level `WeaknessScorer`，只由 scheduled 首答历史驱动。
- 实现正式到期排序、稳定 tie-break、同 Word 双方向防答案污染和 Session base queue 冻结。
- 实现 same-session retry：错误后延后插入、最多两次、重试不再次修改 Level / nextReview。
- 实现 `ReviewRepository` 每次答题单事务即时保存；scheduled、retry、Extra Practice 三类计数严格隔离。
- 增加 SRS、weakness、queue、双方向隔离、retry、extra isolation 与中断 Session 测试。

### 2026-09-01 — Phase 4 复习 UI、TTS 与触觉完成

- 实现 iPad-first 单卡复习界面：大卡片、先翻答案再显示作答按钮、冻结进度条和 retry 提示。
- 实现“认识 / 不认识”即时落库后再前进；完成页区分正式首答与当天重试。
- 实现一张未答直接退出、已有回答二次确认、已答记录保留及 interrupted Session。
- 实现英文/中文独立系统语音、语速和试听；支持自动朗读正面/答案及手动扬声器按钮。
- 为旧 iPad TTS 增加长期 synthesizer、2 秒启动 watchdog、重建与基础 voice fallback、音频服务重置恢复。
- 使用 iOS 16 可用的 UIKit 触觉 API；无触觉硬件时自然 no-op。

### 2026-09-01 — Phase 5 Extra Practice 完成

- 设置页提供最弱 20、最弱 50、全部薄弱卡、全部卡片范围及入口。
- Extra queue 按正式 weakness、较少额外练习次数和稳定 tie-break 排序，并继续防止双方向紧邻。
- Extra Practice 只写独立事件和 Session 计数，不修改 Level、nextReview 或正式 weakness。
- 完成独立 Extra Session Summary，并明确提示正式 SRS 未改变。

### 2026-09-01 — Phase 6 统计完成

- 实现总词、今日到期、双向均 Level >= 7 的熟练词、今日正式首答、今日首答正确率、streak 和累计统计。
- 实现方向级薄弱卡排行榜与 Extra Practice 快捷入口。
- 使用 iOS 16 Swift Charts 显示最近 12 次有正式首答的 scheduled Session 正确率。
- 单词详情按两个方向显示 Level、下次复习、正式认识/不认识及最近 5 次正式首答；排除 retry 和 Extra。

### 2026-09-01 — Phase 7 完整备份与恢复完成

- 实现带 `app` marker、`backupFormatVersion`、`schemaVersion`、App 版本和导出时间的 JSON envelope。
- 导出 Words、ReviewStates、ReviewEvents、StudySessions 和全部 AppSettings；JSON 使用 ISO 8601、pretty printed、sorted keys。
- 恢复前先完整 decode，再校验 App/版本、ID 唯一性、双方向、枚举、计数与关系完整性；坏文件不会写数据库。
- 通过 `fileExporter` / `fileImporter` 和 security-scoped URL 导入；确认前显示备份摘要。
- 覆盖前在 App Application Support 自动写入当前数据安全备份；正式恢复使用单个 Core Data context 事务，失败时 rollback。
- 增加 envelope 拒绝测试与实体/关系 round-trip 恢复测试。

### 2026-09-01 — 真机反馈后的图标与学习记录重置

- 用户提供 `icon.png`（1254×1254、PNG、无 Alpha）；检查构图后确认适合 App Icon。
- 生成 iPhone、iPad 和 App Store 所需的完整 AppIcon 尺寸并加入 `Assets.xcassets`；源图保留不改。
- Xcode Asset Catalog 编译成功，构建产物 Info.plist 已包含 `CFBundleIconName = AppIcon` 和 iPad icon files。
- 设置页新增“清除全部学习记录”：保留 Word，删除 ReviewEvent / StudySession，把两个 ReviewState 方向重置为 Level 0、今天到期、计数归零。
- 重置前自动在 App Application Support 生成 `PreReset` 安全备份；重置使用单个 background context 事务，失败 rollback。
- 新增 `LearningProgressResetServiceTests`，验证单词保留、事件/Session 清空和双方向状态归零。
- 最新真机签名构建、codesign 严格验证、全部测试 target `build-for-testing` 和 `git diff --check` 通过。
- Updated physical install：用户确认后，已通过 Xcode Run 将图标/重置功能更新版覆盖安装并启动；Xcode 显示 App 在已连接 iPad 上运行，未崩溃，安装阶段未删除任何数据。
- Physical feedback：用户确认首次更新后图标未刷新，且“清除全部学习记录”点击无弹窗。
- Reset dialog root cause：设置页同时挂载多组 `confirmationDialog` / `alert`，在 iPadOS 16 上发生弹窗修饰器覆盖；已改为单一 `BackupAlertState` + 单一 `.alert(item:)` 状态机。
- Reset confirmation：修正版明确显示“清除全部学习记录？”二次确认，按钮为“确认清除 / 取消”；新增状态单元测试和 UI 弹窗测试。
- Icon refresh：`CURRENT_PROJECT_VERSION` 从 1 提升到 2，促使 SpringBoard 重新读取 App Icon 元数据。
- Build 2 verification：真机签名构建、全部测试 target `build-for-testing`、codesign、`CFBundleVersion = 2`、`CFBundleIconName = AppIcon` 和 `git diff --check` 全部通过；等待覆盖安装。
- Build 2 physical feedback：用户自行覆盖安装后，学习记录重置与二次确认正常；重启 iPad 后图标显示，但旧源图预制圆角导致四角出现黑边。
- App Icon V2：使用内置图像生成从零制作 `icon-v2.png`（1254×1254、无 Alpha、全幅蓝色背景、无预制圆角/外框/黑角）；用户确认采用。
- Build 3 icon integration：已用 `icon-v2.png` 重建所有 iPhone/iPad/Marketing AppIcon 槽位，原始 `icon.png` 保留；build number 提升到 3。
- Build 3 verification：真机签名构建、codesign、`CFBundleVersion = 3`、包内 iPad/60pt AppIcon 文件和 `git diff --check` 通过；等待覆盖安装。

### 2026-09-01 — 开源发布整理完成

- 公开仓库新增 `README.md`：功能、构建步骤、隐私说明、测试方式和原作者署名均已写明。
- 更新 `LICENSE` 与 `NOTICE`：保留 TOEFL Vocab 原作者 Amir Mohammad Askari 的 MIT 版权声明，明确本项目参考的架构/交互思路，以及未包含上游 TOEFL / 504 词库、截图或出版物内容。
- `REUSE_PLAN.md` 继续作为可审计的复用范围记录。
- 移除 `project.yml` 和重新生成 Xcode 工程中的个人 Apple Team ID；公开 clone 后需由使用者在 Xcode 中选择自己的 Team，必要时改用自己的 Bundle ID。
- 清理需求文档中的本机绝对路径和设备名称，保留产品规格及项目恢复信息。
- 完成源码、文档与 Git 提交范围的敏感信息扫描：未发现 API Key、Token、私钥、密码、网络请求、学习记录或大文件。
- 公开版工程通过 XcodeGen 重新生成；App、逻辑测试与 UI 测试 target 的 `build-for-testing` 通过。
- 在 iPad (A16) / iOS Simulator 26.5 上实际执行 XCTest：31/31 通过（29 个逻辑测试、2 个 UI 冒烟测试）。UI 测试使用串行执行，避免当前 Xcode 并发启动多个 UI test runner 时的间歇性系统终止。
- 已创建公开仓库：<https://github.com/hutianyi/word-memory-cards>；已设为本地 `origin`，首次源码提交与 push 待执行。
- 首次公开提交：`0952430`（`Initial public release`）已于 2026-09-01 推送至 `main`，仓库地址为 <https://github.com/hutianyi/word-memory-cards>。

### 2026-09-05 — FSRS-6 调度升级完成

- 从官方 `open-spaced-repetition/swift-fsrs` 当前源码确认：默认 19 权重是 FSRS-5，必须显式使用 21 权重 `FSRSDefaults.defaultWv6` 才是 FSRS-6。
- XcodeGen `project.yml` 已固定官方依赖到提交 `4fbaf20184d62f82a9f44f343337c61a2c5483e9`，重新生成工程后依赖仍存在；`Package.resolved` 已纳入工程工作区。
- 调度参数：目标保留率 0.92，最大间隔 3650 天，fuzz 关闭，使用 FSRS-6 官方默认权重，不做个人参数训练。
- 库内 short-term steps 关闭：App 已有独立的当天 same-session retry；若保留库默认 1m/10m 学习步骤，新卡 Good 会在 10 分钟后再次到期，与“第二天不强制全部出现”的产品要求冲突。关闭后仍使用 FSRS-6 长期数学调度。
- `认识` 仅映射 `.good`，`不认识` 仅映射 `.again`；旧 Level 字段仅保留数据兼容，不再参与 nextReviewDate 或队列排序。
- Core Data 的每个方向状态新增 `fsrsCardData` 和 `fsrsMigrationVersion`；完整保存官方 `Card` 状态，两个方向互不影响。
- 旧数据首次加载时按时间顺序 replay scheduled 首答：known→Good，unknown→Again；排除 same-session retry 和 Extra Practice。每卡迁移版本标记保证不重复执行，无可用历史时安全初始化为新卡。
- scheduled 首次作答才会更新正式 FSRS Card/due；retry 和 Extra Practice 仅保留事件与 Session 统计，不修改正式调度。
- 备份 schema 升为 2，新备份保存 FSRS Card，仍允许读取 schema 1 旧备份并在恢复后从历史迁移。
- 用户界面仍只显示“认识 / 不认识”，移除 Level 展示；熟练统计改为两方向均有正式复习且下次日期至少在 30 天后。
- 新增/更新自动化覆盖：FSRS-6 配置、Good/Again 映射、动态增长、Again lapse、retry/Extra 隔离、双方向隔离、迁移幂等、未到期过滤、20 词/40 方向次日不全部出现。
- iPad (A16) / iOS Simulator 26.5 串行完整测试通过：33 个单元测试 + 2 个 UI 冒烟测试，共 35/35；`xcodebuild test` 退出码 0。

## 62.3 已确认环境

- Xcode：26.6（Build 17F113）。
- 当前 iOS SDK：26.5。
- 项目最低 deployment target 仍设为 iOS / iPadOS 16.0。
- Apple Git：2.50.1。
- XcodeGen：2.46.0。
- 目标真机：iPad 第五代，iPadOS 16.7.16。

## 62.4 关键决策

- 使用 TOEFL Vocab 作为架构与通用交互参考，不直接保留其教材业务模型。
- 数据层固定为 Core Data + SQLite，不退回上游单一 JSON progress 文件。
- SwiftUI 状态管理使用 iOS 16 兼容的 `ObservableObject` / `@StateObject`，不使用 `@Observable`。
- App 根部持有共享 persistence、settings、speech 和 router；功能级依赖优先显式注入。
- 旧 iPad 的高品质 TTS 可能出现资源加载失败；实现阶段预留 synthesizer 重建、启动 watchdog 和基础 voice fallback，最终以真机为准。
- 不自动创建 GitHub remote，不自动 push，不自动 commit。
- 用户已在 2026-09-01 明确授权：整理公开版并发布到其 GitHub；发布前必须保留上游来源和许可说明。

## 62.5 验证记录

- Phase 0：上游文件与许可证静态审计完成。
- Git：本地仓库初始化成功。
- Build：`iphoneos`、deployment target 16.0、关闭签名的构建成功。
- Build：Phase 0–7 全部源码再次通过 `iphoneos` generic device、关闭签名构建。
- Test build：9 个 XCTest 文件与 App target 的 `build-for-testing` 成功。
- Tests：当前没有 Booted Simulator，因此尚未实际执行；遵循调试流程未自动启动模拟器。
- UI / TTS：尚未在 iPad 第五代真机完成视觉、触控、系统语音和后台/中断验证；Simulator 也不能替代最终语音验收。
- Device discovery：Xcode 已通过 USB 识别已连接 iPad，型号 iPad (5th generation) A1822，iPadOS 16.7.16，状态 available。
- Xcode：已打开生成好的 `WordMemoryCards.xcodeproj`；不需要用户另建工程。
- Signed device build：对已连接 iPad 的只构建检查按预期失败，唯一明确错误为 `Signing for "WordMemoryCards" requires a development team`；未安装 App、未修改 iPad 数据。
- Signing：用户已在 Xcode 选择 Personal Team；Team 同步写入 `project.yml`，避免 XcodeGen 重新生成时丢失。
- Signed device build：选择 Team 后，面向已连接 iPad 的签名构建成功，`codesign --verify --deep --strict` 通过。
- Device install：`devicectl` 对 iPadOS 16.7.16 的旧设备通道显示 unavailable，不能据此安装；Xcode UI 已正确选择连接的 iPad 为 Active Run Destination，状态 Ready。
- Physical XCTest：Xcode 明确报告 logic test target 不支持在 iOS 真机执行，需改在 Simulator 运行；这不是任何测试用例失败。
- Physical install/run：用户确认后通过 Xcode Run 成功安装并启动 App；Xcode 显示 App 在已连接 iPad 上运行，未发生崩溃。
- Physical startup log：仅出现 iPadOS 16 系统语音 catalog 的 `Unable to list voice folder` 提示；App 继续正常运行，实际发音仍需真机点击试听确认。
- UI tests：新增 `WordMemoryCardsUITests` 冒烟测试，使用 `--ui-testing` 内存数据库，不接触正常 App 数据；target 类型已确认为 `com.apple.product-type.bundle.ui-testing`。
- Physical UI XCTest：Xcode 26 对该 iPadOS 16 真机仍报告 `Logic Testing Unavailable`；UI 测试与逻辑测试都保留到 Simulator 执行。
- Latest verification：App 真机签名构建、App + 逻辑测试 + UI 测试的 Simulator `build-for-testing` 均成功。
- Open-source release verification：`xcodebuild test -parallel-testing-enabled NO` 在 iPad (A16) / iOS Simulator 26.5 实际通过 31/31；`git diff --check` 与敏感信息扫描已通过，首次公开提交 `0952430` 已推送到 `origin/main`。
- FSRS-6 verification：重新生成 Xcode 工程后，官方依赖解析为 `4fbaf20`；iPad (A16) / iOS Simulator 26.5 串行通过 33 个单元测试和 2 个 UI 测试，独立 `xcodebuild build` 与 `git diff --check` 均通过。

## 62.6 下一步

1. 在 Xcode 的 Signing & Capabilities 选择用户的 Personal Team，并确认已连接 iPad 处于解锁、信任和 Developer Mode 可用状态。
2. 安装到 iPad 第五代，完成导入、双向复习、retry、退出、统计、Extra Practice、备份 round-trip 的端到端验收。
3. 真机专项验证 Zoe / 语舒、语速切换、连续快速点按、音频路由变化、App 前后台与旧设备 TTS fallback。
4. 用当前真机数据首次启动 FSRS-6 版，确认旧 scheduled 首答迁移后单词、计数和历史保留，并观察次日到期数。
