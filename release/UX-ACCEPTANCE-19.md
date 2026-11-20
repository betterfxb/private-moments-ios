# Private Moments 第十九批验收

2026-11-20 至 2026-11-21，Asia/Tokyo。对象为 SwiftUI 原生 iOS／iPadOS 应用。原生验证由 GitHub Actions 的 macOS、Xcode 26.2 和 iOS／iPadOS 26.2 模拟器执行。测试使用独立的本机合成记录。

本批四项均已完成。最终受测源码 `8e526c8372374c13400ec26426e94dc6a8786e1e` 的四个模拟器配置均通过。54 项应用单元、20 次 UI 用例、无签名 Debug／Release 构建和英文原生 Files 保存与恢复有独立证据。 [最终四配置](https://github.com/betterfxb/private-moments-ios/actions/runs/44760783402) · [源码绑定与截图收据](evidence/batch-19/44760783402/verification.json)

## 执行顺序

| 顺序 | 目标和依赖 | 验收条件 |
| --- | --- | --- |
| 1 | 验证第十八批补录流程在 iPad 最大字号、窗口化和软件键盘同时出现时能继续 | 使用系统真实窗口拖柄。保留多行草稿，保存按钮不被遮挡，能在详情读回相同内容。 |
| 2 | 延续 1,000 条合成记录的性能基线 | 首先测应用内过滤、分组和真实滚动相位。消除重复过滤后，同工作负载复测唯一命中、结果位置变化及编辑、删除后的结果。 |
| 3 | 首页新增原生双语本周回顾 | 依据设备本地日历和已保存记录。展示日期、计数、感受分布和真实记录，覆盖空态、单条、跨年和夏令时。视图与操作分别验收。 |
| 4 | 用完成前述验收的同一源码做四配置回归 | 执行应用单元、UI、无签名 Debug／Release 和实际英文 Files 保存、打开与恢复。记录重跑、证据和剩余限制。 |

## 1 · iPad 有键盘时缩窄窗口

在 iPad Pro 13 英寸（M5）深色最大字号的模拟器上，从 1032 × 1376 点全窗口进入 630 × 1023 点系统窗口。录入两行备注后，软件键盘盖住右下侧，测试从未遮挡的右上角把窗口缩到 513 × 1023 点。键盘在缩窄前后都在，完整备注和顶部保存入口可见。测试直接点按至少 44 × 44 点的保存命中区，再从时间线读回逐字相同的两行。五张原始图和对应界面层级已保留。此处实际操作发生在 iPadOS 模拟器的 Windowed Apps。 [运行 44729533351](https://github.com/betterfxb/private-moments-ios/actions/runs/44729533351) · [证据收据](evidence/batch-19/44729533351/verification.json) · [缩窄后的键盘画面](evidence/batch-19/44729533351/ipad-dark-accessibility/Window-resize-keyboard-narrow.png)

第一轮在系统设置里搜索 Multitasking 得到 No Results，未到应用。测试改为先从系统设置侧栏定位，再保留搜索作为回退。定向验收的应用源码与此前一致。 [首次失败 44727539084](https://github.com/betterfxb/private-moments-ios/actions/runs/44727539084) · [实际日志](evidence/batch-19/44727539084/native-xctest.txt)

## 2 · 时间线 1,000 条记录的查询准备

在相同小屏浅色配置各启动三次，通过真实滑动改变可见行，用软件键盘输入同一个 15 字符合成标签，三次均得到唯一结果。每次渲染的结果计数、空态判断和日期分组共用一个筛选后的列表。时间线保持日期、类型、感受和标签的查询规则，编辑感受后可以按新词找到记录，按旧词无结果。删除后同一查询返回零条。

| 指标 | 优化前中位数 | 优化后中位数 |
| --- | ---: | ---: |
| 准备一次完整查询结果所执行的过滤 | 3 次 | 1 次 |
| 应用内过滤与分组合计，完整查询 | 22.387 ms | 9.960 ms |
| 应用内首次真实滚动从交互开始到停止，含系统减速 | 2479.358 ms | 2531.592 ms |
| XCTest 从实际输入到唯一匹配，含事件驱动及轮询 | 2.611 s | 3.184 s |

应用内准备的三次实测中位数下降约 55%。滚动停止和端到端输入耗时在这两轮小样本里没有变快，保留全部样本范围。日志只记录操作阶段、计时、条数和查询长度，通过 Debug 的隔离测试库启用。首次基线因为测试用向上手势寻找列表顶部搜索框，只有滚动样本，剔除该次无效查询数据。 [首次尝试 44731337867](https://github.com/betterfxb/private-moments-ios/actions/runs/44731337867) · [优化前 44733233790](https://github.com/betterfxb/private-moments-ios/actions/runs/44733233790) · [优化后 44735712091](https://github.com/betterfxb/private-moments-ios/actions/runs/44735712091) · [优化前样本](evidence/batch-19/44733233790/metrics.json) · [优化后样本](evidence/batch-19/44735712091/metrics.json)

## 3 · 本周回顾

首页周选择区之后提供本周回顾。它沿用现有暖纸色、系统圆体和衬线字。首页负责选日，回顾页以日期范围和记录数开场。对于同样一周的两条记录，日历在先会要求先选一个日期。以日期和总数在先可以直接读到整周感受，并从下方进入原始记录。暖纸底把正文和玫瑰色数据强调放在同一内容列，短标题和细分隔把感受与可点开的记录区区分开。计数和比例条由当前周的实际记录计算，空库不显示分布。 [既有最大字号首页](evidence/batch-18/44588232445/compact-dark-accessibility/Today-en.png)

**功能验收通过。** 五项日期单元测试通过，包括空库、单条、同一周跨年、起点恰好午夜、下一周边界和美国夏令时。中英文均走过空态、返回首页保存一条、查看确切感受和条数、打开原始详情、返回回顾。测试先在既有首页实证新增入口缺失，然后验证实现。页面读取同一 MomentStore，并用同一原生详情路由。 [实现前用例 44738612655](https://github.com/betterfxb/private-moments-ios/actions/runs/44738612655) · [双语复验 44744158226](https://github.com/betterfxb/private-moments-ios/actions/runs/44744158226)

**视觉验收通过。** 在同为 iPhone SE（第三代）375 × 667 点、深色、最大字号和一条已保存记录的条件下，英文日期及列表标题从两行缩为一行。新版卡片左边与日期和感受标签对齐，首条至少有 44 点高进入首屏，剩余信息沿自然滚动可达。中文日期在最大字号可换行，录入后仍可在首屏看到首条。空态、入口及完整行另外检查。使用原生 XCTest 的元素框、角色与值，结合实际 PNG 单独判断排版。纯色令牌计算中，辅助文字与暖纸底对比为浅色 4.96:1、深色 8.25:1。Web 页面扫描工具的适用范围为网页，本次使用原生工具。 [首版同状态原图](evidence/batch-19/44741694862/compact-dark-accessibility/Week-review-single-en.png) · [调整后英文](evidence/batch-19/44744158226/compact-dark-accessibility/Week-review-single-en.png) · [调整后中文](evidence/batch-19/44744158226/compact-dark-accessibility/Week-review-single-zh-Hans.png) · [完整中文记录](evidence/batch-19/44744158226/compact-dark-accessibility/Week-review-record-zh-Hans.png)

## 4 · 同一源码四配置回归

首轮 `41c4612e010cdb8449bad24b6f2e9dd811e13237` 实际执行四配置。54 项应用单元和无签名 Debug／Release、Release 测试钩子检查通过，20 次 UI 中 17 次通过。深色 iPhone 的三项全过。浅色 iPad 和常规小屏的英文 Files 都在等待期限内显示空白，截图及层级里没有可操作的目录或另存控制。深色最大字号作业的真实英文 Files 和图库通过，回顾测试却只滚到按钮中心，实拍中按钮的下半段与标签栏重叠，完整可见断言失败。iPad 旋转、图库与双语回顾均通过。 [首轮四配置](https://github.com/betterfxb/private-moments-ios/actions/runs/44746110865) · [iPad 空白面板](evidence/batch-19/44746110865/attempt-1-ipad-light-failure/Exporter-browser-unavailable-en.png) · [小屏空白面板](evidence/batch-19/44746110865/attempt-1-compact-light-failure/Exporter-browser-unavailable-en.png) · [最大字号入口下半段](evidence/batch-19/44746110865/attempt-1-compact-dark-accessibility-failure/Today-week-context-en.png)

修订 `8e526c8372374c13400ec26426e94dc6a8786e1e` 让回顾测试滚到完整按钮出现并停稳，继续要求整个入口位于标签栏上方。Files 就绪探测改走 XCTest 的有界条件轮询，原 90 秒预算、真实目录和完成反馈断言继续生效。两处修改在 UI 测试内，系统文件面板的空白原因仍待独立证据。iPad 定向复验通过九项备份单元和一次原生英文的本机保存、取消、恢复及重启，重选次数为零。最大字号复验通过五项日期单元和一个双语 UI 方法。运行截图可见整枚按钮位于标签栏上方，点按进入回顾后可访问首条记录。 [iPad 定向复验](https://github.com/betterfxb/private-moments-ios/actions/runs/44753981032) · [真实本机保存](evidence/batch-19/44753981032/ipad-light/Export-files-en.png) · [原生替换完成](evidence/batch-19/44753981032/ipad-light/Backup-restored-en.png) · [最大字号定向复验](https://github.com/betterfxb/private-moments-ios/actions/runs/44758268628) · [完整入口原图](evidence/batch-19/44758268628/compact-dark-accessibility/Week-review-entry-en.png)

第二轮完整四配置全部通过。每个作业在同一源码上按配置运行 `bash scripts/verify-mac.sh`，四个配置均执行了双语图库、本周回顾和英文原生 Files 回路。常规小屏另跑中文 Files、搜索编辑删除与其他完整用例。浅色 iPad 在导入提供方首次未交付文件时显示可恢复反馈，验证本机记录数保持后实际重选一次并完成。其余配置的重选次数为零。 [四配置作业](https://github.com/betterfxb/private-moments-ios/actions/runs/44760783402) · [原生 iPad 日志](evidence/batch-19/44760783402/ipad-light/native-xctest.txt)

| 配置 | 原生窗口与原图尺寸 | 应用单元 | UI 通过 | 构建和主要覆盖 |
| --- | --- | ---: | ---: | --- |
| iPhone SE（第三代）浅色 | 375 × 667 点，750 × 1334 像素 | 54 | 10 | 无签名 Debug／Release，Release 排除 Debug 测试钩子，双语 Files，千条时间线和持久化 |
| iPhone 17 Pro 深色 | 402 × 874 点，1206 × 2622 像素 | — | 3 | Debug 原生 UI，双语回顾、图库、英文 Files |
| iPad Pro 13 英寸（M5）浅色 | 1032 × 1376 点，2064 × 2752 像素 | — | 4 | Debug 原生 UI，双语回顾、图库、英文 Files、旋转连续性 |
| iPhone SE（第三代）深色最大字号 | 375 × 667 点，750 × 1334 像素 | — | 3 | Debug 原生 UI，双语回顾、图库、英文 Files |

最终运行导出 400 张 PNG，按清单对 48 张相关原图核验了字节和 CRC，实际打开并归档 40 张。四种配置中，日期、总数和感受从上方依次承接到可点记录，记录卡对齐日期列。最大字号的中文日期自然换行，常规字号水平排布。浅色 iPad 继续使用暖纸底和居中内容列，双语入口及卡片可点。四套原生 Files 截图均保留实测的本机位置和恢复反馈。 [常规小屏英文回顾](evidence/batch-19/44760783402/compact-light/Week-review-single-en.png) · [深色 iPhone 中文回顾](evidence/batch-19/44760783402/phone-dark/Week-review-single-zh-Hans.png) · [浅色 iPad 回顾](evidence/batch-19/44760783402/ipad-light/Week-review-single-en.png) · [最大字号中文回顾](evidence/batch-19/44760783402/compact-dark-accessibility/Week-review-single-zh-Hans.png) · [小屏真实 Files](evidence/batch-19/44760783402/compact-light/Export-files-en.png)

Windows 工具回归用 `python -m unittest discover -s tools -p 'test_*.py'`，47 项通过。使用 `node tools/audit-localization.mjs`、`node tools/audit-xcode-project.mjs` 和 `node tools/audit-release-materials.mjs` 检查 236 个本地化键、111 个 Xcode 对象和双语发行材料。Bundle ID、隐私政策发布者及审核联系人等仍使用既有待填项。

## 剩余验收

本批可复核的是指定模拟器条件下的功能、可见排版与可访问元素。真机 Files、VoiceOver 实际朗读和物理键盘仍待验证。端到端搜索建议在真机用应用内测点复测，保留输入、渲染与滚动的独立测量。产品目前处于 GitHub 草稿分支的开发验收阶段。 [草稿 PR #1](https://github.com/betterfxb/private-moments-ios/pull/1)
