# Private Moments 项目记忆

更新日期：2026-11-15（Asia/Tokyo）。这是可随仓库迁移的工程记忆；验收事实以对应源码、原始运行及证据收据为准，不能以文档最新提交替代受测源码。

## 项目与约束

- 工作目录：`D:\find_project\ios\PrivateMoments`。仓库：https://github.com/betterfxb/private-moments-ios 。现有分支：`feat/native-manual-entry`；[PR #1](https://github.com/betterfxb/private-moments-ios/pull/1)保持草稿。
- 用户在Windows开发，SwiftUI／SwiftData原生编译和XCTest由GitHub托管macOS执行；本地静态检查不能替代原生运行。
- 用户已说明尚无付费Apple Developer账号，优先继续开发。不得将无签名归档称为可安装或TestFlight成功；实际签名、上传和main合并尚未执行。
- `design/`是既有未跟踪目录，保留原状，不纳入批量暂存。代码提交、证据、文档应显式选择路径。
- 用户重视温馨感、视觉质感和真实操作体验，曾多次否定旧视觉方案。当前语义Rose体系的功能验收不等于审美认可，也不能据此宣称已超越DO。

## 架构与数据边界

- RootView持有MomentStore、SessionClock、Today／Timeline独立导航路径和选中标签；RecapView保存表单草稿，持久化只在明确保存时完成。
- SwiftData本机数据、显式schema V1、禁止托管CloudKit同步；JSON备份是用户主动导出，包含备注且未加密。不要把“本机优先”解释成已实现云同步或跨设备服务。
- 界面支持English和简体中文，跟随iOS应用语言；记录枚举保持稳定，用户备注不自动翻译。字符串目录231键，现有项目静态审计109对象。
- Debug UI测试使用每次独立UUID库，不重置正常日记；Release排除测试钩子。认证使用真实系统流程，不增加成功绕过路径。

## 第十七批执行中

用户优先要求解决大字体键盘遮挡和长提示滚动负担，按[计划](release/BATCH-17-PLAN.md)串行执行。修订前dfcb8f2a的输入43703852664（72核验／14实际打开）、英文文件43708031913和中文文件43710410554（各10／10）已成功，均实际验收后才进入首次完整43713613425。该完整最终失败：主配置英文系统白色导出面板90秒未就绪、清筛选后键盘仍exists；iPad全页已容纳却被错误要求提示滚出窗口，原生Clear text后失焦造成输入失败。291张核验／3张实际打开及411附件独立封存，不能拼接phone-dark和最大字号配置的局部成功。五次更早输入失败同样保留。

新增修订限于Timeline清除时显式释放搜索焦点，及测试中清除后原生空栏稳定再点入、真实收键盘等待、iPad全消息及全部备份／删除动作已完整同屏时独立几何验收；手机三次内滚离和完整数据断言不减。文件提供方原因未证明，90秒、无预热和真实Save保持。新源码须重新依次完成iPad双语输入→iPad英文文件→SE最大字号双语输入→英文文件→中文文件→完整四配置，再更新最终证据与记忆。修订前成功不冒充新源码验证；最近完整仍为第十六批。43工具及231键／109对象／发行审计通过，原有占位警告保留。

## 最近完整四配置验收（第十六批）

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
- 第十五批补齐指定26.2云端独立英文／中文冷启动旋转；旧失败根因及其他环境稳定性仍未证明。下一步建立实际系统窗口缩放证据，明确终止后的草稿／计时恢复策略，再推进性能与真机验证。产品恢复策略不能由测试脚本擅自假定。
- 中文IME组合与候选、VoiceOver／Switch Control、成功Face ID／Touch ID及待决认证取消、锁屏文件保护、外接／浮动键盘和外部文件提供方仍需相应设备或环境。
- 当前只验证固定Xcode／SDK／Simulator26.2；iOS17最低目标不代表所有旧系统已实测。真机、审美验收和发行材料中的发布者／Bundle ID占位仍未关闭。

只保存合成测试内容与工程事实；不把凭据、私钥或真实私密记录写入记忆。
