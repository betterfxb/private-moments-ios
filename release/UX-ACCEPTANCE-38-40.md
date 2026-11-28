# 第 38–40 批 · 从月历补记到按标签回顾

以 `93b9a4c` 为起点，依次实现并验证下列流程。用合成日记进行原生模拟器测试，截图保留对应运行和源码版本。

| 批次 | 目标与范围 | 依赖 | 验收 |
| --- | --- | --- | --- |
| 38 · 月历补记 | 日期记录区提供补记入口，复用完整记录表单与草稿保护 | 现有月历、完整补记和草稿恢复 | 有记录和空白的过去日期均可补记。默认带入所选日期，取消不新增，保存回原日并更新计数。已有草稿时保留内容。 |
| 39 · 按标签回顾 | 月回顾列出使用过的标签与记录数，点标签可看当月记录 | 38 批完成，现有标签归一化及按日分组 | 合并等价标签，同一记录只计一次。切换月份、编辑、删除后重新计算。详情返回保留月份和标签，筛选可清除。 |
| 40 · 完整流程精修 | 连贯走通月历补记、录入标签、按标签回顾与返回，复核页面层级、空状态与键盘操作 | 38、39 批均完成 | 原生测试覆盖紧凑 iPhone 的中英文、标准与最大辅助字号，iPad 窗口键盘，以及 iOS 17.5 兼容流程。按实际截图复核跳转位置、录入时保存入口和长标签换行。 |

真实中文输入法、VoiceOver、iPad 外接键盘和安装签名，连同备份、计时及私密备注搜索的产品决定，见 [真机验收与恢复方案](DEVICE-AND-RECOVERY-DECISIONS.md)。

先对照既有空日实拍。标准字号还有位置显示当前日期与补记动作，最大辅助字号下通用「记录」标题、日期和回月历链接已占去大部分屏幕。新入口沿用暖纸面和日记筛选的强调色，允许换行。第 40 批验收时检查具体日期和主动作之间的距离，以及回月历操作的权重。参照 [标准字号](evidence/batch-36/45998876261/compact-light-review-calendar/Month-calendar-empty-day-zh-Hans.png) 与 [最大辅助字号](evidence/batch-36/46000820677/compact-dark-accessibility-review-calendar/Month-calendar-empty-day-zh-Hans.png)。

## 第 38 批 月历补记

先行版本 `7904a03` 在紧凑 iPhone 通过 12 项日期单测。原生用例走过选择日期、删除、检查计数和进入空白日期，随后在「空日必须提供补记入口」断言失败。[运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46078305006) · [原生截图](evidence/batch-38/46078305006/compact-light-review-calendar/Month-calendar-add-missing-en.png) · [日志](evidence/batch-38/46078305006/compact-light-review-calendar/xctest-extract.txt)

补记支持今天和过去的日期，与完整记录表单的日期范围一致。保存或取消返回原先选中的日期。表单允许用户改日期和时间，日历按最终保存日期计数。新记录入口沿用草稿冲突提示。应用重启后仍从「今天」恢复保存在设备上的草稿。

首轮常规字号通过 12 项日期单测及 1 个双语原生用例，归档空日动作、带入日期的表单及保存返回三组画面。[常规字号运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46080057135) · [补记表单原图](evidence/batch-38/46080057135/compact-light-review-calendar/Month-calendar-add-form-zh-Hans.png)

