# Private Moments 项目记忆

更新日期：2026-11-26（Asia/Tokyo）。源码、原始运行及证据收据共同确定验收范围。记录文档的提交可与实际受测源码不同。

## 项目与约束

- 工作目录：`D:\find_project\ios\PrivateMoments`。仓库：https://github.com/betterfxb/private-moments-ios 。现有分支：`feat/native-manual-entry`；[PR #1](https://github.com/betterfxb/private-moments-ios/pull/1)保持草稿。
- 用户在Windows开发，SwiftUI／SwiftData原生编译和XCTest由GitHub托管macOS执行；本地静态检查不能替代原生运行。
- 用户已说明尚无付费Apple Developer账号，优先继续开发。不得将无签名归档称为可安装或TestFlight成功；实际签名、上传和main合并尚未执行。
- `design/`是既有未跟踪目录，保留原状，不纳入批量暂存。代码提交、证据、文档应显式选择路径。
- 用户重视温馨感、视觉质感和真实操作体验，曾多次否定旧视觉方案。当前语义Rose体系的功能验收不等于审美认可，也不能据此宣称已超越DO。

## 架构与数据边界

- RootView 持有 MomentStore、SessionClock、Today／Timeline／Review 独立导航路径和选中标签。RecapDraftStore 以独立受保护文件暂存一份未完成的表单，正式记录仅在明确保存后更新。
- SwiftData 本机数据使用显式 schema V2 并包含 V1 升级路径。CloudKit 同步已禁用。用户可主动导出 JSON v1 备份，文件包含已保存备注和收藏状态，以明文保存。未完成草稿不随应用导出。
- 界面支持英语和简体中文，跟随 iOS 应用语言。记录枚举保持稳定，用户备注保留原文。字符串目录 296 键，Xcode 项目审计 113 对象。
- Debug UI测试使用每次独立UUID库，不重置正常日记；Release排除测试钩子。认证使用真实系统流程，不增加成功绕过路径。

## 第二十七至三十一批工作状态

- 第 27 批对照加拿大 App Store 的 Do? 2.0 官方手机画面，打磨「沉浸扉页」首页、时间线、详情和筛选。iPhone SE（第三代）中英文两种配置完成同数据回拍。`b84dbdc` 的最大字号回拍确认日期和类型筛选各一行，首条记录至少有 44 点可点击。`4009428` 的浅色回拍确认中文首页首屏露出两条近期记录。最大字号图库及独立双语键盘搜索均通过。审美反馈和竞品任务实测仍单独记录。[验收与对照](release/UX-ACCEPTANCE-27.md)
- 第 28 批新增快捷记录、保存后直达详情、复用用户标签，以及大小写去重和内容限制。修改后的快捷记录草稿恢复为完整表单。第 29 批在回顾内增加月历、辅助字号日期列表，以及按日查看。`b84dbdc` 的两种字号月历用例通过，核心 71 项单测、7 项 UI 及无签名双配置通过，实际 iOS 17.5 另有 6 项单测和 4 项 UI 通过。`c01d422` 为标签提供键盘工具栏专用提交按钮，两套定向复验已启动。[功能及验证记录](release/UX-ACCEPTANCE-28-31.md)
- 第 30 批整理加密备份默认策略、旧明文导入、口令丢失说明和进程终止后暂停计时等待确认。第 31 批已补齐真机用例和截图清单，真机执行依赖签名开发构建与设备。[待确认与真机清单](release/DEVICE-AND-RECOVERY-DECISIONS.md)

## 第二十三至二十六批工作状态

