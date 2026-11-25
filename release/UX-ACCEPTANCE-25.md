# Private Moments 第二十五批原生功能与验收

## 实施顺序与可观察结果

| 顺序 | 改动 | 需要验证 |
| --- | --- | --- |
| 1 | 时间线增加日期范围和单标签筛选。可与关键词、记录类型及收藏一起使用，原生表单在确认后应用筛选。 | 起止日均包含，结束日后的零点排除。交叉条件能找对记录。从详情返回保留筛选，全部清除可恢复原列表。被编辑或删除的记录按最新数据重新计算。无结果时显示可操作的清除入口。 |
| 2 | 收藏详情增加「再记一次」。新表单带入原记录类型和标签，时间默认为当前时间，初始时长为零。 | 备注为空，可重新填写。取消未修改表单后回到原详情。明确保存才生成新记录。继续沿用本机草稿冲突处理与恢复，原记录可回读。 |
| 3 | 「回顾」的月份页汇总当月收藏及重复出现的并列常见感受，可按项目找到来源记录。 | 月份切换和详情返回状态正确，满足条件的实际记录才会出现。月份边界和删除后的结果准确。单条记录可以形成收藏入口，单次感受不列入常见感受。 |

本批消费既有已保存记录，数据格式沿用 SwiftData V2 和现有 JSON。搜索仍使用已实现的日期、类型、感受和标签文本匹配。月度精选在月视图可访问，周回顾仍由原入口提供。

## 验收入口

`journal_features_smoke` 可以独立检验三项原生操作。完整矩阵把这些用例放在常规小屏和深色最大辅助字号的 `journal-features` 作业。既有图库、回顾与草稿、系统文件及无签名核心构建各自保留。待核对同一提交下的新单元测试、两套环境的截图和 XCTest 结果。