首轮最大辅助字号能取消空表单、保存并在原日看到新增记录。英文草稿提示的辅助树显示「取消」位于屏幕高度之外，实拍同时显示正文和按钮占去多屏。缩短标题下的操作标签，删除与三个操作重复的正文。在同一用例中要求「取消」按钮完整可见且点击一次后关闭提示，原草稿仍可恢复。[首轮最大字号](https://github.com/betterfxb/private-moments-ios/actions/runs/46080062351) · [提示实拍](evidence/batch-38/46080062351/compact-dark-accessibility-review-calendar/Control-unreachable.png)

修复版最大字号原图确认三个操作同时可见。XCTest 实际点击取消后返回当日并成功打开恢复表单，随后在首屏直接查询滚动区下方尚未呈现的感受选项而失败。复验保留对所选感受的断言，先正常滚动到该控件再检查。[修复版提示](evidence/batch-38/46081896957/compact-dark-accessibility-review-calendar/Month-calendar-draft-conflict-en.png) · [运行与断言位置](https://github.com/betterfxb/private-moments-ios/actions/runs/46081896957)

终稿的 app 源码一致。常规字号 `e2746ff` 与最大辅助字号 `9d99133` 各通过 12 项日期单测和 1 个双语原生用例。空白日取消保持为空，保存回到原日，计数从零变一且未改变相邻日的记录数。窗口重新打开后，草稿保护提示保持同一日期，原草稿可继续，已选感受保留。[常规运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46081902337) · [最大字号运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46083464796) · [最大字号空日](evidence/batch-38/46083464796/compact-dark-accessibility-review-calendar/Month-calendar-add-empty-zh-Hans.png) · [最大字号草稿提示](evidence/batch-38/46083464796/compact-dark-accessibility-review-calendar/Month-calendar-draft-conflict-en.png)

## 第 39 批 按标签回顾

「本月标签」与月历相邻，每行显示标签名和该月记录数。点按后复用现有按日分组的记录区。以相同标签跨两个月、同月重复使用及一条记录带多标签为夹具。另用领域测试覆盖历史导入数据中的大小写和空白变体。标签只来自本机记录，使用现有标签归一化和内置标签本地化。

首次先行作业在执行 XCTest 前识别到合成长标签混在应用字符串内。将它改为 Debug 测试启动参数的数据，并补齐 Release 构建禁止该测试字段的检查。该次作业用于定位夹具问题。[本地化审计拦截](https://github.com/betterfxb/private-moments-ios/actions/runs/46085468487)

修正夹具后的先行版本 `318935a` 通过日期单测和第 38 批双语月历回归，随后在「有标签的月份必须提供按标签回顾入口」的断言失败。[原生基线运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46086026599) · [原图](evidence/batch-39/46086026599/compact-light-review-calendar/Month-calendar-tags-missing-en.png)

`b8a3c81` 标准字号通过 13 项日期单测及两个双语原生用例，包括标签跨月、编辑、删除、清除和返回。最大辅助字号通过日期单测及月历补记用例，但原生测试测得长标签行高 543 点，无法完全显示在导航与标签栏之间。实拍显示放大的装饰图标和箭头压缩了文字宽度，导致标题和计数多处断行。候选把辅助字号的标签行宽交给文字，计数使用跟随系统字号的脚注字阶，保留整行触控。[标准字号运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46087425442) · [本月标签原图](evidence/batch-39/46087425442/compact-light-review-calendar/Month-calendar-tag-summary-zh-Hans.png) · [最大字号首轮失败原图](evidence/batch-39/46087429021/compact-dark-accessibility-review-calendar/Content-not-fully-visible.png)
`e59512b` 最大字号英文实拍的同一长标签行缩至 305.5 点，完整标签和一行计数进入同一屏。用例已走通编辑后仍保留当月筛选，再删除最后一条带标签记录。此时界面树显示当月范围和清除入口仍在，空状态位于屏幕下方，测试原先仅等待控件出现。复验改为先滚动到空状态，再核对双语文字、零条结果与月份。[修复原图](evidence/batch-39/46089926089/compact-dark-accessibility-review-calendar/Month-calendar-tag-summary-en.png) · [断言日志](evidence/batch-39/46089926089/compact-dark-accessibility-review-calendar/xctest-extract.txt)
`19ea943` 通过英文长标签、编辑和删除后的空状态，随后在解除筛选时仍停在记录区末尾，无法顺畅找回本月标签。返回动作现在按剩余内容定位到标签区或月历，并同步更新可见与辅助读屏的动作名称。[空结果原图](evidence/batch-39/46092265935/compact-dark-accessibility-review-calendar/Month-calendar-tag-empty-en.png) · [返回位置运行日志](evidence/batch-39/46092265935/compact-dark-accessibility-review-calendar/xctest-extract.txt)
