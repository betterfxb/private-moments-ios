# Private Moments 项目记忆

更新日期：2026-11-14（Asia/Tokyo）。这是可随仓库迁移的工程记忆；验收事实以对应源码、原始运行及证据收据为准，不能以文档最新提交替代受测源码。

## 项目与约束

- 工作目录：`D:\find_project\ios\PrivateMoments`。仓库：https://github.com/betterfxb/private-moments-ios 。现有分支：`feat/native-manual-entry`；[PR #1](https://github.com/betterfxb/private-moments-ios/pull/1)保持草稿。
- 用户在Windows开发，SwiftUI／SwiftData原生编译和XCTest由GitHub托管macOS执行；本地静态检查不能替代原生运行。
- 用户已说明尚无付费Apple Developer账号，优先继续开发。不得将无签名归档称为可安装或TestFlight成功；实际签名、上传和main合并尚未执行。
- `design/`是既有未跟踪目录，保留原状，不纳入批量暂存。代码提交、证据、文档应显式选择路径。
- 用户重视温馨感、视觉质感和真实操作体验，曾多次否定旧视觉方案。当前语义Rose体系的功能验收不等于审美认可，也不能据此宣称已超越DO。

## 架构与数据边界

- RootView持有MomentStore、SessionClock、Today／Timeline独立导航路径和选中标签；RecapView保存表单草稿，持久化只在明确保存时完成。
- SwiftData本机数据、显式schema V1、禁止托管CloudKit同步；JSON备份是用户主动导出，包含备注且未加密。不要把“本机优先”解释成已实现云同步或跨设备服务。
- 界面支持English和简体中文，跟随iOS应用语言；记录枚举保持稳定，用户备注不自动翻译。字符串目录230键，现有项目静态审计109对象。
- Debug UI测试使用每次独立UUID库，不重置正常日记；Release排除测试钩子。认证使用真实系统流程，不增加成功绕过路径。

## 最近完整四配置验收（第十三批）

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

## 第十四批补充适配验收

按[第十四批计划](release/BATCH-14-PLAN.md)完成，详见[报告](release/UX-ACCEPTANCE-14.md)、[原图](release/evidence/batch-14/index.html)与[收据](release/evidence/batch-14/verification.json)。默认四配置保持；新配置仅显式input／rotation可用，不允许full／backup，mini缺失不得回退为大屏。

- [ipad-mini-light / rotation 运行43571193201](https://github.com/betterfxb/private-moments-ios/actions/runs/43571193201)，实际源码 `d1ab55bad08c341d4eadf18d81b63e73b4d2dac0`。
- [ipad-dark-accessibility / rotation 运行43579218909](https://github.com/betterfxb/private-moments-ios/actions/runs/43579218909)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。
- [ipad-light / rotation 运行43580963939](https://github.com/betterfxb/private-moments-ios/actions/runs/43580963939)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。
- [ipad-dark-accessibility / input 运行43583072318](https://github.com/betterfxb/private-moments-ios/actions/runs/43583072318)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。

共124张PNG完成精确核验，88张原图实际打开并保留。工具测试11项、脚本／工作流范围防护267组及既有项目审计通过。定向方法没有应用单元／Release验收，最近完整回归仍是第十三批源码fb78856；不能把旧完整结果重标为本批受测源码。小屏全窗口与旋转均不是系统分屏／窗口缩放验收；本批计划保存实际窗口操作／几何／连续性的后续协议。

最终深色及默认iPad旋转包含真实Settings横竖屏参考前置；旧冷启动首转失败根因仍未独立证明，未经该前置的深色最大字号首转还需独立复核。三次失败均单独归档，不能将后续成功解释为生产旋转故障已经修复。

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
- 下一步先独立复核未经Settings参考前置的深色最大字号冷启动首转，再建立实际系统分屏／窗口缩放证据，明确终止后的未保存草稿和计时恢复策略、实现及性能基准。产品恢复策略不能由测试脚本擅自假定。
- 中文IME组合与候选、VoiceOver／Switch Control、成功Face ID／Touch ID及待决认证取消、锁屏文件保护、外接／浮动键盘和外部文件提供方仍需相应设备或环境。
- 当前只验证固定Xcode／SDK／Simulator26.2；iOS17最低目标不代表所有旧系统已实测。真机、审美验收和发行材料中的发布者／Bundle ID占位仍未关闭。

只保存合成测试内容与工程事实；不把凭据、私钥或真实私密记录写入记忆。
