# 第 44–46 批 · iPad 旋转与编辑连续性

基线 `3fd6402`。第 43 批在 513 点宽的竖屏窗口验证了长标签输入。两次横竖屏综合作业均在「设置」参照窗口仍为竖向时停止，随后未运行应用的旋转流程。[上批记录](UX-ACCEPTANCE-41-43.md#第-43-批-云端集成回归)

| 批次 | 目标与范围 | 依赖 | 验收标准 |
| --- | --- | --- | --- |
| 44 · 旋转与输入排查 | 对照同一源码的冷启动旋转、系统窗口综合流程与竖屏窄窗，定位旋转失败发生在系统参照、应用窗口还是产品操作 | 已有 iPad 原生 XCTest 和可拖动的模拟器系统窗口 | 记录系统参照和应用窗口的真实几何及失败阶段，复验横竖屏往返和实际窗口拖动。检查键盘焦点、输入内容、添加及保存可达性，保留可核对的原图。 |
| 45 · 编辑时聚焦当前字段 | 清理第 43 批原图中贴近键盘边缘、与标签计数同时出现的备注计数。按现有输入颜色、字阶和表单布局呈现 | 44 的原生窄窗输入路径通过 | 编辑标签时标签计数保持可见，备注计数在编辑备注或收键盘后可见。以标准和最大字号走通标签与备注切换，验证内容、计数和保存。 |
| 46 · 回归与交付 | 用与验收对应的源码执行窄窗、小屏及旧运行时验证，核对证据并更新项目记忆 | 44、45 各自通过 | 云端无签名编译和定向 XCTest 通过，视觉原图及实际结果能追溯到对应运行。明确区分模拟器验证、系统异常和待真机确认事项。 |

苹果将 `XCUIDevice.orientation` 定义为设备物理方向模拟，因此旋转验收还观察真实界面。系统窗口使用「设置」启用 Windowed Apps 和系统拖柄改变宽度。[设备方向接口](https://developer.apple.com/documentation/xcuiautomation/xcuidevice/orientation) · [iPad 窗口操作](https://support.apple.com/en-us/125309)

真机安装、外接键盘、VoiceOver 与真实拼音候选依赖设备。原有的发布与数据策略确认集中记录在[待确认清单](DEVICE-AND-RECOVERY-DECISIONS.md)。

## 第 44 批 旋转与输入复验

同一源码 `3fd6402` 的四项作业均通过。英文与简体中文在独立新模拟器中从冷启动开始，各核对九次应用几何阶段，实际界面在 1032 × 1376 与 1376 × 1032 点间切换。双语用例验证草稿、详情返回、暂停计时与重启读回。[英文冷启动](https://github.com/betterfxb/private-moments-ios/actions/runs/46124323423) · [简体中文冷启动](https://github.com/betterfxb/private-moments-ios/actions/runs/46124323636)

综合作业的「设置」参照与应用窗口均实际往返横竖屏。软件键盘打开时，窗口从 630 点拖至 520 点，最后在详情扩大至 768 点。竖屏独立作业实测从 630 点缩至 513 点并回到 768 点。两次均验证标签内容、回顾与保存。第 43 批预检失败可定位到应用测试前的系统参照窗口。本轮没有复现，触发条件尚未确定。[综合作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46124323716) · [横屏原图](evidence/batch-44/46124323716/ipad-dark-accessibility/Pad-journal-01-landscape-home.png) · [竖屏作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46124323458)

## 第 45 批 编辑时聚焦当前字段

在第 44 批同尺寸原图里，标签计数位于软件键盘工具栏，备注的 `0 / 10,000` 在键盘边缘被切断。沿用原有颜色、字阶和表单布局，把当前字段的计数放进键盘工具栏。收键盘后，计数回到各自字段下方。先在月历的正常补记入口验证计数归属、输入、保存和详情读回。[513 点基线](evidence/batch-44/46124323458/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png)

先行用例 `1fcb250` 在原生 513 点窗口确认失败。标签计数可见时，备注计数仍出现在界面层级。修正复用原生键盘工具栏和同一份备注计数视图，标签和备注各在编辑期间展示自己的计数，收键盘后计数回到表单相应位置。[先行测试](https://github.com/betterfxb/private-moments-ios/actions/runs/46128932102) · [失败现场原图](evidence/batch-45/46128932102/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard-unrelated-note-counter.png)

iPhone SE（第 3 代）标准字号用同一先行源码复现相同断言失败。该作业的四项标签单测和另外两个原生用例通过。[小屏先行作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46128931147) · [日志摘录](evidence/batch-45/46128931147/compact-light-tag-entry/xctest-extract.txt)

修正版 `0d9f598` 首轮 iPad 已通过 513 点下的两个计数状态、保存和月历找回，随后系统拖柄未将详情窗口扩大。该整项作业标为失败，保留当时的实际结果，使用同一源码在新模拟器复验。[首轮作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46130514642) · [首轮备注计数原图](evidence/batch-45/46130514642/ipad-dark-accessibility/Pad-journal-09-note-keyboard.png)

同一源码的小屏 iPhone 标准与最大辅助字号各通过 4 项标签单测和 3 个双语原生用例。标签和备注的计数随编辑状态切换，键盘上的备注计数完整可见，收键盘恢复表单计数，保存后详情读回正确备注。[标准字号](https://github.com/betterfxb/private-moments-ios/actions/runs/46131295917) · [最大辅助字号](https://github.com/betterfxb/private-moments-ios/actions/runs/46130514206) · [最大字号中文原图](evidence/batch-45/46130514206/compact-dark-accessibility-tag-entry/Month-calendar-journey-zh-Hans-note-keyboard.png)

iPad 同一源码复跑通过。系统窗口实测 630 → 513 → 768 点，在 513 点同一表单完成标签与备注输入、保存和回顾，返回详情后完成最后一次放大。原图分别核对工具栏的 `58 / 64` 与 `13 / 10,000`。[iPad 复跑](https://github.com/betterfxb/private-moments-ios/actions/runs/46132240929) · [标签输入](evidence/batch-45/46132240929/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png) · [备注输入](evidence/batch-45/46132240929/ipad-dark-accessibility/Pad-journal-09-note-keyboard.png)

## 第 46 批 集成回归与交付

复用第 45 批通过的应用源码，运行 iPad 横竖屏及窄窗综合回归、小屏最大字号的原生输入图库、常规字号核心回归和实际 iOS 17.5 兼容验证。XCTest 使用独立测试库。

最终应用源码通过 iPad 横竖屏及窄窗综合流程。系统参照与产品进入横屏，再回到竖屏。键盘打开时，窗口缩至 513 点。标签与备注均完成输入、保存和找回，详情重新扩大至 768 点。[综合作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46133662438) · [横屏原图](evidence/batch-46/46133662438/ipad-dark-accessibility/Pad-journal-01-landscape-home.png) · [窄窗原图](evidence/batch-46/46133662438/ipad-dark-accessibility/Pad-journal-09-note-keyboard.png)

最大字号输入图库首轮在英文首页周菜单处失败。失败原图显示菜单已打开，界面只显示周日到周三，层级另含周四、周五及两页滚动条。当天周六还未出现。测试现分别确认一次点按已打开菜单，再在原生菜单内滚动到当天，并实际选择及清除日期。此处仅调整 XCTest。首轮独立双语搜索输入用例通过。[图库首轮](https://github.com/betterfxb/private-moments-ios/actions/runs/46133659866) · [菜单原图](evidence/batch-46/46133659866/compact-dark-accessibility/Week-menu-current-unavailable-en.png)

`4389698` 的最大字号输入图库与独立双语搜索均通过，原生菜单滚动后可选中当天。相同应用源码的核心作业通过 73 项应用单测、7 个原生 UI、无签名 Debug／Release 构建及 Release 测试钩子排除。[输入图库](https://github.com/betterfxb/private-moments-ios/actions/runs/46135223972) · [菜单滚动原图](evidence/batch-46/46135223972/compact-dark-accessibility/Week-menu-en.png) · [核心作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46133662915) · [核心测试收据](evidence/batch-46/46133662915/compact-light-core/xctest.json)

iOS 17.5 首轮通过 6 项单测与另外 5 项原生用例，Release 编译的最低系统为 17.0。月历用例读到的标签只有 `Quiet m`，在验证备注前停止。保持输入原文与严格比对条件，在独立模拟器重新运行旧系统的完整范围。[首轮作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46133661848) · [首轮日志](evidence/batch-46/46133661848/ios17/xctest-extract.txt)

第二轮无签名 Release 通过，Apple 官方 iOS 17.5 Universal 模拟器镜像下载报告停在 99.8%，作业到期时仍未进入 XCTest。为单次镜像下载设 8 分钟上限，主 Xcode 下载挂起时也能使用原有的 Xcode 16.4 备用流程。保留完整的部署目标和 XCTest 断言。[镜像超时作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46140474963) · [下载日志摘录](evidence/batch-46/46140474963/ios17/runtime-download-extract.txt)

同一应用源码 `c01f297` 在 iPhone 15 的实际 iOS 17.5 上通过 6 项单测和 6 个原生用例，包含中英文的标签与备注输入、计数切换、保存与详情读回。无签名 Release 最低部署版本为 17.0，排除了测试钩子。最终作业使用主 Xcode 完成下载，下载成功、错误及超时返回值在本地分别验证。[最终旧系统作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46146034752) · [旧系统备注键盘原图](evidence/batch-46/46146034752/ios17/Month-calendar-journey-zh-Hans-note-keyboard.png) · [测试收据](evidence/batch-46/46146034752/ios17/xctest.json)

### Windows 检查与待确认事项

- `python -X utf8 -m unittest discover -s tools` 的 60 项工具测试通过。`bash -n` 的 `scripts/verify-mac.sh`、`scripts/verify-ios17.sh` 两个入口语法检查通过。
- `node tools/audit-localization.mjs`、`node tools/audit-xcode-project.mjs`、`node tools/audit-release-materials.mjs` 通过。覆盖 311 个本地化键和 113 个 Xcode 工程对象。发布审计仍提示 Bundle ID、发布者信息和审核材料有待确认字段。
- 核对三批 31 张原生 PNG 的 SHA-256 收据和报告相对文件链接，覆盖基线、诊断与终稿。
- 真机旋转、输入法候选、VoiceOver、外接键盘及签名安装保留在设备清单。备份、计时与私密搜索的产品决定沿用现有登记。[待确认事项](DEVICE-AND-RECOVERY-DECISIONS.md)