- 第二十三批把模拟器验收拆为可独立补跑的作业。四配置 17 个场景已在相同应用源码上分别验证通过。成功结果跨完整运行和专项补跑，单次完整矩阵有取消与失败记录。最新版核心通过 67 项单测、7 项原生 UI 用例、无签名 Debug／Release 和钩子排除。最大字号搜索遮挡已修复并通过双语图库。iPad 和深色手机的键盘采样等待已调整，`331ed2b` 隔离输入、性能和旋转诊断。Windows 55 项工具测试通过。各范围、实际 SHA 和例外见报告。[验收报告](release/UX-ACCEPTANCE-23.md)
- 第二十四批窄屏候选样张将清除挪到计数旁，暖棕强调色用于收藏和小型操作，长备注提前到时长与评分前。iPhone SE（第三代）相同配置的双语原生前后对照通过。iPhone 17 Pro 深色、iPad Pro 13 英寸浅色及 iPhone SE 深色最大辅助字号同流程和对比度检查均通过，共归档 30 张原图。最大字号的时间线第一条记录仍需滚动。用户尚未评价本次样张。[样张报告](release/UX-ACCEPTANCE-24.md) · [原生前后对照](release/evidence/batch-24/reading-comparison-375pt.png)
- 第二十五批已实现日期和单标签组合筛选、收藏「再记一次」以及月度精选。修正了取消日期范围退出及最大字号日期横向裁切。`c260b35` 常规小屏与同产品源码 `e30269d` 的最大字号 ARM64 各通过 11 项单测和 3 个原生功能用例。最大字号能换行读完整日期，系统日历打开与取消均经双语回归，极窄英文顶栏标题仍截短。Windows 54 项工具测试和本地化、工程审计通过。[功能验收](release/UX-ACCEPTANCE-25.md)
- 第 26 批已写出真机验收清单，并记录加密备份和暂停恢复计时的两项待确认设计。实际真机尚未验收，用户此前选择继续开发。[真机及恢复方案](release/DEVICE-AND-RECOVERY-DECISIONS.md)

## 第二十二批收藏、阅读界面、周期对照与草稿

- 详情支持收藏和取消。时间线「仅看收藏」与原有搜索和记录类型筛选组合。旧 JSON 合并保留本机已有的收藏，备份中的明确状态可随恢复应用。时间线与详情沿用暖纸色，按日期和感受组织阅读，备注提前到标签前。
- 回顾可比较相邻周／月，两期有记录才显示。记录数、日期数与重复出现的常见感受可定位到对应记录。进程终止后，首页可继续或丢弃一份本机草稿。已保存记录与进行中的计时遵循各自的生命周期。
- `4e7b775` 在常规小屏和 iPad 各通过 16 项单测、5 个双语 UI 用例。`7125c28` 在深色最大辅助字号同样通过 16 项单测和 5 个双语 UI 用例，实际 iOS 17.5 通过 6 项单测、4 个界面用例及无签名 Release 检查。`17663c0` 通过 9 项备份单测与系统 Files 往返，`37280b6` 通过最大字号双语原生图库及独立搜索，GitHub 作业终态为取消且已上传截图和结果包。共归档 40 张原图及指纹。首轮完整矩阵与各次复验按实际源码记录。真机旁白和签名发行仍待完成。[验收报告](release/UX-ACCEPTANCE-22.md) · [视觉并排对照](release/evidence/batch-22/diagnostics/reading-comparison-375pt.png)

## 第二十一批独立回顾页

- 原生导航为「今天｜时间线｜回顾｜设置」。回顾支持按周／月翻阅及按日期跳转，显示周期总数和按日分组的本机记录。点感受后可直接查看匹配记录，详情返回保留周期和筛选。首页原有「本周回顾」路径复用同一界面。现有 SwiftData 与备份格式继续适用。
- 源码 `de97f559894231b9b18c355bda46c3d1377762fc` 的 iPhone SE（第三代）浅色常规字号和深色最大字号配置通过。每配置 7 项日期查询单测和 2 个双语原生 UI 用例，归档 12 张原图。真机 VoiceOver、iPad 大屏和新回顾页的 iOS 17 运行证据待补。下一批规划为收藏。 [完整报告](release/UX-ACCEPTANCE-21.md) · [常规运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45386361856) · [最大字号运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45392182272)

## 第二十批原生首页、千条搜索与旧系统验收

