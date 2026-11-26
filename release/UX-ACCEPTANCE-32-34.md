# 第 32–34 批 日记操作与原生验收

以「沉浸扉页」和现有日记设计令牌为依据。各批先完成范围内的原生检查，再进入下一批。合成记录由 Debug 隔离数据目录创建，证据注明源码、配置、系统和结果。

| 顺序 | 目标与范围 | 通过条件 |
| --- | --- | --- |
| 32 | 从首页快记到保存、补标签、时间线找回与月历回顾。保留计时、完整补记和独立导航。 | 用同一用例和代表性记录，从首页到月历逐步运行。在 iPhone 小屏的常规及最大字号下核对中英文原图，同一条记录能找回，时间线搜索与月历日期往返保持。 |
| 33 | 在现有日期与标签筛选内选择多个标签，支持任一或全部，单独移除条件。 | 原生流程验证任一／全部、单独移除、取消、详情返回、与日期／收藏／搜索叠加及零结果。单测覆盖旧标签拼法和空选择。 |
| 34 | 验证第 32–33 批功能在 iPad 横屏及实际窄窗口内的使用情况。 | 验证输入、保存、返回及所选日期不中断。窗口宽度以系统拖动前后的实际尺寸记录，分开保存横屏和窄窗口原图。 |

第 30 批加密备份和计时恢复的产品策略仍待确认。第 31 批继续依赖可安装构建和真机。真机输入法、VoiceOver、锁屏认证和 Files 的验收在对应设备执行。[待确认事项](DEVICE-AND-RECOVERY-DECISIONS.md)

## 第 32 批 原生基线与回拍

基线 `e4b813b` 仅增加测试和测试选择。流程依次截取首页入口、快记、保存后的详情、标签输入、时间线匹配、月历及当日记录。候选版使用相同任务、视口和合成标签。两次执行的时钟显示允许有差异。

常规字号 iPhone SE 第 3 代，375 × 667 点，浅色。基线通过三个颜色检查及两个原生用例，包含中英文完整旅程。实际看到首页快记仅显示一个加号，快记的类型控件缺少可见标签，保存进入详情后需要找通用编辑按钮并滚到标签区。时间线结果不露出使其匹配的标签。月历的日期和计数可扫读，选日后月度分布仍出现在当天记录之前。[基线原图收据](evidence/batch-32/45845148576/compact-light/screenshots.json) · [基线 XCTest](evidence/batch-32/45845148576/compact-light/xctest-extract.txt)

深色最大字号基线也通过同一组单测和原生流程。原图显示英文默认值说明占多行，长表单上的标签输入需要先滚动。首轮候选补了明确的保存反馈、直达标签页面和搜索匹配标签。浅色首页回拍发现系统按钮的浅底压低了快捷文字对比，标签输入时下方保存按钮部分落入键盘工具栏。改用由应用绘制的深底按钮，核对暖色按钮的文本对比，缩短默认值说明，并在输入标签时使用仍可见的顶部保存和键盘动作。[最大字号基线原图收据](evidence/batch-32/45845144867/compact-dark-accessibility/screenshots.json) · [首轮浅色实拍](evidence/batch-32/45848585164/compact-light/Journal-journey-01-home-zh-Hans.png)

第二轮候选两个配置各通过三项颜色检查和两个原生用例。对照原图确认最大字号的英文默认值已缩为两行，键盘上的添加与顶部保存都清楚可见。首页导航栏仍把快记文字压成省略号，因此把快记移到封面主操作下方，与补记并排。辅助字号将二者纵排，让完整文字在系统字号下换行。最后一轮继续核对两个配置的原图。[浅色截字证据](evidence/batch-32/45852029494/compact-light/Journal-journey-01-home-en.png) · [最大字号截字证据](evidence/batch-32/45852021693/compact-dark-accessibility/Journal-journey-01-home-zh-Hans.png)

最终源码 `e86b051` 在 iPhone SE（第 3 代）两种配置各通过三项颜色单测和两个原生用例，归档 28 张终稿原图。首屏快记名称完整可见和可点，两种语言均能直接补标签。搜索结果显示命中的标签，选日后直接浏览当天记录，进出详情保留搜索词和所选日期。最大字号英文补记的第二行、部分记录元数据和完整长搜索词需要继续滚动或进入输入状态，原生回拍保留了这些边界。日期选择用原生列表承载辅助字号。

