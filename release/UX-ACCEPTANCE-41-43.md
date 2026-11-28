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