- 「沉浸扉页」原型与原生首页在 375 × 667 点中文浅色空态及有记录状态并排。原生保留提前出现的「开始记录」和独立「补记」，用暖色渐变消除导航和封面的断层，中央叠形补上内部亮面。最大字号在原生前后实拍中保留两入口。源码 `e08b36b5e964391da92568b7fbbcbde900f620e2` 的四配置、54 应用单元、20 次 UI 和无签名 Debug／Release 通过。 [云端四配置](https://github.com/betterfxb/private-moments-ios/actions/runs/45165361425) · [原图、对照及收据](release/evidence/batch-20/45165361425/visual-verification.json)
- 1,000 条合成记录在三个独立进程中首次查询得到唯一结果，末键后的完整过滤分组中位数 6.7 ms，SwiftUI 更新 12.3 ms。首字符到唯一行布局 51.6 ms，显示刷新回调波动明显。滚动约 2.49 s，其中系统减速约 2.31 s。保留现有搜索逻辑。XCTest 验证了真实键盘提交、收键盘、查询保留、结果可点及编辑和删除后的搜索一致性。新增测点只在 Debug 的隔离库启用。 [云端定向复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45179488037) · [三次样本](release/evidence/batch-20/45179488037/metrics.json)
- `legacy_ios17` 入口使用原有 Xcode 26.2，有需要时从 Apple 下载 iOS 17.5（21F79）。实际 Intel iPhone 15 模拟器通过搜索和完整补记两个原生用例，Release 编译最低版本为 17.0。首轮因测试点落在距窗口底部 22 点处而漏选，复验先滚入完整选项并核对选中状态；一个 ARM64 复验未获执行器。17.0 运行时以及真机 Files、VoiceOver、中文输入候选和外接键盘待验证。 [最终 iOS 17.5 复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45187823979) · [第二十批报告和双语真机清单](release/UX-ACCEPTANCE-20.md)

## 第十九批 iPad 输入、时间线与本周回顾

按 iPad 真实窗口操作、时间线应用内测量、本周回顾、四配置回归的顺序完成。最新完整验证为源码 `8e526c8372374c13400ec26426e94dc6a8786e1e` 的[四配置 44760783402](https://github.com/betterfxb/private-moments-ios/actions/runs/44760783402)。54 应用单元、20 UI、无签名 Debug／Release 和 Release 测试钩子排除通过。四个配置均通过真实英文 Files，常规小屏另通过真实中文 Files。浅色 iPad 在应用显示来源不可用、记录数保持后重选一次并通过。导出 400 张 PNG，48 张相关原图核验，40 张实际打开并归档。详见[第十九批报告](release/UX-ACCEPTANCE-19.md)及[最终收据](release/evidence/batch-19/44760783402/verification.json)。

- [iPad 44729533351](https://github.com/betterfxb/private-moments-ios/actions/runs/44729533351)在深色最大字号和实际软件键盘下，经系统右上角拖柄把宽度从 630 点缩至 513 点。原两行备注可读，保存按钮可点，点击后读回同样备注。源码 `3261023b94904433d28e09925b566fad1d730e27`，五张物理原图和层级已封存。
- [性能基线 44733233790](https://github.com/betterfxb/private-moments-ios/actions/runs/44733233790)与[优化 44735712091](https://github.com/betterfxb/private-moments-ios/actions/runs/44735712091)同为小屏浅色，三次真实搜索和滚动。页面在每次渲染复用一个筛选结果，完整查询的过滤次数 3 降为 1，应用内过滤和分组中位数 22.387 降至 9.960 ms。XCTest 从输入到匹配和应用滚动停止的中位数在这两轮未见改善。感受编辑、删除及查询一致性两次通过。隔离测试日志只有阶段、计时、条数和长度。
- [本周回顾复验 44744158226](https://github.com/betterfxb/private-moments-ios/actions/runs/44744158226)五项日期测试及一个双语端到端 UI 方法通过。Today 周选择区之后进入，本地日历使用半开周界，显示实际日期、记录数和感受分布，点记录进入现有详情。英文最大字号用短日期和短列表标题将首条带回首屏，回顾列表用撑满版式并与日期左对齐。保留两种语言在相同设备、主题、字号和数据量的原图。使用 Geek Design Engineering 原生验收流程，视觉是工程走查，用户审美反馈仍以实际评阅为准。
- [首轮 44746110865](https://github.com/betterfxb/private-moments-ios/actions/runs/44746110865)保留三项失败。浅色 iPad 与常规小屏各遇英文系统空白面板，最大字号入口测试只滚到按钮中心，遮挡断言失败。随后只调整 UI 测试的整控件滚动及原 90 秒内的就绪轮询，同源码先通过[iPad Files 44753981032](https://github.com/betterfxb/private-moments-ios/actions/runs/44753981032)和[最大字号回顾 44758268628](https://github.com/betterfxb/private-moments-ios/actions/runs/44758268628)，再通过上述完整矩阵。系统空白的根因仍待独立证据。真机 Files、VoiceOver 朗读、物理键盘及端到端性能仍待验证。

## 第十八批首页、操作体验与性能验收

仓库开发分支已实现原生暖色沉浸扉页、双语空态及有记录首页、备份入口精简、删除命中区、iPad 窗口和数据连续性回归、1,000 条合成数据基线以及明确终止规则。完整四配置的受测源码为 `7c90b26c50a39f072f92eda83ed62e7136037a49`，[运行 44543961473](https://github.com/betterfxb/private-moments-ios/actions/runs/44543961473)。51 项应用单元、14/15 次 UI 及无签名 Debug／Release 检查通过，唯一失败为浅色小屏英文 Files 定位。两次无执行器的小屏尝试和一次无执行器的 iPad 尝试有独立状态，重跑只替换未执行的配置。

修订源码 `3602f3096d42a008df0d95a16f6fa6a5c9f0b4d3` 把最大字号首页日期缩成一行，补录完整高于标签栏，设置首屏直接显示已保存数量。英文 Files 测试等真实目录或稳定的系统侧栏，仍保留实际文件结果。英文常规字号定向 [44574843556](https://github.com/betterfxb/private-moments-ios/actions/runs/44574843556) 在标准 Intel 通过，零显式重选。最大字号 Intel [44581949391](https://github.com/betterfxb/private-moments-ios/actions/runs/44581949391) 在初始化时超时，未执行用例。ARM64 同源码 [44588232445](https://github.com/betterfxb/private-moments-ios/actions/runs/44588232445) 通过双语图库及新增首屏断言，[44594842249](https://github.com/betterfxb/private-moments-ios/actions/runs/44594842249) 通过最大字号真实 Files 回路，零显式重选。命中区在常规 iPad 原生实测高 49.5 点，真实点按文字上方内边距打开删除确认。

独立系统窗口 [44541077629](https://github.com/betterfxb/private-moments-ios/actions/runs/44541077629) 是真实 iPadOS Windowed Apps 拖柄验证，宽度 1032／784／516 点。备注两行、3 分 8 秒和 44 × 44 点保存目标均保留，详情一次返回、暂停原秒数保留。已保存的记录重启后可读。未保存草稿仅在当前进程存在，进程退出时会停止会话计时，界面提供双语提示。

千条 M1 模拟器中位数为启动 4.240 秒、滚动 3.513 秒、输入到唯一结果 1.844 秒，包含 XCTest 驱动时间。千条 JSON 编码／解码为 6.349／5.190 毫秒中位数，文件大小 323,919 字节。源、执行器、样本与限制见[第十八批报告](release/UX-ACCEPTANCE-18.md)。后续可从[最大字号原图收据](release/evidence/batch-18/44588232445/verification.json)、[窗口原图收据](release/evidence/batch-18/44541077629/verification.json)和[四配置收据](release/evidence/batch-18/44543961473/verification.json)复核。

## 第十七批历史完整四配置验收

按[计划](release/BATCH-17-PLAN.md)完成，见[报告](release/UX-ACCEPTANCE-17.md)、[原图](release/evidence/batch-17/index.html)及[收据](release/evidence/batch-17/verification.json)。完整受测源码`9e106f37431da8a30448731271abdfccaa19a9c7`，运行43734076863；50应用单元、13次UI执行、Debug／Release及Release测试钩子排除通过。iPad常规Large字号双语输入／英文文件，以及SE最大辅助字号双语输入、英文和中文真实文件定向各有独立运行来源，先原图检查才进入下一项。43项本地工具测试及231键／109对象／发行材料审计通过，原始占位警告保留。

搜索激活时计数先于辅助筛选／说明，筛选与清除仍在无界记录列表前；匹配提交直接展示可操作记录；实际键盘及候选栏在场的计数完整无遮挡，真实Search提交只移除焦点且查询／0条保留，应用自动露出完整无结果说明，测试不代为滚动；匹配／清除断言保留。iOS18及以上使用searchFocused，iOS17响应链兼容分支尚未在旧运行时实测。Settings brief反馈属于滚动正文，新反馈完整显示，滚动视口不被固定长消息挤压，短屏正常滚动可移出但状态仍保留；宽屏整页可容纳时独立核对提示及全部动作完整同屏，实际备份取消／合并／替换／重启精确内容通过。没有缩小字体、自动超时消息、存储格式或认证变更。

成功运行523张PNG核验、136张实际打开保留，失败现场分列。完整矩阵有两次显式系统文件重选：主配置中文source-unavailable和最大字号英文picker-not-delivered各一次；恢复原图及原始原因保留，精确数据断言通过，不能写成零恢复直达或已解决提供方根因。五项前置定向均零重选。

原生UI方法耗时不是产品性能测量，仍不能保证全部长文同屏。最大字号输入时范围末行、英文长记录下部仍需正常滚动，原生窄查询栏也无法同时显示长查询全文。iPad删除动作AX frame约20.55pt，实际扩展命中范围尚未独立测量；后续应检查触控尺寸和最大字号信息密度。沉浸扉页整体视觉、真实窗口缩放、终止恢复、真机／IME／其他运行时与发行配置继续待办；主分支、签名和Apple上传约束保持。

## 第十六批历史完整四配置验收


按[计划](release/BATCH-16-PLAN.md)完成，见[报告](release/UX-ACCEPTANCE-16.md)、[原图](release/evidence/batch-16/index.html)和[收据](release/evidence/batch-16/verification.json)。最终完整受测源码`82ccfccdb3bb743a19628e10e42d54f75698c5a3`。主要成功运行包括[iPad深色最大字号双语图库43596558784](https://github.com/betterfxb/private-moments-ios/actions/runs/43596558784)、[修订后手机最大字号输入43605122458](https://github.com/betterfxb/private-moments-ios/actions/runs/43605122458)、[手机真实文件回路43655072648](https://github.com/betterfxb/private-moments-ios/actions/runs/43655072648)及[最终完整四配置43667122995](https://github.com/betterfxb/private-moments-ios/actions/runs/43667122995)；每项定向通过并检查原图后才派发下一项。文件定向与Done修订后输入／完整各有独立测试来源，除Done单函数外文件验证内容未变；五项生产路径一致，手机输入搜索检查函数逐字未变。完整回归50单元、13UI、Debug／Release及Release测试钩子排除通过，文件定向的9项备份单元是额外执行而非9个新用例。

首次完整43599672305／003cdcd实际失败，原始任务日志、物理图与层级[单独封存](release/evidence/batch-16-failures/43599672305/verification.json)，不拼接个别成功配置。后续只修订图库测试，使用正常滚动重新显示已清空的原生搜索框；系统空白导出面板原因仍未独立证明，保持90秒期限、不预热Files。新成功不能解释为旧失败因果已解决。

新增[手机Done修订输入43664332669](https://github.com/betterfxb/private-moments-ios/actions/runs/43664332669)，源码`82ccfccdb3bb743a19628e10e42d54f75698c5a3`，每语言两次Done后键盘不存在、原双语图库和搜索断言通过，实际原图检查后才再次派发完整回归。文件来源`657596b3cabcd5adcbd18208e73231129ced7be4`保留，除dismissRecapKeyboard函数外整个UITest及生产路径与最终完整来源逐字一致。

第二次完整43659541214／657596b仍失败，phone-dark文件通过、图库Done后查询已消失Keyboard触发No matches，其他三配置成功。其12张失败配置PNG核验、2张关联原图实际打开及完整失败任务日志／4文本／矩阵状态[封存](release/evidence/batch-16-failures/43659541214/verification.json)。只改手机Done等待为单次不存在状态、保留5秒，iPad行为不改；没有Done之后物理PNG，不能用之前图片冒充。

文件定向43608392564／4592271另失败于取消反馈下的删除按钮滚动就绪；5张实际打开原图、完整运行日志和层级[独立保留](release/evidence/batch-16-failures/43608392564/verification.json)。仅固定Settings反馈存在时的测试拖动改为slow并末端按住0.2秒，保持所有原有功能与几何断言，随后以新源码文件定向及完整结果验证；不称为生产数据故障修复。

全程慢速文件定向43610236417／edc7ed9再次失败，新增实际日志显示每次61点、16次仍未到达远处目标；5张实际打开原图及完整日志[独立封存](release/evidence/batch-16-failures/43610236417/verification.json)。最终采用远处正常滚动、进入三个可用视口距离后慢速停稳，保留原16次上限及全部断言，不能把先前失败描述为已通过。

43652828407／9b74274另在单击本机位置后目录根15秒未出现处失败，尚未执行新手势。1张实际打开原图、17文本和完整日志[保留](release/evidence/batch-16-failures/43652828407/verification.json)，有DocumentManager内部断言、根因未证明。最终侧栏和真实目录根共用原90秒预算，不重置或重复点击；原Save及完成条件保持。

时间线搜索框改为简短Search moments／搜索记录，完整范围正文可换行，保留日期／类型／感受／标签搜索及备注排除规则。231键本地化、109对象、18项工具测试与发行审计通过。共539张PNG核验，79张实际打开保留；原始日志／图／元数据与逐配置来源独立记录。完整iPad旋转包含真实Settings参考前置，第十五批两项冷启动仍绑定其旧源码，没有重标为本批冷验证。

仅搜索局部体验改进；“沉浸扉页”作为后续视觉方向保留，未完成原生实现或审美验收。真实窗口缩放、草稿／计时终止恢复策略、性能与真机工作独立待办；无签名、Apple上传或main合并。

原图仍显示最大字号查询期间计数下缘被键盘遮挡、小屏空结果辅助说明在键盘下方，清空后完整计数与无键盘恢复；固定Settings长反馈约占44%高度，删除目标曾需12次正常／停稳滚动。以上操作负担没有由测试修订解决，后续产品改进应直接针对这些实际问题。539张是核验总数，79张才是实际打开并归档的原图，不混同为全部逐张视觉验收。

## 第十三批历史完整四配置验收


第十三批按[计划](release/BATCH-13-PLAN.md)完成。最终源码`fb78856ca48a43eb1739d5c2c6198d973a519246`；[报告](release/UX-ACCEPTANCE-13.md)、[原图](release/evidence/batch-13/index.html)、[收据](release/evidence/batch-13/verification.json)包含每次运行的精确源码与实际覆盖。

- files-initial：[运行43528908376](https://github.com/betterfxb/private-moments-ios/actions/runs/43528908376)，源码`3437144fddbe1627a4162521fa2a70e9891d87d2`。
- rotation：[运行43533970911](https://github.com/betterfxb/private-moments-ios/actions/runs/43533970911)，源码`41b18ca1c0653c655d9ea5b083f68d46b14c1100`。
- files：[运行43542044127](https://github.com/betterfxb/private-moments-ios/actions/runs/43542044127)，源码`96e21b043bf370101793c422071bc6e7f5b59689`。
- files-ax：[运行43544171039](https://github.com/betterfxb/private-moments-ios/actions/runs/43544171039)，源码`96e21b043bf370101793c422071bc6e7f5b59689`。
- files-zh：[运行43549009789](https://github.com/betterfxb/private-moments-ios/actions/runs/43549009789)，源码`adac204764b70e7bea74039b887106c53f8b1a72`。
- files-ax-final：[运行43554342330](https://github.com/betterfxb/private-moments-ios/actions/runs/43554342330)，源码`fb78856ca48a43eb1739d5c2c6198d973a519246`。
- full：[运行43556512255](https://github.com/betterfxb/private-moments-ios/actions/runs/43556512255)，源码`fb78856ca48a43eb1739d5c2c6198d973a519246`。
- 完整四配置：50单元，6主配置／3iPad／其他各2UI，Debug／Release及Release钩子排除通过。七次成功运行363张精确PNG校验，166张实际打开并保留。初始手机、旋转定向、四项后续文件定向与完整回归分别绑定各自源码。最终compact-light英文／中文各发生1次真实来源不可用反馈，并各经一次明确重选恢复，记录未变和后续精确内容断言通过；其他配置显式恢复0次。
- 初始旋转运行43531447097失败后修订原生Back定位、稳定等待及目的地验证；完整运行43536445203另暴露数字输入未聚焦、等待入口时遗漏已加载本机根目录、中文恢复后仍在Today。随后修订测试输入就绪、根目录轮询及真实TabBar遮挡判断；96e21b0先通过深色手机英文与最大字号英文定向；同源码中文定向43547538933在5秒数值等待失败，原图和层级实际值4与请求一致，之后仅修订为同步检查返回值及15秒有界观察，adac204通过中文定向，但第二次完整43550472100的最大字号关闭反馈步骤失败；修订为关闭按钮稳定后单击、15秒消失等待、失败物理取证和立即检查记录数。最终源码先通过最大字号文件定向，再完整回归。四次失败的实际可用原图／层级／日志独立保留，不计最终完整通过。初次Back失败根因未独立证明；TabBar误触是与原图及代码一致的解释，未保留实际触点坐标，不能声称因果已独立证明。
- 本批应用生产源码、资源、应用单元与项目配置未改。数字输入测试新增单击前稳定等待、真实键盘就绪与精确值确认，不盲目重复点击。旋转覆盖iPad浅色Large完整窗口、键盘收起后草稿／导航／暂停状态和已保存记录重启；20张双语旋转图及18次实际窗口几何核对在既有旋转定向和最终完整iPad各执行一次；较早失败完整运行的个别成功配置另记，不混入最终源码统计。EXIF显示方向与原始PNG像素尺寸分别保存，未重写原图。
- 旧phone-dark空白导出取景见[第十二批](release/UX-ACCEPTANCE-12.md)，本批新图显示真实保存控件；旧结果不被改写。iPad浅色最大字号竖屏补充仍绑定[第十一批](release/UX-ACCEPTANCE-11.md)源码5c0a637，未在本批重新执行。

## 第十五批独立冷启动旋转验收

按[计划](release/BATCH-15-PLAN.md)完成，见[报告](release/UX-ACCEPTANCE-15.md)、[原图](release/evidence/batch-15/index.html)及[收据](release/evidence/batch-15/verification.json)。

- [cold-en运行43588585515](https://github.com/betterfxb/private-moments-ios/actions/runs/43588585515)：源码`fbcae3f4b34055f719c2044f1adb322844349659`，方法`testIPadColdEnglishRotationContinuity`。
- [cold-zh-Hans运行43589974794](https://github.com/betterfxb/private-moments-ios/actions/runs/43589974794)：源码`fbcae3f4b34055f719c2044f1adb322844349659`，方法`testIPadColdChineseRotationContinuity`。
- [reference运行43591326457](https://github.com/betterfxb/private-moments-ios/actions/runs/43591326457)：源码`fbcae3f4b34055f719c2044f1adb322844349659`，方法`testIPadRotationContinuity`。

独立英文与中文冷启动各在全新派发的macOS任务中仅运行一个语言方法，入口应用尚未运行，不先调用Settings参考；各9次实际应用窗口核对与10张原图。默认浅色reference双语共享流程另行回归。共42张PNG核验、42张实际打开保留；18项工具测试及801组范围保护通过。定向Debug UI，无应用单元或Release验收；该批结束时最近完整四配置为第十三批fb78856；现在以第十六批新源码完整结果为准。

仅补齐指定26.2云端条件，旧失败根因仍未独立证明，不称为生产代码旋转修复或普遍稳定性证明。生产代码／应用单元／项目未改；默认四配置排除冷方法，保持原始范围。下一步真实窗口缩放、草稿／计时终止恢复策略、性能与真机；搜索提示省略和视觉质感仍需产品迭代。

## 第十四批补充适配验收

按[第十四批计划](release/BATCH-14-PLAN.md)完成，详见[报告](release/UX-ACCEPTANCE-14.md)、[原图](release/evidence/batch-14/index.html)与[收据](release/evidence/batch-14/verification.json)。默认四配置保持；新配置仅显式input／rotation可用，不允许full／backup，mini缺失不得回退为大屏。

- [ipad-mini-light / rotation 运行43571193201](https://github.com/betterfxb/private-moments-ios/actions/runs/43571193201)，实际源码 `d1ab55bad08c341d4eadf18d81b63e73b4d2dac0`。
- [ipad-dark-accessibility / rotation 运行43579218909](https://github.com/betterfxb/private-moments-ios/actions/runs/43579218909)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。
- [ipad-light / rotation 运行43580963939](https://github.com/betterfxb/private-moments-ios/actions/runs/43580963939)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。
- [ipad-dark-accessibility / input 运行43583072318](https://github.com/betterfxb/private-moments-ios/actions/runs/43583072318)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。

共124张PNG完成精确核验，88张原图实际打开并保留。工具测试11项、脚本／工作流范围防护267组及既有项目审计通过。定向方法没有应用单元／Release验收，该批结束时完整回归为第十三批源码fb78856，当前最近完整结果见第十六批；不能把旧完整结果重标为本批受测源码。小屏全窗口与旋转均不是系统分屏／窗口缩放验收；本批计划保存实际窗口操作／几何／连续性的后续协议。

第十四批最终深色及默认iPad旋转包含真实Settings横竖屏参考前置，因此该批未覆盖独立冷启动首转；第十五批另行补齐指定26.2云端的英文／中文条件。三次旧失败仍单独归档，根因未独立证明，不能将后续成功解释为生产旋转故障已经修复。

双语输入图库60张核验、24张实际打开，软件键盘下的两行ASCII备注和20字符计数保留；不等同中文IME候选验收。中英文搜索提示省略、宽屏居中留白及长错误文案需继续滚动保留为体验改进项。43577972823的SpringBoard层级观察到Other类型resize-grabber（Resize Private Moments／Bottom Right），尚未证明可见／命中／拖动／缩放，只作为后续真实窗口操作线索。

## 继续执行时的规则

1. 先检查git状态、对应批次计划和最新云端运行；不要重新开始已通过且功能未变的任务。
2. 按顺序完成定向运行及其原图检查后，再派发完整四配置回归。同分支同时派发第二次运行会触发并发取消，应先确认无活动运行。
3. 派发请求先留标记，仅提交一次；网络响应不确定时查询真实运行，避免重复派发。只读网络可有界重试，不能把网络重试写成功能测试重跑。
4. 失败先保留日志、物理原图及层级，区分应用、测试假设、系统提供方和云端环境；修复后用新源码验证，不放宽精确内容断言掩盖问题。
5. 原始PNG不修饰；分别记录导出数量、下载核验数量及实际打开数量。保留manifest、哈希、关键原始日志和实际受测源码，文档提交不触发无意义重跑。
6. 原始日志／层级／下载收据使用对应证据目录的`.gitattributes`保留原始字节。GitHub短plan任务可能只提供合并日志，应检查真实合并内容。

## 待办及结论边界

- 第十四批补充mini浅色Large、iPad深色最大字号及默认浅色Large全窗口旋转；最终大屏运行包含Settings参考前置。键盘已收起，检查草稿／导航／暂停及已保存记录重启，不能外推为冷启动首转或分屏通过。
- 第十五批补齐指定26.2云端独立英文／中文冷启动旋转。第十八批验证单窗口真实缩放、进程终止与合成数据性能。并行双窗口、多任务搭配和真机极小窗口仍待独立验证。未来改变私密草稿落盘或跨进程计时，应先决定隐私和存储契约。
- 中文IME组合与候选、VoiceOver／Switch Control、成功Face ID／Touch ID及待决认证取消、锁屏文件保护、外接／浮动键盘和外部文件提供方仍需相应设备或环境。
- 当前只验证固定Xcode／SDK／Simulator26.2；iOS17最低目标不代表所有旧系统已实测。真机、审美验收和发行材料中的发布者／Bundle ID占位仍未关闭。

只保存合成测试内容与工程事实；不把凭据、私钥或真实私密记录写入记忆。
