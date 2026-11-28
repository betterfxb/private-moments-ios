# 第 41–43 批 · 长标签录入与恢复

从 `4212485` 开始。第 40 批的 iPad 513 点窄窗原生截图显示，大字号下单行标签输入滚到了文字末尾，开头需要横向移动才能读到。[窄窗基线原图](evidence/batch-40/46097937230/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png)

| 批次 | 目标与范围 | 依赖 | 验收条件 |
| --- | --- | --- | --- |
| 41 · 长标签输入 | 在现有标签区提供全宽且可换行的原生编辑控件，保留键盘工具栏的添加入口 | 第 40 批的统一表单、标签验证及窄窗测试 | 紧凑 iPhone 最大辅助字号及 iPad 原生窄窗下，真实长标签可换行，输入值完整，键盘不遮挡添加标签及保存。原生截图核对实际断行。 |
| 42 · 超限纠正 | 就地显示标签长度，提示现有上限，超限时保留原输入和编辑焦点 | 41 的输入控件通过验收，复用现有 64 字符与编码长度规则 | 65 个字符无法添加，内容和键盘仍在，可以修正后添加。64 个字符的合法标签可保存并找回。英文和简体中文均可识别错误与修正结果。 |
| 43 · 集成回归 | 从月历补记和详情补标签两条入口验证新编辑器，归档原图并更新项目记忆 | 41、42 分别完成 | 云端覆盖小屏 iPhone 标准及最大字号、iPad 窄窗和实际 iOS 17.5，运行适用的本地审计。验证详情找回、取消、草稿恢复及既有短标签操作。 |

标签控件沿用日记的字阶、颜色和触控尺寸。长标签使用全宽输入与随字号换行，添加入口紧邻输入且可从键盘工具栏触达。真机 VoiceOver、中文输入法、外接键盘及签名验收等安排，以及备份、搜索与计时的产品选择，见[待确认清单](DEVICE-AND-RECOVERY-DECISIONS.md)。

## 第 41 批 长标签输入

首轮 iPad 作业在系统参照应用旋转检查时停止，未进入标签字段。增加紧凑 iPhone 的定向标签验收，同时在新 iPad 模拟器上重跑基线。[首轮系统参照作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46105099325)

`34c2500` 在两个配置上均接受完整测试文本，但输入框高度没有随内容增加，先行原生断言按预期失败。紧凑 iPhone 的四项标签单测和已有快捷记录用例通过。[iPhone 原生基线](evidence/batch-41/46106437512/compact-dark-accessibility-tag-entry/Month-calendar-journey-en-03-keyboard-single-line.png) · [iPad 原生基线](evidence/batch-41/46106458996/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard-single-line.png)

