# Private Moments 第二十二批验收

实施日期为 2026-11-25（Asia/Tokyo）。基线为 `c22dad8`，开发分支为 `feat/native-manual-entry`。

## 任务与验收顺序

| 顺序 | 范围 | 验收行为 |
| --- | --- | --- |
| 1 | 收藏和找回 | 从详情添加或取消收藏。时间线能同时按类型、关键词和收藏状态筛选，重启后能找回。迁移读取原数据库，旧 JSON 合并保留本机收藏，新的收藏状态随手动备份。 |
| 2 | 原生界面精修 | 相同视口核对时间线日期、感受和操作层级，详情检查两行备注、原生编辑与返回入口。浅色和深色使用同一语义色，最大辅助字号下自然换行。 |
| 3 | 相邻周期对照 | 两期均有记录时可以比较所选周／月与前一期的记录数、记录日期数与重复出现的主要感受。点计数或感受跳到原记录列表。 |
| 4 | 本机草稿恢复 | 终止进程后恢复补记或编辑，保留日期、录入的时长、感受、评分、标签与备注。验证主动丢弃、保存后清理和锁定时的可见性边界。 |

## 产品与界面取舍

- 收藏入口位于现有详情导航栏。时间线的「仅看收藏」位于搜索范围旁，最大字号时排在结果数量之后。旧备份未提供收藏值时，合并保留当前收藏，明确的取消状态仍可随备份恢复。SwiftData 从既有 V1 轻量迁移至 V2。手动备份仍使用 JSON 格式版本 1。[Apple 的 SwiftData 版本迁移说明](https://developer.apple.com/videos/play/wwdc2023/10195/?time=520)
- 时间线沿用「沉浸扉页」的暖纸色，由日期分组，感受成为条目标题。时刻、记录类型、时长和评分为辅助信息，收藏看图标，打开记录有独立方向提示。详情先显示日期与感受，将备注移到标签前，只有备注区域使用独立纸色底。顶部原生返回、收藏和编辑动作均可直接操作。375 × 667 点并排对照使用旧版原生截图、代表性设计样张和本批实拍，比较内容层级。旧版示例的记录和筛选状态不同。iPad 将笔记限制在居中的阅读列，标签栏采用系统的顶部布局。[小屏并排对照](evidence/batch-22/diagnostics/reading-comparison-375pt.png) · [iPad 中文详情](evidence/batch-22/45511970568/ipad-light/Reading-note-zh-Hans.png)
- 回顾上的对照默认折叠，保持常用周月翻页、感受和记录入口优先。周期含记录的日期数按本地日历去重。单次出现的感受不作为常见感受，重复出现且并列的感受均展示。所选周期包括当前周或月时，计数以已保存数据为准。
- 同一时间保留一份草稿，补记、已结束会话的回顾及现有记录编辑都使用同一保护目录。继续之前可主动丢弃，原记录只有在明确保存时才改变。首页只显示通用操作，无草稿备注预览。JSON 备份只包含已保存的记录，进行中的计时依旧按既有生命周期处理。

计时恢复另行评估。进行中的会话依赖进程内的单调时钟，自动延续可能把关停期间的时间算进记录。当前只恢复已经进入表单的草稿及其中确定的时长。后续如要恢复计时，需要先确定终止时暂停还是继续，以及系统重启和异常时长如何处理。

## 本地验证

Windows 工具测试 48 项通过。270 个本地化键和 113 个 Xcode 对象审计通过，两份 macOS 验收脚本 Bash 语法检查和 Git 差异检查通过。执行入口为 `python -m unittest discover -s tools`、`node tools/audit-localization.mjs`、`node tools/audit-xcode-project.mjs`、`bash -n scripts/verify-mac.sh`、`bash -n scripts/verify-ios17.sh` 和 `git diff --check`。

## 云端验证

### 基线与首轮回归

- 测试提交 `46d8e55` 在旧应用上命中缺少收藏入口的断言，原有两个回顾用例通过。[基线运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45419094005) · [XCTest 摘录](evidence/batch-22/diagnostics/45419094005-xctest-extract.txt)
- 源码 `c821397` 的首轮完整矩阵未通过。常规小屏的无签名 Debug／Release 构建及单测通过。可复现问题包含收藏用例按列表位置选中了感受不匹配的同一时间记录，回顾用例等待了首页元素，以及最大字号下收藏控件将结果计数挤到标签栏之后。两个配置遇到系统文件选择器缺少可操作的取消控件，系统侧根因尚未单独证明。[首轮矩阵](https://github.com/betterfxb/private-moments-ios/actions/runs/45423165858)

### 中间修订的已通过证据

源码 `4e7b775` 在 iOS 26.2 的 iPhone SE（第三代）浅色常规字号，以及 iPad 浅色常规字号上分别通过 16 项相关单元测试和 5 个中英双语原生 UI 用例。两套各归档 10 张原图。用例从正常界面入口验证收藏重启后可与搜索同时使用、原备注能读回、点周期对照可回到正确记录、进程终止后草稿能继续编辑及主动丢弃。最大字号上的收藏和原有回顾已通过，周期对照的单击展开和编辑草稿的感受控件定位仍需补验。iOS 17.5 中 6 项收藏与草稿单测及原有三个界面用例通过，新对照用例的尺寸检测在浮点舍入处失败。[小屏常规](https://github.com/betterfxb/private-moments-ios/actions/runs/45511957307) · [iPad 常规](https://github.com/betterfxb/private-moments-ios/actions/runs/45511970568) · [最大字号首轮修订](https://github.com/betterfxb/private-moments-ios/actions/runs/45511963837) · [iOS 17.5 首轮修订](https://github.com/betterfxb/private-moments-ios/actions/runs/45511983147)

### 最后复验

- `7125c28` 在 iPhone SE（第三代）、375 × 667 点、iOS 26.2 深色最大辅助字号下通过 16 项单测和全部 5 个双语原生用例，归档 10 张原图。周期对照经过完整触控范围测量并通过一次点按展开。补记草稿与编辑草稿在进程终止后都能继续，原始值、明确保存及丢弃行为通过。详情日期从此前英文实拍的四行缩为两行，辅助功能名称保留完整日期。长备注、扩展的周期数据和低优先级操作沿页面滚动可达。[最大字号功能验收](https://github.com/betterfxb/private-moments-ios/actions/runs/45597952537) · [最大字号详情](evidence/batch-22/45597952537/compact-dark-accessibility/Favorite-detail-en.png) · [最大字号草稿](evidence/batch-22/45597952537/compact-dark-accessibility/Draft-recovery-en.png)
- `7125c28` 在实际 iOS 17.5 iPhone 15 模拟器通过 6 项单测及 4 个 UI 用例，包括新回顾、上一期对照以及原有搜索和补记。无签名 Release 编译最低版本为 17.0，并通过测试钩子排除检查。[iOS 17.5 通过记录](https://github.com/betterfxb/private-moments-ios/actions/runs/45597962115)
- `7125c28` 的独立备份测试先通过 9 项单测，文件选择器取消用例在控件可操作前超时。失败处原生截图和随后层级记录已显示取消操作。`17663c0` 将该步骤改为等待实际取消控件或安全外沿，沿用项目既有 Files 90 秒启动预算。复验通过 9 项相关单测及常规小屏英文系统文件往返，包括导出、取消、合并、替换与重启读回。[备份诊断](https://github.com/betterfxb/private-moments-ios/actions/runs/45597971767) · [诊断截图](evidence/batch-22/45597971767/diagnostics-files/Picker-cancel-late.png) · [备份复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45602723201)
- 最大字号图库曾遇到两种模拟器测试失败。ARM64 作业在获取进程后台断言时超时，Intel 作业在原生日历菜单打开后查询通用弹层超时。`37280b6` 在截图前等待指定日期选项可用，并加入单独的双语搜索入口。此修订以来的生产代码与最大字号核心功能验收一致。[ARM64 诊断](https://github.com/betterfxb/private-moments-ios/actions/runs/45597981269) · [Intel 诊断](https://github.com/betterfxb/private-moments-ios/actions/runs/45602555167)
- 最终 `37280b6` 在 iPhone SE（第三代）、iOS 26.2 深色最大辅助字号上通过双语原生图库与独立双语搜索两个定向用例。两种语言均验证输入时结果计数处于键盘及其附加区域上方，提交会收起键盘并保留查询，匹配记录或无结果说明自动进入可用区域，清除后可继续操作。归档 8 张原图及哈希。最大字号下原生搜索框需横向滚动才能查看较长查询全文。GitHub 将整项作业标为取消，XCTest 步骤、截图上传和结果包上传均记录为成功。[最终云端复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45606358822) · [XCTest 摘录](evidence/batch-22/45606358822/compact-dark-accessibility-gallery/xctest-extract.txt) · [中文匹配界面](evidence/batch-22/45606358822/compact-dark-accessibility-gallery/standalone-Timeline-search-match-submitted-zh-Hans.png) · [英文无结果界面](evidence/batch-22/45606358822/compact-dark-accessibility-gallery/standalone-Timeline-search-submitted-en.png)

本批归档并核验 40 张有指纹收据的原生截图。各条结果均保留实际受测提交及设备。首轮四配置全量作业未通过，后续按用例和配置复验。签名、TestFlight 和真机旁白继续延期。
