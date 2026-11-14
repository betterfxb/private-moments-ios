# 第十四批：iPad 小屏与深色最大字号验收

日期：2026-11-14（Asia/Tokyo）。按[计划](BATCH-14-PLAN.md)完成补充配置、防护、串行原生验证及原图检查。本批是明确范围的补充验收，上一批完整四配置回归仍绑定 fb78856 与运行43556512255；本批不重标该历史受测源码。

## 一、改动与架构边界

新增 ipad-mini-light 与 ipad-dark-accessibility，仅显式 input／rotation 模式可选，拒绝 full／backup。mini 只选择固定26.2运行时上真实可用的 iPad mini，缺失时失败，不回退为大屏。CI 根据 iPad 家族选择 iPad 专用方法，默认四配置及其设备选择顺序保留。

11项本地矩阵／工作流实际设备选择测试、243组脚本和24组工作流范围防护、Bash语法、230本地化键、109项目对象和发行审计通过。发布者／Bundle ID占位警告保留。本批补充测试使用Debug独立UUID库；没有签名、Apple上传或main合并。

## 二、实际运行与原图

- [ipad-mini-light / rotation 运行43571193201](https://github.com/betterfxb/private-moments-ios/actions/runs/43571193201)，实际源码 `d1ab55bad08c341d4eadf18d81b63e73b4d2dac0`。
- [ipad-dark-accessibility / rotation 运行43579218909](https://github.com/betterfxb/private-moments-ios/actions/runs/43579218909)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。
- [ipad-light / rotation 运行43580963939](https://github.com/betterfxb/private-moments-ios/actions/runs/43580963939)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。
- [ipad-dark-accessibility / input 运行43583072318](https://github.com/betterfxb/private-moments-ios/actions/runs/43583072318)，实际源码 `c98cfaa37dda32fd8acbb58b8ac96c51409c28c8`。

| 范围 | 实际设备 | UI方法秒数 | PNG下载核验 | 实际打开保留 | 窗口方向核对 | 显示像素尺寸 |
|---|---|---:|---:|---:|---:|---|
| ipad-mini-light / rotation | iPad mini (A17 Pro) | 572.298 | 20 | 20 | 18 | [(1488, 2266), (2266, 1488)] |
| ipad-dark-accessibility / rotation | iPad Pro 13-inch (M5) | 578.361 | 22 | 22 | 18 | [(2064, 2752), (2752, 2064)] |
| ipad-light / rotation | iPad Pro 13-inch (M5) | 570.817 | 22 | 22 | 18 | [(2064, 2752), (2752, 2064)] |
| ipad-dark-accessibility / input | iPad Pro 13-inch (M5) | 918.107 | 60 | 24 | 0 | [(2064, 2752)] |

每项只有1次明确选择的UI方法，无应用单元测试或Release验收；云端plan执行11项工具测试。旋转方法每种语言执行9次实际应用窗口方向检查、正文采集10张原图，并核对3分8秒、两行ASCII合成备注、草稿继续编辑、保存、导航、暂停状态和保存记录重启。新修订另在每种语言创建草稿前激活真实系统Settings应用，独立核对其横屏／竖屏窗口几何并采集1张系统横屏图，恢复本应用前台后才开始草稿；系统参考不能替代原18次应用窗口和内容检查。早期mini仍是20图，新修订旋转是22图，均保留真实源码。UI方法耗时包含自动化、系统查询和截图，不是用户操作响应延迟。

输入图库复用双语真实软件键盘输入、计数器与键盘动作几何、继续编辑后备注保留、取消确认、记录与筛选、保存失败反馈及恢复、设置／锁恢复等现有检查。保存失败是隔离Debug库的一次注入，不是本轮偶然产品故障；图库的备份提示与锁恢复截图不构成真实文件导入导出或认证成功证明。

两种界面语言的备注输入均为ASCII合成文本（例如Test draft／Keep this），旋转使用Rotation draft／Keep every line；原换行完整保留。语言界面与实际软件键盘输入均有检查，但不等同于中文IME组合／候选验收。

合计124张PNG精确核验；88张重点原图实际逐张打开并原字节保留，见[原图](evidence/batch-14/index.html)及[收据](evidence/batch-14/verification.json)。每张来源、设备、原始IHDR、EXIF显示方向、显示尺寸与SHA-256分别记录。原图未裁切或重绘；下载量不等于视觉检查量。关键检出、工具链、模拟器、XCTest日志、manifest及原始层级一起保留。

## 三、失败诊断及修订边界

以下失败不计入上述成功运行的图片数量：

| 失败运行 | 真实源码 | 下载PNG | 实际打开 | 证据 |
|---|---|---:|---:|---|
| [43573470233](https://github.com/betterfxb/private-moments-ios/actions/runs/43573470233) | `d1ab55bad08c341d4eadf18d81b63e73b4d2dac0` | 1 | 1 | [独立收据](evidence/batch-14-failures/43573470233/verification.json) |
| [43575831324](https://github.com/betterfxb/private-moments-ios/actions/runs/43575831324) | `a7675af1c1fc00d6f2a2cf2a782e17e6b70970f4` | 1 | 1 | [独立收据](evidence/batch-14-failures/43575831324/verification.json) |
| [43577972823](https://github.com/betterfxb/private-moments-ios/actions/runs/43577972823) | `47c5a25f82d7ef8ecf4176bae0ffbae9fbbf75cc` | 3 | 3 | [独立收据](evidence/batch-14-failures/43577972823/verification.json) |

早期深色最大字号运行43573470233（源码d1ab55b）整体失败，UI方法125.160秒；第一种语言的键盘已收起，3分8秒／两行备注存在，但请求横屏后20秒实际应用窗口仍1032×1376 pt。物理原图（2064×2752、EXIF1）及应用层级均为竖屏，已实际打开并保留于[失败收据](evidence/batch-14-failures/43573470233/verification.json)。该运行只有1次初始方向检查、1张失败现场原图，没有完成整个双语旋转流程，不计成功截图数量。

第二次运行43575831324（源码a7675af）在45.871秒的系统控件前置检查失败，未进入原旋转流程。实际打开的1张物理原图与SpringBoard层级显示控制中心已打开，但控制区为空，没有旋转锁；证据见[第二次失败收据](evidence/batch-14-failures/43575831324/verification.json)。该环境不满足“必须读取旋转锁”的假设，因此后续将不可读状态明确记为unknown，保留系统原图后继续真正的窗口验收；未放宽应用窗口或内容断言。

第三次运行43577972823（源码47c5a25）在129.458秒未达到首个草稿横屏；请求与实际设备方向均为3、应用state为4（前台），实际窗口仍1032×1376 pt。3张物理原图均实际打开并独立保留，控制中心仍为空，两行草稿与计数30可见；没有把未知控制状态当成解锁成功。仅靠这次结果仍不能区分应用能力与整个模拟器旋转环境。

最终局部修订用真实系统Settings横竖屏对照替换无可读控件的控制中心前置；不更改系统设置或生产应用。原18次应用窗口检查及20秒期限不变，不把设备方向赋值或系统参考通过视为产品成功。新增编译后Info.plist方向元数据记录、失败时实际设备方向／应用状态／系统层级，补默认ipad-light旋转回归。缺省方向键不能独立证明旧失败根因，不能仅凭后续结果将旧失败归因于系统锁、字体、产品或偶发。

Apple的[UIApplication默认方向说明](https://developer.apple.com/documentation/uikit/uiapplication/supportedinterfaceorientations(for:))指出，缺少UISupportedInterfaceOrientations时iPad默认返回全部方向，因此不能将缺省键等同于应用仅支持竖屏。源码／项目未发现显式方向覆盖；实际界面仍须测量，未据此猜测性修改生产Info.plist。

## 四、分屏与下一步

小屏全窗口与旋转不能证明系统分屏／窗口缩放。后续须通过真实系统窗口操作，记录应用实际窗口几何、窄／中／宽状态、缩放期间草稿／导航／暂停连续性、键盘和安全区域。具体协议与Apple原始依据见本批计划；没有使用私有API或生产调试入口伪造窗口变化。

第三次失败的SpringBoard层级已观察到Other类型的resize-grabber（Resize Private Moments／Bottom Right），可作为下一步系统窗口验证的线索；本批未操作它，未证明其可见、可命中或实际能改变窗口尺寸。

本批旋转均为键盘已收起、完整窗口；最终深色／默认iPad通过均包含先运行真实Settings横竖屏参考的前置条件，不能据此宣称未经该前置的深色最大字号冷启动首转问题已关闭，仍需在可观测系统环境独立复核。未保存草稿／活动计时的系统终止恢复、组合输入中旋转、多窗口、其他运行时、真机IME／VoiceOver／Switch Control、认证成功／待决取消与锁屏文件保护仍未验收。居中限宽布局、宽屏留白和视觉质感仍需独立设计迭代，功能证据不等于用户审美认可或已超越DO。

mini原图显示双语备注和时长保持，原生继续编辑／放弃确认两项可见；长表单截图处于正常滚动位置，顶部部分字段会经过系统导航栏的模糊区域，不能声称整张表单同屏显示。mini横屏中文Timeline的搜索提示仍省略显示，记录条目与返回断言通过；该文案显示问题保留为后续体验改进项。

最终深色最大字号及默认浅色Large的大屏原图，双语3分8秒／两行备注、继续编辑与放弃确认、暂停页继续／结束控件均有可读现场；Settings显示1条已保存记录。浅色配置的计时页沿用专用暗色样式，不应解释为系统外观设置未生效。深色最大字号时间线的中英文搜索提示均省略，默认浅色中文也有省略；宽屏居中限宽留下较多空白，均列入后续体验／视觉改进，未以功能通过作审美背书。

最终输入图库的24张重点原图显示：双语两行Test draft／Keep this及20字符计数在键盘显示、收起及继续编辑后保留，备注输入框、计数器及收起键盘操作同屏可见；原生保存失败反馈的重新读取／继续编辑两项均可见，滚动后的保存、详情编辑／删除和设置底部操作可达。评分在最大字号下正常换为两行，英文标签纵排、中文标签横排；长表单和部分内联错误文案需要继续滚动才能完整阅读，不能将局部截图称为全文同屏。锁恢复图中Off／关闭及系统Settings返回标记可见，只支持当前测试的往返恢复检查，不支持真实认证成功结论。输入图库的时间线为1条记录，中英文搜索提示仍省略。

后续顺序：先独立复核未经系统参考前置的深色最大字号冷启动首转，再建立可复现的系统窗口缩放验证，明确未保存草稿及计时的终止恢复产品策略并实现，最后建立大数据性能基线。[项目记忆](../PROJECT-MEMORY.md)保留每次真实源码、运行与边界，避免重复执行未受影响的历史测试。
