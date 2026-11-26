# 第 27 批「沉浸扉页」原生验收

## App Store 视觉参考

核对加拿大 App Store 的 Do? 版本历史与前六张官方宣传图，参考范围是宣传图内的手机画面。官方图展示的排版可用于对照。双方的主观审美、真实任务耗时和触控反馈仍需分别实测。[Do? 2.0 App Store 页面](https://apps.apple.com/ca/app/do-sex-tracker-period-log/id6757778324)

| 观察到的设计 | 本次对应处理 |
| --- | --- |
| 首页首屏在日期和快捷入口之后露出实际记录，同一组的日期和记录贴近。 [官方画面 01](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/5a/0e/88/5a0e88f8-adf6-be02-7938-f79cd86e736a/01.png/600x1300bb-60.jpg) | 保留暖棕封面，将日期和衬线标题一起左排。缩减装饰使其与标题同排，开始计时、补记和真实内容依次出现。 |
| 成组控件共用一条阅读线，强调色标出当前选择。 [官方画面 02](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource211/v4/a9/2d/3e/a92d3e66-1175-cf20-c986-a83d87abc097/02.png/600x1300bb-60.jpg) | 大字号时间线将类型和收藏并排，搜索范围提示随焦点出现，日期与标签面板在大字号改用短标题。记录数量、清除筛选和首条记录依次出现。 |
| 一个内容区突出一个主题，旁支信息退居次要层级。 [官方画面 06](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource211/v4/be/ca/56/beca5629-07a8-c83e-f844-ee105e8d93ed/06.png/600x1300bb-60.jpg) | 详情按日期、感受、长备注组织，备注下方用细线串联类型、时长、评分与标签。最大字号减少备注左右内边距，留出更多文字宽度。 |

## 原生验收范围

使用既有 `testJournalReadingSample`。在相同 iPhone SE（第 3 代）视口、相同浅色常规字号或深色最大辅助字号、相同合成日记条件下，对照中英文的首页、选中收藏的时间线、同一条长备注详情。候选版补充日期与标签面板原图。首页原图应看清开始计时和补记的优先级。时间线检查回到顶部时首条记录可点，日期与标签面板应显示完整标题，详情应在时长和评分前显示可读的备注。输入专项验证键盘出现后仍显示计数、提交后记录可点、清除时关闭键盘。

同数据基线源码 `79144c0d8a49d44134b3780dcbeda2656fbd4b5c`。[浅色常规](https://github.com/betterfxb/private-moments-ios/actions/runs/45820527119) · [深色最大辅助字号](https://github.com/betterfxb/private-moments-ios/actions/runs/45820527515)

首轮候选源码 `3adf798e64d5ce2942cb3295d2752c436f0be783`。两个配置各通过三个颜色单测和一个双语读写界面用例，四次运行共归档 36 张 750 × 1334 像素原图与校验收据。图组逐屏按 375 × 667 点并排查看。[常规字号前后](evidence/batch-27/compact-light-zh-Hans-comparison.png) · [最大字号前后](evidence/batch-27/compact-dark-accessibility-en-comparison.png) · [英文最大字号筛选原图](evidence/batch-27/45821218697/compact-dark-accessibility/Reading-sample-filters-en.png)

- 浅色中文首页前图只完整显示一条记录，候选首屏完整显示两条。并排后仍见首页记录的玫红强调与时间线暖棕不同，复验版将记录图标、时长和背景收敛到现有暖纸色。
- 深色最大字号时间线中，英文首条标题已出现，但摘要靠近或进入标签栏。中文「全部」和日期各占两行。复验版缩短清除按钮，固定类型选择的自然宽度，将最大字号日期改为紧凑格式，并以 44 点未遮挡的区域和实际点击验证。
- 英文「Filters」在最大字号完整显示，日期范围自然换行。详情在最大字号为长备注减少缩进，复验版去除大尺寸备注标题的装饰图标，保留语义标题和朗读顺序。

首轮[最大字号输入专项](https://github.com/betterfxb/private-moments-ios/actions/runs/45821218156) 的图库和独立搜索在英文搜索提交后都触发同一断言。键盘收起且查询仍在。截图显示完整提示，但 XCTest 无障碍树报告空结果说明从 75.5 点开始，导航底部是 160 点。显示与无障碍范围不一致。提交时移除两行提示是首要疑因，后续修正让提示在整次搜索中保留，离开搜索时再隐藏，日期与标签摘要也避开搜索过程中的重排。复验沿用原有像素边界断言，不在测试中滚动补救。

Windows 工具回归、本地化、工程及差异检查已通过。iOS 17 使用同一 `isSearchPresented` 状态决定是否显示提示。原生复验另记于下。

初版 iOS 17.5 兼容验证 `55a7f1a` 通过 6 个单测和 4 个 UI 用例，发行检查确认无签名 Release 未包含调试钩子。[初版 iOS 17.5 结果](evidence/batch-27/45821741503/ios17/xctest-extract.txt)

## 复验原图

统一源码 `b84dbdc` 的 iOS 26.2 iPhone SE（第 3 代）深色最大辅助字号读写用例和三个颜色单测通过，归档 10 张原图。中文类型和数字日期各占一行，英文原本两行的备注标题现在一行。两种语言的第一条记录都露出至少 44 点高的操作区域，XCTest 点击该区域直接打开详情。时长和评分在深色最大字号仍需向下滚动，可通过屏上首条记录进入详情。原图亦验证两语言的筛选标题完整。[深色最大字号中文前后对照](evidence/batch-27/final-compact-dark-accessibility-zh-Hans-comparison.png) · [英文前后对照](evidence/batch-27/final-compact-dark-accessibility-en-comparison.png) · [原图收据](evidence/batch-27/45825755561/compact-dark-accessibility/screenshots.json)

同一源码的最大字号原生图库和独立键盘用例通过。两种语言均确认计数在键盘上方，提交零结果时提示完整，提交匹配后保持原查询且记录可点，清除时关闭键盘。[XCTest](evidence/batch-27/45825751201/compact-dark-accessibility/xctest-extract.txt)

浅色常规字号的最后回拍 `4009428` 通过同一读写用例与三个颜色单测，归档 10 张原图。中文首屏完整露出两条近期记录，封面、记录、时间线和详情采用同一暖纸色系。Intel 首次回拍在模拟器配置阶段取消，改用 ARM64 通过。`b84dbdc` 与此版的首页、时间线、详情代码相同。[浅色中文前后对照](evidence/batch-27/final-compact-light-zh-Hans-comparison.png) · [英文前后对照](evidence/batch-27/final-compact-light-en-comparison.png) · [原图收据](evidence/batch-27/45830651560/compact-light/screenshots.json)