- 浅色常规字号的[中文操作对照](evidence/batch-32/compact-light-zh-Hans-capture-comparison.png)、[中文找回对照](evidence/batch-32/compact-light-zh-Hans-retrieval-comparison.png)、[英文操作对照](evidence/batch-32/compact-light-en-capture-comparison.png)、[英文找回对照](evidence/batch-32/compact-light-en-retrieval-comparison.png)与[云端结果](https://github.com/betterfxb/private-moments-ios/actions/runs/45855031957)。
- 深色最大辅助字号的[中文操作对照](evidence/batch-32/compact-dark-accessibility-zh-Hans-capture-comparison.png)、[中文找回对照](evidence/batch-32/compact-dark-accessibility-zh-Hans-retrieval-comparison.png)、[英文操作对照](evidence/batch-32/compact-dark-accessibility-en-capture-comparison.png)、[英文找回对照](evidence/batch-32/compact-dark-accessibility-en-retrieval-comparison.png)与[云端结果](https://github.com/betterfxb/private-moments-ios/actions/runs/45855029964)。

## 第 33 批 时间线多标签筛选

基线 `1208ee2` 先执行新行为用例。15 项旧单测正常通过，原生流程打开单选菜单后，因找不到多选匹配方式而按预期失败。[旧界面原生截图](evidence/batch-33/45858779331/compact-light-timeline-tags/Tag-filter-multiple-options-unavailable-en.png) · [失败断言](evidence/batch-33/45858779331/compact-light-timeline-tags/xctest-extract.txt) · [云端作业](https://github.com/betterfxb/private-moments-ios/actions/runs/45858779331)

「日期和标签」下进入专用标签列表。默认匹配全部，可切换为匹配任一，点选或逐项取消。返回筛选面板后，点完成应用草稿，点取消回到此前条件。日期、记录类型、收藏和文本条件独立叠加。保存的旧标签仍按既有首尾空白与大小写归一规则查询，重音差异和原始拼写继续保留。标签筛选使用当前时间线的内存状态。

首次最大字号复验中，已选两项可从原图核对，重新打开列表时底部行需要滚入视口后才进入 XCTest 快照。复验逐行滚入并读取实际选中状态，取消回滚仍需独立验证。同一截图见到随字号放大的勾选符挤占文字空间，候选把勾选图标限制为 22 点并沿用暖纸色，文字继续跟随系统字号。[最大字号首轮原图](evidence/batch-33/45860474192/compact-dark-accessibility-timeline-tags/Tag-filter-options-en.png)

首轮普通字号中，原生搜索展开会让导航栏专注搜索框。验收改为先在普通导航中走详情往返和取消，再叠加收藏、类型和搜索，核对详情返回仍保留查询。[普通字号首轮日志](evidence/batch-33/45860474167/compact-light-timeline-tags/xctest-extract.txt)

最终源码 `cd62619` 两个配置各通过 16 项日期与标签单测及 1 个双语原生用例，共归档 18 张终稿原图。两条不同标签的记录在「任一」下全显示，在「全部」下显示零结果，并给出调整条件的提示。逐项去除、取消、详情返回、系统日期选择器和其他条件叠加均通过。英文最大字号标签可完整显示，中文较长的匹配方式支持换行和滚动。[普通字号选项](evidence/batch-33/45863088523/compact-light-timeline-tags/Tag-filter-options-zh-Hans.png) · [普通字号结果](https://github.com/betterfxb/private-moments-ios/actions/runs/45863088523) · [最大字号选项](evidence/batch-33/45863092123/compact-dark-accessibility-timeline-tags/Tag-filter-options-en.png) · [最大字号结果](https://github.com/betterfxb/private-moments-ios/actions/runs/45863092123)

## 第 34 批 iPad 横屏与窄窗口

在 iPadOS 的 Windowed Apps 模式下执行。先全宽横屏完成快记并进入标签编辑，再切回竖屏。用系统窗口拖柄缩到中等宽度、输入标签，并在键盘可见时进一步缩窄。继续用时间线和月历打开同一记录，在详情中重新扩大窗口并返回当日列表。以 XCTest 的窗口绝对尺寸、原图和真实点按结果验收。
