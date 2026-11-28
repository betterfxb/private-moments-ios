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

终稿的 app 源码一致。常规字号 `e2746ff` 与最大辅助字号 `9d99133` 各通过 12 项日期单测和 1 个双语原生用例。空白日取消保持为空，保存回到原日，计数从零变一且未改变相邻日的记录数。重新启动应用后，重新选择同一日期可再次触发草稿保护，原草稿可继续，已选感受保留。[常规运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46081902337) · [最大字号运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46083464796) · [最大字号空日](evidence/batch-38/46083464796/compact-dark-accessibility-review-calendar/Month-calendar-add-empty-zh-Hans.png) · [最大字号草稿提示](evidence/batch-38/46083464796/compact-dark-accessibility-review-calendar/Month-calendar-draft-conflict-en.png)

## 第 39 批 按标签回顾

「本月标签」与月历相邻，每行显示标签名和该月记录数。点按后复用现有按日分组的记录区。以相同标签跨两个月、同月重复使用及一条记录带多标签为夹具。另用领域测试覆盖历史导入数据中的大小写和空白变体。标签只来自本机记录，使用现有标签归一化和内置标签本地化。

首次先行作业在执行 XCTest 前识别到合成长标签混在应用字符串内。将它改为 Debug 测试启动参数的数据，并补齐 Release 构建禁止该测试字段的检查。该次作业用于定位夹具问题。[本地化审计拦截](https://github.com/betterfxb/private-moments-ios/actions/runs/46085468487)

修正夹具后的先行版本 `318935a` 通过日期单测和第 38 批双语月历回归，随后在「有标签的月份必须提供按标签回顾入口」的断言失败。[原生基线运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46086026599) · [原图](evidence/batch-39/46086026599/compact-light-review-calendar/Month-calendar-tags-missing-en.png)

`b8a3c81` 标准字号通过 13 项日期单测及两个双语原生用例，包括标签跨月、编辑、删除、清除和返回。最大辅助字号通过日期单测及月历补记用例，但原生测试测得长标签行高 543 点，无法完全显示在导航与标签栏之间。实拍显示放大的装饰图标和箭头压缩了文字宽度，导致标题和计数多处断行。候选把辅助字号的标签行宽交给文字，计数使用跟随系统字号的脚注字阶，保留整行触控。[标准字号运行](https://github.com/betterfxb/private-moments-ios/actions/runs/46087425442) · [本月标签原图](evidence/batch-39/46087425442/compact-light-review-calendar/Month-calendar-tag-summary-zh-Hans.png) · [最大字号首轮失败原图](evidence/batch-39/46087429021/compact-dark-accessibility-review-calendar/Content-not-fully-visible.png)

`e59512b` 最大字号英文实拍的同一长标签行缩至 305.5 点，完整标签和一行计数进入同一屏。用例已走通编辑后仍保留当月筛选，再删除最后一条带标签记录。此时界面树显示当月范围和清除入口仍在，空状态位于屏幕下方，测试原先仅等待控件出现。复验改为先滚动到空状态，再核对双语文字、零条结果与月份。[修复原图](evidence/batch-39/46089926089/compact-dark-accessibility-review-calendar/Month-calendar-tag-summary-en.png) · [断言日志](evidence/batch-39/46089926089/compact-dark-accessibility-review-calendar/xctest-extract.txt)

`19ea943` 通过英文长标签、编辑和删除后的空状态，随后在解除筛选时仍停在记录区末尾，无法顺畅找回本月标签。返回动作现在按剩余内容定位到标签区或月历，并同步更新可见与辅助读屏的动作名称。[空结果原图](evidence/batch-39/46092265935/compact-dark-accessibility-review-calendar/Month-calendar-tag-empty-en.png) · [返回位置运行日志](evidence/batch-39/46092265935/compact-dark-accessibility-review-calendar/xctest-extract.txt)

终稿 `c2d3d2e` 的两个紧凑 iPhone 配置各通过 13 项日期单测和 2 个双语原生用例。长标签可以全行显示，删除后可读到空结果，返回时定位到本月标签。月份切换与编辑、删除后的结果均由用例检查。[标准字号](https://github.com/betterfxb/private-moments-ios/actions/runs/46094601218) · [最大辅助字号](https://github.com/betterfxb/private-moments-ios/actions/runs/46094597425) · [最大字号原图](evidence/batch-39/46094597425/compact-dark-accessibility-review-calendar/Month-calendar-tag-summary-en.png)

## 第 40 批 完整流程精修

第 38 批实拍显示，空日处的通用「记录」标题占去辅助字号下的一行，切进表单还会改变底色并显示「昨天」捷径。第 39 批的筛选截图显示，无关的整月统计出现在标签结果上方。此轮在日期或标签作为结果标题时收起月度统计，由对应标题直接承接补记或结果。空结果与清除动作对齐。月历发起的补记复用暖纸色、原生日期控件及普通表单，保留日期编辑，去掉已预选日期场景中的「昨天」捷径。

从一条全新的历史补记开始输入自定义标签，检验键盘存在时保存仍可达、保存回原日、标签数增加、筛选命中和详情返回。在 iPad 的实际系统窗口复用同一路径，在 iOS 17.5 额外跑同一双语流程并保留原生截图。增加用例后给回顾定向步骤留出 45 分钟。

`64a3000` 标准字号通过 13 项单测和 3 个双语原生用例。iPad 系统窗口实测从 630 点缩到 513 点，再扩为 768 点。窄窗录入标签与保存目标均在键盘之外，保存后同日有两条记录，当月新标签只命中一条。[标准 iPhone](https://github.com/betterfxb/private-moments-ios/actions/runs/46097929665) · [iPad 作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46097937230) · [iPad 窄窗键盘](evidence/batch-40/46097937230/ipad-dark-accessibility/Pad-journal-09-calendar-entry-keyboard.png)

同一源码的最大字号先通过新完整流程、日期单测及补记回归。在标签长行回归拍摄时，快速测试手势交替滚过目标，最后诊断帧显示 305.5 点高的行底边比标签栏上缘低 5 点。保留原完整可见断言，用慢速且停稳的原生手势取景，应用源码保持一致。[首轮日志与诊断帧](evidence/batch-40/46097933318/compact-dark-accessibility-review-calendar/xctest-extract.txt)

实际 iOS 17.5 的 iPhone 15 无签名运行通过 6 项单测和 6 个原生用例，包含中英文补记到标签回顾。Release 模拟器产物的最低系统为 iOS 17.0，产物扫描排除了 Debug 测试与诊断钩子。[iOS 17.5 作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46097926273) · [原生键盘](evidence/batch-40/46097926273/ios17/Month-calendar-journey-zh-Hans-03-keyboard.png) · [测试日志](evidence/batch-40/46097926273/ios17/xctest-extract.txt)

对照实拍核对了暖纸色、日期标题、标签结果和空状态，确认缩短后的层级在标准 iPhone 和 iPad 上可操作。iPad 513 点窄窗的最大字号单行输入会随光标横向滚动，测试核对了完整标签值、可点击的录入与保存目标，以及保存后命中的同一条记录。[标准 iPhone 表单](evidence/batch-40/46097929665/compact-light-review-calendar/Month-calendar-journey-zh-Hans-02-form.png) · [标准 iPhone 标签结果](evidence/batch-40/46097929665/compact-light-review-calendar/Month-calendar-journey-zh-Hans-05-results.png) · [iPad 窗口测量](evidence/batch-40/46097937230/ipad-dark-accessibility/window-geometry.txt)

紧凑 iPhone 的核心回归 `7514425` 通过 73 项单测、7 个原生用例和不签名的 Debug／Release 构建，原有的草稿放弃、计时取消、私密保存以及时间线搜索和性能用例均纳入运行。Windows 的 58 项构建工具测试、两个 Bash 入口语法、本地化和 Xcode 工程审计均通过。[核心回归](https://github.com/betterfxb/private-moments-ios/actions/runs/46101152560) · [测试摘要](evidence/batch-40/46101152560/compact-light-core/xctest.json)

最大辅助字号最终复验 `7514425` 通过 13 项单测及 3 个双语原生用例。日期后直接出现补记动作，筛选后的标签用作结果标题。长标签及计数完整可见，删除后的空状态和返回标签均通过实际点按。核对过 `Sources`、`Resources` 与 Xcode 工程目录在 `64a3000` 和 `7514425` 之间的差异，五项通过作业的应用源码来自同一版本。[最大字号作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46101095490) · [最大字号日期与动作](evidence/batch-40/46101095490/compact-dark-accessibility-review-calendar/Month-calendar-journey-zh-Hans-01-day.png) · [最大字号标签结果](evidence/batch-40/46101095490/compact-dark-accessibility-review-calendar/Month-calendar-journey-zh-Hans-05-results.png)

真机 VoiceOver、iPad 外接键盘、真实中文输入法以及签名安装继续按设备清单验证。明文导出、备份口令遗失、应用终止后的计时恢复、私密备注搜索等待产品决定。[待确认事项](DEVICE-AND-RECOVERY-DECISIONS.md)

这三批归档并逐张校验了 97 张原生 PNG，包括基线、诊断和通过后的画面。第 40 批的成功作业贡献 52 张。截图收据记录作业、应用源码、设备、原图尺寸与 SHA-256。