两个定向运行使用相同的 `6f83cb739f487c5b5f7b6f0c599f585a2af1ad5d`。GitHub 已通过计划作业并分配设备配置。原生作业结果待查。[常规小屏](https://github.com/betterfxb/private-moments-ios/actions/runs/45626995515) · [深色最大辅助字号](https://github.com/betterfxb/private-moments-ios/actions/runs/45626988045)

Windows 已通过 53 项工具测试、Bash 脚本语法、本地化 281 键、Xcode 项目 113 对象、发行材料和 Git 差异检查。Windows 上的检查覆盖工程配置、测试选择及资源完整性。原生编译、交互及视觉结果按 GitHub Actions 的实际结果另行记录。

### 两套配置首轮及修订

`6f83cb7` 在常规小屏和深色最大字号下均通过全部 11 项日期和周期单测。「再记一次」及月度精选的原生用例也通过。两套配置的日期组合用例均出现同一现象，选中标签后得到一条记录，点按原生日期开关再应用时仍是一条，未得到所选日期应有的空结果。`7046aa0` 将日期范围改为完整一行可点的明确动作，并在测试中确认真实的日期字段已出现后才应用，同时验证详情返回保留搜索词。已请求两套同源码复验。Windows 54 项工具测试、本地化 282 键和工程审计通过。[常规首轮](evidence/batch-25/45626995515/compact-light/xctest-extract.txt) · [最大字号首轮](evidence/batch-25/45626988045/compact-dark-accessibility/xctest-extract.txt) · [月度精选原图](evidence/batch-25/45626988045/compact-dark-accessibility/Month-highlights-zh-Hans.png) · [常规复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45644956312) · [最大字号复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45643950202)

`7046aa0` 在常规小屏实拍可打开日期字段，并与标签、收藏、搜索组合得到预期的零条结果。随后取消已选日期范围时，两套配置的 XCTest 均记录应用进程退出。`1008cac` 让表单日期字段持续绑定到独立的非空状态，由单独开关控制是否将日期应用到列表，测试增加取消范围后应用仍可操作的断言。已用包含修正的 `aca682a` 请求两套定向复验。请求一度遇到 GitHub Actions 返回 HTTP 500，两套重试均被接受。[日期字段实拍](evidence/batch-25/45644956312/compact-light/Timeline-date-range-en.png) · [无结果实拍](evidence/batch-25/45644956312/compact-light/Timeline-range-empty-en.png) · [常规失败位置](evidence/batch-25/45644956312/compact-light/xctest-extract.txt) · [最大字号失败位置](evidence/batch-25/45643950202/compact-dark-accessibility-journal-features/xctest-extract.txt) · [常规小屏复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45650755597) · [最大字号复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45650798278) · [GitHub 状态](https://www.githubstatus.com/incidents/qn8mfv6q5hlx)

`aca682a` 在深色最大辅助字号通过 11 项单测及 3 个原生功能用例，包括两种语言的日期移除、组合筛选及详情往返。原图另显示系统紧凑日期字段的标签和日期被左右裁切。`c260b35` 在辅助字号将标签和完整日期改为可换行的独立行，沿用补记使用的系统日历样式。日历取消不改变日期，确认写入当前起止字段，筛选仍由表单确认应用。新增两种语言的日期行可点、语义有值、日历可打开及取消保留选择的验收。原生复验已触发。[原生回归结果](evidence/batch-25/45650798278/compact-dark-accessibility/xctest-extract.txt) · [裁切实拍](evidence/batch-25/45650798278/compact-dark-accessibility/Timeline-date-range-zh-Hans.png) · [日历复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45655196061)

`aca682a` 在常规小屏也通过相同的 11 项单测和 3 个原生用例。已保存 7 张实拍，包含两种语言的日期范围与无结果，以及「再记一次」和月度精选。两套 `aca682a` 的功能证据与后续日期裁切修复分别记录。[常规小屏 XCTest](evidence/batch-25/45650755597/compact-light-journal-features/xctest-extract.txt) · [原图收据](evidence/batch-25/45650755597/compact-light-journal-features/screenshots.json)

`c260b35` 的常规小屏复验通过 11 项单测和 3 个原生功能用例，中英文继续使用紧凑日期选择器。归档 7 张日期、无结果、再记及月度精选原图。[常规小屏 XCTest](evidence/batch-25/45655726442/compact-light/xctest-extract.txt) · [截图收据](evidence/batch-25/45655726442/compact-light/screenshots.json) · [云端运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45655726442)

`c260b35` 的 Intel 最大字号作业构建成功并通过 11 项单测。UI 测试启动器在首个用例之前因 `Timed out waiting for AX loaded notification` 退出。`e30269d` 仅追加验收记录和原图，已使用相同应用与测试代码改走 ARM64。[Intel 运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45655196061/job/139350231940) · [ARM64 重试](https://github.com/betterfxb/private-moments-ios/actions/runs/45661989166)

ARM64 重试通过 11 项单测和 3 个原生功能用例。中英文最大字号的日期字段按完整日期换行，两个输入行均通过可点和无横向越界断言。打开系统日历并取消后保留原日期。已归档 9 张原图。英文「Dates and tags」在最窄最大字号顶栏仍会截短，日期值可逐行完整阅读。[通过日志](evidence/batch-25/45661989166/compact-dark-accessibility/xctest-extract.txt) · [中文日期范围](evidence/batch-25/45661989166/compact-dark-accessibility/Timeline-date-range-zh-Hans.png) · [中文原生日历](evidence/batch-25/45661989166/compact-dark-accessibility/Timeline-date-calendar-zh-Hans.png) · [英文日期范围](evidence/batch-25/45661989166/compact-dark-accessibility/Timeline-date-range-en.png)

`9880cb3` 调整最大字号的时间线搜索说明后，重新通过 11 项单测及三项原生功能用例。[最新最大字号回归](evidence/batch-25/45679021708/compact-dark-accessibility/xctest-extract.txt)
