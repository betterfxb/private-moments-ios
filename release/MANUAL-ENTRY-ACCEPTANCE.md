# 原生补记与日期查看验收

这是第四批的历史功能验收；后续整体主题与最终源码见[视觉升级验收](VISUAL-UPGRADE-ACCEPTANCE.md)。

## 验证对象

开发分支 `feat/native-manual-entry`，草稿 [PR #1](https://github.com/betterfxb/private-moments-ios/pull/1)。本批不合并主分支，也不视为全局UI方向认可。

最终已验证源码：`b1225b5e065e81a5847c969d68278363780de9bd`；运行 [42801899567](https://github.com/betterfxb/private-moments-ios/actions/runs/42801899567) 四配置全部成功。后续验收文档提交不改变该源码。本批五项任务全部完成，后续真机与全局视觉任务见本文末尾。

## 验收项目

| 项目 | 覆盖方式 | 当前状态 |
|---|---|---|
| 直接补记不启动计时 | 新增原生UI测试与源码路由 | 通过 |
| 默认0时长，用户填写分钟＋秒 | 双语原生补记截图与UI输入 | 通过 |
| 17分9秒保存、重启与再次编辑保持 | 新增原生UI测试 | 通过 |
| 日期／时长变化触发放弃确认 | 草稿单元测试＋修改后取消UI测试 | 通过 |
| 过去日期与按当天查看 | 昨天快捷补记→查看今天为空→恢复最近列表 | 通过；保存后定位实际发生日期 |
| 日期边界 | 东京午夜、洛杉矶23/25小时日的单元测试 | 通过 |
| 输入边界与兼容 | 空值、负值、小数、超大值、秒数、30天上限、未来日期与旧记录 | 通过 |
| 跨设备／外观 | 紧凑浅色、手机深色、iPad浅色、紧凑辅助大字号；中英文 | 四配置自动化通过；重点截图复核通过 |
| 双语与项目结构 | 215键、Xcode成员与发布材料审计 | 本机通过；占位Bundle ID／发行资料警告保留 |

每个UI测试使用独立UUID测试存储，重启场景只复用该测试的ID；不读取、重置或导出用户真实日记。测试数据均为合成数据。

## 最终运行与截图

日志记录的工具链为Xcode 16.4、iPhoneSimulator 18.5 SDK，实际运行环境为iOS 26.2 Simulator；运行时版本不等于编译SDK版本。本批没有补充Xcode 26 SDK矩阵。

| 配置 | 实际设备 | 自动化范围 | 导出PNG |
|---|---|---|---|
| compact-light | iPhone SE（第三代） | Debug／Release编译；30项单元测试、4项UI测试 | 38 |
| compact-dark-accessibility | iPhone SE（第三代），最大辅助字号 | 中英文gallery；日期面板操作与字段边界断言 | 38 |
| phone-dark | iPhone 17 Pro | 中英文gallery | 36 |
| ipad-light | iPad Pro 13-inch（M5） | 中英文gallery | 36 |

148张原始PNG已下载并校验所需名称。针对本批新流程实际打开20张最终源码截图，覆盖补记顶部、分钟／秒、日期面板、按日查看、空状态及辅助字号保存控件；没有声称逐张人工审查全部148张。大字号截图是可滚动页面的选定位置，不能当作整页拼图。已有主题沿用，不据此认定美观度已达到要求。

可追溯记录见 [verification.json](evidence/batch-04/verification.json)；仓库保留三张未经裁切、缩放或改色的原图：[普通中文补记](evidence/batch-04/manual-compact-zh.png)、[辅助字号输入](evidence/batch-04/manual-accessible-zh.png)、[辅助字号日期面板](evidence/batch-04/date-panel-accessible-zh.png)。下载的全量原图、清单和日志位于本地 `build/batch-04-cloud/42801899567/`，云端artifact按现有七天策略保留。

## 证据与结论边界

仅最新源码的完成运行可作最终证据。首轮 `9aed2a7` 的运行42792559771在默认时长复核修正后取消；其Debug／Release编译日志仅作诊断，不是最终验收。

中间版本 `ead99f4` 的运行42793409074：compact-light通过Debug／Release、30项单元与4项UI；phone-dark和ipad-light通过。compact-dark-accessibility失败在返回首页后查找上方开始按钮，日志显示测试只连续向上滑。已修复双向查找，保留16次上限与控件可点击断言；没有跳过该配置或降低字号。修正版本还验证补记保存后定位实际日期，避免旧日期被最近三条列表隐藏。

中间版本 `7163ac3` 的运行42795999800：四配置自动化全部通过，导出146张PNG。但新增界面逐图复核发现中文最大辅助字号下紧凑DatePicker的长日期撑宽整个表单，分钟／秒输入与文字左侧被裁切，因此未通过最终截图验收。已改为大字号图形日历＋时间滚轮，并补充字段边界断言；保留该轮证据，不把自动化成功覆盖视觉缺陷。

中间版本 `1e26492` 的运行42799189531：iPad和手机深色通过，英文辅助字号已通过字段边界检查；中文补记顶部截图确认横向裁切修复，但随后秒输入框仍不可达。纵向内嵌控件存在手势冲突风险，最终收敛为主表单可换行日期入口＋独立日历面板、独立标签的紧凑时间入口。日期面板确认才回写，取消保持；应用失活时关闭自建日期面板。该轮非最终通过证据。

日期筛选依据 [Apple Calendar.dateInterval](https://developer.apple.com/documentation/foundation/calendar/dateinterval(of:for:))，并以小于区间结束时间实现半开日期范围；编辑器使用[系统DatePicker](https://developer.apple.com/documentation/swiftui/datepicker)。不引入固定86400秒日界线，不复制原型固定日期。

仍需后续真机检查：VoiceOver逐项阅读、系统时区切换中的正在编辑草稿、应用锁／文件保护生命周期、硬件键盘与真实保存失败交互。自动化通过不证明触觉、美观度或App Store上线条件满足。