使用原生纵向输入框，内容逐行扩展到四行，超出时在输入框内纵向滚动。添加按钮放在输入下方，键盘工具栏也保留添加入口。两处复用同一标签验证和提交操作。[Apple 原生输入行数说明](https://developer.apple.com/documentation/swiftui/view/linelimit%28_%3A%29)

首轮换行版本 `0773fec` 的小屏标准字号和 iPad 窄窗测试通过。人工查看原图时发现，大字号下键盘工具栏覆盖部分输入行。小屏最大字号任务还在回顾页的长标签按钮定位处失败。第二轮在开始编辑、可见高度变化与输入换行时把字段移到可见区域，并检查字段整体位于导航栏与键盘工具栏之间。回顾页测试沿用第 40 批的慢速拖动验证超高标签按钮。[小屏标准字号任务](https://github.com/betterfxb/private-moments-ios/actions/runs/46108123370) · [小屏遮挡原图](evidence/batch-41/46108116351/compact-dark-accessibility-tag-entry/Month-calendar-journey-en-03-keyboard.png) · [iPad 遮挡原图](evidence/batch-41/46108119990/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png)

第二轮 `edc562e` 的 iPhone SE（第 3 代）标准字号通过四项标签单测与两个双语用例。原图可见两行文字、插入点和两个添加入口。首个 iPad 运行中，系统设置窗口保持 1032 × 1376 点，因参照应用未转成横向而结束。它未进入产品流程，已在新模拟器用同一源码重跑。[小屏英文](evidence/batch-41/46109911610/compact-light-tag-entry/Month-calendar-journey-en-03-keyboard.png) · [小屏简体中文](evidence/batch-41/46109911610/compact-light-tag-entry/Month-calendar-journey-zh-Hans-03-keyboard.png) · [iPad 参照失败记录](https://github.com/betterfxb/private-moments-ios/actions/runs/46109908887)

同一源码在小屏最大辅助字号通过四项标签单测和两个双语用例。编辑器显示靠近光标的完整四行，开头可在输入区内纵向滚动查看；保存后的月标签回顾显示完整内容。iPad Pro 13 英寸（M5）同一源码从 630 点拖到 520 点，原生用例通过。输入长标签的四行全文、键盘添加、保存和回顾均经原图检查。[最大字号原图](evidence/batch-41/46109912183/compact-dark-accessibility-tag-entry/Month-calendar-journey-en-03-keyboard.png) · [iPad 520 点原图](evidence/batch-41/46110967771/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png) · [窄窗按标签找回](evidence/batch-41/46110967771/ipad-dark-accessibility/Pad-journal-10-narrow-month-tag.png)

## 第 42 批 超限纠正

先在详情补标签入口增加原生回归，实际输入 65 字符并点击键盘添加。验证上限提示、焦点保留、用软件键盘删去一个字后重新提交，以及 64 字符回到详情后的读回。保留现有的字符和编码长度校验。

基线 `05b8ef4` 输入完整的 65 字符后，先行断言未找到超限反馈。四项标签单测及两项既有 UI 用例通过。修正使显式提交失败保留焦点，后续实际编辑才清除错误。输入时的计数与键盘添加同处，收键盘后放回输入旁，超限用数字和颜色提示。[原生失败记录](https://github.com/betterfxb/private-moments-ios/actions/runs/46112348233)

`86951ec` 的两种字号均通过四项标签单测与三个双语 UI 用例。原图仍显示工具栏数字被换成两行，小屏最大字号的完整错误还被键盘部分盖住。后续把计数固定在一行，最大辅助字号编辑时把简短的超限提示移到同一行，使用户可继续看到光标，辅助功能值保留完整错误。[首轮最大字号超限原图](evidence/batch-42/46114291448/compact-dark-accessibility-tag-entry/Month-calendar-tag-limit-en-oversized.png)

终稿 `56a4e15` 两种字号各通过四项标签单测和三个双语原生用例。标准字号的完整提示位于输入下方，最大字号的短提示及计数同一行且与输入区分开。分别验证了键盘不退出、65 字符原文保留、65 字符未被添加、删去一个字符后提示清除，以及 64 字符保存后从详情完整读回。[标准字号原图](evidence/batch-42/46116216501/compact-light-tag-entry/Month-calendar-tag-limit-en-oversized.png) · [最大字号英文原图](evidence/batch-42/46116216429/compact-dark-accessibility-tag-entry/Month-calendar-tag-limit-en-oversized.png) · [最大字号简体中文原图](evidence/batch-42/46116216429/compact-dark-accessibility-tag-entry/Month-calendar-tag-limit-zh-Hans-oversized.png) · [修正后原图](evidence/batch-42/46116216429/compact-dark-accessibility-tag-entry/Month-calendar-tag-limit-zh-Hans-corrected.png)

## 第 43 批 云端集成回归

应用源码沿用第 42 批终稿。双语标签回路增加从详情编辑取消后，重新进入确认原有记录未受到影响的断言。新用例归入常规日记功能分组，定向标签验收仍保留。随后运行 iPhone 双语标签测试、iPad 系统窄窗、实际 iOS 17.5 和核心构建回归。

首轮 iPad 集成作业的系统旋转预检再次停止。设备报告横向时，独立的设置窗口仍为 1032 × 1376 点。该次未执行标签流程，用同一源码在新模拟器复跑。[首轮 iPad 作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46118378593) · [测试日志摘录](evidence/batch-43/46118378593/ipad-dark-accessibility/xctest-extract.txt)

第二轮同样停在横竖屏参照。增加独立竖屏窄窗作业，从「今天」快记进入详情补标签，复用同一套实际窗口拖动、软件键盘、时间线筛选和月历长标签断言。横竖屏综合用例仍执行原有预检与断言，竖屏作业覆盖本次窄窗验收。[第二轮 iPad 作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46119414008) · [第二轮日志](evidence/batch-43/46119414008/ipad-dark-accessibility/xctest-extract.txt)

`02f8b3d` 的 iPhone SE（第 3 代）标准和最大辅助字号各通过 4 项标签单测与 3 个双语用例。详情编辑选择标签后取消，原记录没有被写入该标签，重新打开仍可添加。回归也验证月历长标签找回、短标签去重、键盘确认和跨启动恢复已添加的草稿标签。[iPhone 标准字号作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46118379695) · [最大字号作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46118379567) · [取消后的详情原图](evidence/batch-43/46118379695/compact-light-tag-entry/Month-calendar-tag-limit-zh-Hans-discarded.png)

同一源码通过 iPhone SE（第 3 代）核心回归，包含 73 项应用单测、7 个原生 UI 用例、无签名 Debug 与 Release 构建，以及 Release 测试钩子排除。[核心回归](https://github.com/betterfxb/private-moments-ios/actions/runs/46118379219) · [核心测试摘要](evidence/batch-43/46118379219/compact-light-core/xctest.json)

`02f8b3d` 在 iPhone 15 的实际 iOS 17.5 上通过 6 项单测和 6 个原生用例。双语月历补记能录入、换行、保存并再次找回长标签。无签名 Release 最低系统实测为 17.0，测试和时间线追踪钩子排除。旧系统的迁移单测日志记录一条 SQLite 临时库文件仍在使用时被移除的警告，该用例的迁移、回读与备份断言均通过。[iOS 17.5 作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46118375368) · [旧系统中文原图](evidence/batch-43/46118375368/ios17/Month-calendar-journey-zh-Hans-03-keyboard.png) · [旧系统测试日志](evidence/batch-43/46118375368/ios17/xctest-extract.txt)

同一应用源码的独立竖屏作业 `70bbc55` 通过。iPad Pro 13 英寸（M5）最大辅助字号下，系统拖柄将窗口从 1032 点缩至 630 点，键盘打开时再缩到 513 点，详情打开后扩大到 768 点。513 点原图中，58 字符的长标签四行完整，添加、字符计数和保存均可见。时间线筛选、月历找回及恢复窗口后的详情保留已通过。横竖屏综合预检的间歇性异常继续记录，窄窗验收采用这次竖屏实测。[竖屏作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46120906952) · [513 点键盘原图](evidence/batch-43/46120906952/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png) · [按标签找回](evidence/batch-43/46120906952/ipad-dark-accessibility/Pad-journal-10-narrow-month-tag.png) · [原生测试日志](evidence/batch-43/46120906952/ipad-dark-accessibility/xctest-extract.txt)

## 本地验证与待确认事项

- Windows 执行 `python -X utf8 -m unittest discover -s tools`，60 项通过。`bash -n` 检查 `scripts/verify-mac.sh` 和 `scripts/verify-ios17.sh` 通过。
- `node tools/audit-localization.mjs`、`node tools/audit-xcode-project.mjs` 和 `node tools/audit-release-materials.mjs` 通过。本地化目录 311 键，Xcode 工程 113 对象。现有发布占位告警涉及 Bundle ID、隐私政策发布者信息及审核联系资料。
- 复核三批归档的 48 张原生 PNG 与 SHA-256 收据，其中包含基线、诊断与最终状态。第 43 批五项通过的原生作业收据和报告中的相对文件链接均已核对。
- 真机待测项目包括 VoiceOver 朗读与焦点顺序、系统中文拼音候选、外接键盘和签名安装。签名、加密备份、系统终止后的计时恢复、私密备注搜索均按[待确认清单](DEVICE-AND-RECOVERY-DECISIONS.md)处理。
