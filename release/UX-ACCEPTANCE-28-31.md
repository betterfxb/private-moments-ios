# 第 28 至 31 批实施与验收

| 顺序 | 范围与依赖 | 验收条件 |
| --- | --- | --- |
| 28 快捷记录与自定义标签 | 接续第 27 批首页，复用现有补记、保存、详情编辑和草稿。SwiftData 记录与 JSON 备份结构继续兼容。 | 首页直接进入快捷记录，可明确保存一条记录并到详情补全。取消不留下正式记录。扩展表单的有效修改仍可恢复。验证空白、超长、重复大小写、自定义标签复用及旧记录。 |
| 29 月历与按日回顾 | 接续已存在的月回顾和相邻周期对比。月历使用相同日历区间及记录数据。 | 日期打开当天记录，返回详情后保留筛选。切换月份或清除后恢复所选期间。验证空日与空月、月边界、周起始日、跨月编辑与删除。验证中英文、375 点宽度和最大辅助字号。 |
| 30 备份与计时恢复决策 | 策略选择后才能修改明文备份出口、恢复状态与持久化协议。 | 逐条记录所需决定、建议、旧数据边界和对应的失败测试。 [决策记录](DEVICE-AND-RECOVERY-DECISIONS.md) |
| 31 真机验收 | 需要安装构建与真实 iPhone／iPad。可先完善步骤和截图清单。 | 按真机清单验证认证、锁屏、VoiceOver、真实拼音和 Files，记录设备与系统。 [真机清单](DEVICE-AND-RECOVERY-DECISIONS.md) |

## 实现范围

- 第 28 批 `a715cb6` 增加首页快捷入口。快捷表单选择感受和记录类型，使用页面显示的当前时刻、0 时长和默认 4/5 评分。可先保存并直接进详情，也可在保存前展开完整编辑。修改后的草稿仍使用现有恢复入口，恢复后展开完整表单。标签在保存的记录中复用，首尾空白和大小写变体合并，旧数据保留原拼法。每条记录最多 20 个标签，单个标签最多 64 字符。
- 第 29 批 `c1fcf76` 在月回顾内显示按地区周起始日排列的网格。日期有记录时显示标记和记录数。辅助字号用可滚动日期列表，保持日期、计数和触控区域完整。所选日期复用回顾的记录列表与详情，编辑、删除后从当前库存重新计算。现有相邻月比较保留。
- 第 30 批完成待确认决策清单。加密文件格式及跨进程恢复取决于该清单中的策略选择。第 31 批补齐真机组合场景和原图收集条件，进入真机执行依赖可安装构建与设备。[待确认清单](DEVICE-AND-RECOVERY-DECISIONS.md)

## 验证

Windows 工具测试 55 项通过，Bash 脚本语法、本地化、Xcode 工程和 Git 差异检查通过。Mac 原生执行结果另记于下。测试环境使用合成日记和每次独立的数据目录。

第 28 批源码 `a715cb6` 在 iPhone SE（第三代）浅色常规字号通过 14 项单测和 4 项界面用例。双语快记用例验证取消不创建记录、保存后直接进详情、补标签、忽略大小写重新选中既有标签、终止进程后恢复带标签的草稿并保存两条独立记录。[快记录入原图](evidence/batch-28-29/45822773008/compact-light/Quick-record-zh-Hans.png) · [标签原图](evidence/batch-28-29/45822773008/compact-light/Quick-record-tag-zh-Hans.png) · [XCTest](evidence/batch-28-29/45822773008/compact-light/xctest-extract.txt)

同一源码的深色最大字号输入中，`Weekend` 已正确进入文本框，但纵向排列的「添加标签」按钮与键盘工具栏重叠。将添加动作与输入框同排后，普通字号复验仍测得按钮边界与工具栏有 3 点重叠。最终在输入期间提供独立的键盘工具栏「添加标签」动作，并保留表单按钮和键盘提交。新增带键盘的原图及几何断言，要求该按钮有完整的 44 点操作区域且不进入按键区，之后实际点按验证标签已选中。[最大字号首轮](https://github.com/betterfxb/private-moments-ios/actions/runs/45822773105) · [普通字号复现](https://github.com/betterfxb/private-moments-ios/actions/runs/45830384605)

第 29 批常规小屏首轮在编译阶段发现月度精选仍引用旧的标题属性。已让精选标题和无障碍标签复用同一个本地化标题值，与按日记录标题使用同一接口。[失败日志所在运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45823392525)

修正后的 `b84dbdc` 在 iOS 26.2 浅色常规字号复验通过 15 项单测和 5 项原生界面用例。月历用例逐语言验证当天两条记录、详情返回保留日期、删除后计数减少、空日提示和切到空月份。单测同时覆盖不同周起始日、夏令时、月界及空月。[月历原图](evidence/batch-28-29/45825750892/compact-light-journal-features/Month-calendar-zh-Hans.png) · [空日原图](evidence/batch-28-29/45825750892/compact-light-journal-features/Month-calendar-empty-day-en.png) · [XCTest](evidence/batch-28-29/45825750892/compact-light-journal-features/xctest-extract.txt)

同一源码的深色最大字号月历双语用例通过，日期以独立可点行排版，图中日期与计数完整，空日可直接返回月历。这一作业的 15 项单测和其余原生功能用例通过，旧版快捷标签测试仍复现键盘遮挡。后续各字号均复验。[最大字号日期列表](evidence/batch-28-29/45825738892/compact-dark-accessibility-journal-features/Month-calendar-zh-Hans.png) · [XCTest](evidence/batch-28-29/45825738892/compact-dark-accessibility-journal-features/xctest-extract.txt)

`b84dbdc` 的核心回归通过 71 项单测及 7 项原生界面用例，无签名 Debug 和 Release 均构建成功，Release 钩子排除检查通过。相同源码实际在 iOS 17.5 通过 6 项单测、4 项界面用例及该系统的 Release 钩子检查。这两组未包含后续自定义标签键盘工具栏的专项，最新功能证据另列。[核心回归](evidence/batch-28-29/45825752377/compact-light-core/xctest-extract.txt) · [iOS 17.5](evidence/batch-28-29/45826233371/ios17/xctest-extract.txt)

键盘工具栏最终源码 `c01d422` 的浅色常规字号通过 15 项单测和 5 项原生用例。两种语言实际从键盘工具栏提交新标签，另用键盘提交大小写变体，随后重启恢复带标签的草稿。归档 10 张原图，含型号相同的键盘和月历。[中文键盘原图](evidence/batch-28-29/45835040434/compact-light/Quick-record-tag-typing-zh-Hans.png) · [XCTest](evidence/batch-28-29/45835040434/compact-light/xctest-extract.txt)

同一源码的深色最大辅助字号也通过 15 项单测和 5 项双语原生用例。键盘上的「添加标签」在两种语言均有完整触控区并可直接点按。月历的大字日期列表、返回后保留选择、删除后重新计数和空日提示通过。该配置也归档 10 张原图。标签输入使用合成词 `Weekend`，真实拼音候选、VoiceOver、认证及 Files 真机验证按第 31 批清单开展。[最大字号键盘原图](evidence/batch-28-29/45835041631/compact-dark-accessibility/Quick-record-tag-typing-zh-Hans.png) · [日期列表原图](evidence/batch-28-29/45835041631/compact-dark-accessibility/Month-calendar-zh-Hans.png) · [XCTest](evidence/batch-28-29/45835041631/compact-dark-accessibility/xctest-extract.txt)
