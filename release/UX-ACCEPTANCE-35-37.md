# 第 35–37 批 时间线筛选与月历查找

起点为 `f51e90d`。延续「沉浸扉页」和现有暖纸色。按下表顺序在原生流程验收后推进，设备使用 GitHub 托管模拟器。

| 批次 | 目标和范围 | 依赖 | 验收标准 |
| --- | --- | --- | --- |
| 35 | 在时间线搜索结果旁提供日期和标签入口，复用现有筛选面板。 | 第 33 批的多标签草稿、日期与标签组合筛选，以及原生搜索提交。 | iPhone 两种字号和中英文均可带着原词打开面板。应用筛选能把一条命中变成零条，取消可保留筛选，解除冲突后恢复同一记录，返回详情保留查询。对照实际截图核查阅读层级、触达和零结果。 |
| 36 | 最大辅助字号的月历选日优先列出有记录的日期，提供全部日期切换，节省逐日滚动。 | 第 35 批验收和第 29 批现有月历计数、按日浏览及删除后的更新。 | 深色最大字号双语流程验证日期可直接找到，无记录月可恢复到完整日期。切换后能查看空白日期，删除一条记录后数量正确。常规字号月历网格通过回归。 |
| 37 | 对两批功能做适配与集成回归，归档原生截图、运行日志和项目记忆。 | 第 35–36 批分别通过。 | 同一源码在现代模拟器通过综合日记测试与 iPad 系统窗口回归，实际 iOS 17.5 运行可覆盖新搜索筛选和现有日记路径。本地工具、本地化和工程检查通过。 |

两处界面沿用原生导航、既有字阶、语义颜色和 44 点触控目标。搜索结果保留计数与清除的阅读次序，历史筛选入口留在原有位置。大字号选日用紧凑的切换控件和完整日期文本，避免硬缩字体。

明文导出、口令遗失、进程终止后的计时恢复和可安装真机路径仍需产品确认。真机旁白、外接键盘、真实中文输入与签名测试按现有清单执行。[待确认事项](DEVICE-AND-RECOVERY-DECISIONS.md)

## 第 35 批 时间线搜索中的筛选

旧版 `24d3abc` 先跑新增原生断言。输入并提交 `Happy` 后能找到目标记录，但搜索结果内没有能保留查询的日期与标签入口，断言按预期失败。[原生基线](https://github.com/betterfxb/private-moments-ios/actions/runs/45981730621)

候选复用日期和标签面板。普通字号用文字和图标，辅助字号保留 44 点图标按钮及完整辅助名称。打开面板时只收起键盘，应用和取消沿用原有草稿语义。

首轮 `300a191` 两配置各通过 16 项单测和 1 个双语原生用例。浅色能看见完整的入口名称，零结果仍可修改条件。最大字号的系统图标放大到与清除文字接近，容易被读成清除按钮的一部分。复验把图标限制为 20 点并给它独立的触控背景，保留 44 点点击面积。[基线断言](evidence/batch-35/45981730621/compact-light-timeline-tags/xctest-extract.txt) · [首次最大字号回拍](evidence/batch-35/45984227605/compact-dark-accessibility-timeline-tags/Tag-filter-search-entry-en.png)

最大字号终稿 `13846be` 通过 16 项单测及同一双语原生用例。计数与两个独立动作能同时显示。零结果时仍可回到筛选，恢复同一条记录并保持搜索词。小屏最大字号的系统搜索输入会截省显示，原值由测试读取核对。[常规字号原图](evidence/batch-35/45984227607/compact-light-timeline-tags/Tag-filter-search-entry-zh-Hans.png) · [常规字号云端结果](https://github.com/betterfxb/private-moments-ios/actions/runs/45984227607) · [最大字号原图](evidence/batch-35/45993857517/compact-dark-accessibility-timeline-tags/Tag-filter-search-conflict-zh-Hans.png) · [最大字号终稿运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45993857517)

## 第 36 批 大字号月历选日

使用同一月历夹具检查有记录、空白日期和整月无记录三种状态。大字号打开选日时先看到有记录的日子；需要查看空白日时用固定在列表上方的切换动作。若从已选中的空白日期重新打开，直接显示全部日期与当前选择。普通字号继续使用已有月历网格。定向验收复用现有 CI，按需重复月历用例和日期单测。

基线 `5d0f442` 的 12 项日期单测通过，大字号原生测试找不到有记录日期与全部日期的切换入口，按预期失败。[基线实拍](evidence/batch-36/45997299126/compact-dark-accessibility-review-calendar/Month-calendar-recorded-days-missing-en.png) · [基线日志](evidence/batch-36/45997299126/compact-dark-accessibility-review-calendar/xctest-extract.txt)

候选 `d0a5b23` 常规字号通过，大字号能打开有记录日期列表，但首轮复测点切换后仍读到旧操作名称。将切换按钮置于滚动容器上方的独立布局，复验要求只点一次，等待真实标签更新并检查日期行变化。[首轮大字号日志](evidence/batch-36/45998876369/compact-dark-accessibility-review-calendar/xctest-extract.txt)

终稿 `2516601` 的最大字号通过 12 项单测和 1 个双语原生用例。原图同时覆盖有记录日期、全部日期、无记录的当日和无记录的整月。删除一条后日期计数从 2 变为 1，重新打开已选空白日期时正确保留选择；整月无记录时仍可切换到全部日期。常规字号的网格通过同一套日期单测和原生回归。[常规字号作业](https://github.com/betterfxb/private-moments-ios/actions/runs/45998876261) · [最大字号作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46000820677) · [有记录日期](evidence/batch-36/46000820677/compact-dark-accessibility-review-calendar/Month-calendar-zh-Hans.png) · [全部日期](evidence/batch-36/46000820677/compact-dark-accessibility-review-calendar/Month-calendar-all-dates-en.png) · [整月无记录](evidence/batch-36/46000820677/compact-dark-accessibility-review-calendar/Month-calendar-no-recorded-dates-zh-Hans.png)

## 第 37 批 集成回归

在同一源码上执行四个云端范围。iPhone 常规字体验证已有日记功能组合，最大辅助字号复验键盘输入和搜索布局，iPad 用系统窗口拖动验证跨快记到日期选择的状态，iOS 17.5 兼容范围加入同一套搜索与日期标签验收。兼容作业同时检查无签名 Release 和最低部署目标。

扩大回归后，源码 `48acf7d` 的英文小屏最大字号首页发现补记按钮延伸到 651 点，底部标签栏开始遮挡的位置为 584 点。改用单行可见文案 `Add past`，保留完整的辅助功能名称并压缩次操作的上下内边距。验收增加三个首页入口均完整可见的检查。同一轮 iPad XCTest 请求横屏后系统方向值已改变，应用窗口仍为 1032 × 1376 点，未开始窗口业务流程。复验复用已有的系统设置横竖屏参照，再按应用真实宽度和实际拖动验收。[首页回归日志](evidence/batch-37/46004493153/compact-dark-accessibility/xctest-extract.txt) · [iPad 首轮失败](https://github.com/betterfxb/private-moments-ios/actions/runs/46004498147)

源码 `113e204` 已通过英文首页三个操作的首屏几何断言，并通过独立的双语搜索布局用例。图库随后在滚动打开「本周」时未获得可点的日期行。图库验收改为先让本周入口的完整触控区域露出并稳定，再点按一次，滚动检查原生菜单内的日期。首页首屏几何断言继续执行。[首屏通过后图库失败作业](https://github.com/betterfxb/private-moments-ios/actions/runs/46007718654)
