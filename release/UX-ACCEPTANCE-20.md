# Private Moments 第二十批验收

2026-11-23，Asia/Tokyo。这一批围绕首页对照、千条记录搜索测量和旧系统兼容执行。自动化读写使用隔离的合成日记。

三项模拟器与本地验收依次完成。iOS／iPadOS 26.2 四配置通过，实际 iOS 17.5 的两个定向用例通过。受测源码与证据分别列在每项中。真机项目有独立中英双语清单。

| 顺序 | 范围 | 验收条件 |
| --- | --- | --- |
| 1 | 用当前选定的「沉浸扉页」核对原生首页 | 对齐设备宽度、语言、外观及记录状态。检查连续暖色、标题层级、主次入口和最近记录。原生最大字号另行验收。 |
| 2 | 定位 1,000 条记录时的搜索与滚动耗时 | 复用原来的合成数据和实际键盘。分别测量应用接收输入、结果行布局、显示刷新回调与实际滚动，保持原有查询正确性。 |
| 3 | 验证 iOS 17.x 旧运行时路径 | 查云端库存。具备系统运行时才执行真实搜索提交、收起键盘和补记保存返回。记录实际运行时与覆盖结果。 |

## 1 · 原生首页与「沉浸扉页」

原型首屏面向准备开始记录的人，以两行题句、暖色叠形、浅杏主按钮构成中心阅读轴。原生首页把产品名作为标题，同一题句作为副标题，保留独立的「开始记录」和「补记」。原生还提供日期选择、已保存计数和可点击的原生历史行。对照的两项具体取舍是保持中央标题和主按钮的轴线，以及让「补记」占独立触控行且与主动作有清晰权重差。

Playwright 实际运行用户选定的原始 HTML，在 393 点和 375 点宽渲染中文空态及有记录状态。用原型的轮播进入「沉浸扉页」，在 393 点通过「开始记录 → 结束并丢弃 → 确认丢弃 → 返回原型首页」。保留 667 点窄屏首屏预览及完整滚动内容，原型按钮的本地几何为距顶部约 436 点、高 53 点。原型没有补记入口，也没有 iOS Dynamic Type，日期和演示内容是固定样例。

375 × 667 点浅色的原生基线提前约 135 点展示「开始记录」，补记紧随其后，最近记录区约在 414 点进入画面。原型的双行题句和较大留白更有封面感，简化标题和提前入口有利于原生窄屏中的快速记录。空态和有记录分别对照，两个版本的样本日期与记录内容有差别。原生安装状态、系统导航栏和状态栏使用各自平台组件。

查看 iPhone SE（第三代）中文版原生基线时，导航与内容交界处可见横贯全宽的台阶，中央装饰的实色重叠与粗描边削弱了原型里的光泽。局部修订让原生导航底色进入封面渐变，沿用暖色令牌给叠形增加内部亮面与更细的边缘。标题、入口位置和空态结构沿用原生基线；可访问字号保留短日期、主次入口和可滚动记录区。

**视觉复验通过。** 浅色窄屏同一位置的 RGB 距离由 32.16 降至 0，深色最大字号由 13.64 降至 1。采样点避开文字和控件。深色 402 × 874 点 iPhone 17 Pro 同样可见柔和过渡和内部亮面。保存的 393 点原型图与该设备有 9 点宽度差。最大字号比较使用原生前后两列，原型列保留其普通字号作方向参考。 [浅色空态三列对照](evidence/batch-20/45165361425/comparisons/comparison-compact-light-empty.png) · [浅色有记录三列对照](evidence/batch-20/45165361425/comparisons/comparison-compact-light-records.png) · [最大字号三列对照](evidence/batch-20/45165361425/comparisons/comparison-compact-dark-accessibility-empty.png) · [深色常规三列对照](evidence/batch-20/45165361425/comparisons/comparison-phone-dark-empty.png)

**原生功能复验通过。** `bash scripts/verify-mac.sh` 在 Xcode 26.2、iOS／iPadOS 26.2 上通过四配置、54 项应用单元、20 次 UI、无签名 Debug／Release 构建及 Release 测试钩子排除。简体中文和英文图库验证两个首页入口的可点击几何及真实目的地。基线取自上一轮已验证的原生截图，同当前改动前源码一致；本轮仅基线运行在选定该证据后取消，正式修订版四配置完成。 [基线 44760783402](https://github.com/betterfxb/private-moments-ios/actions/runs/44760783402) · [修订版 45165361425](https://github.com/betterfxb/private-moments-ios/actions/runs/45165361425) · [原图与 SHA-256](evidence/batch-20/45165361425/visual-verification.json)

## 2 · 1,000 条记录搜索和滚动

在同一浅色窄屏 iPhone SE（第三代）、iOS 26.2 中启动三个独立进程，用同一合成库和同一 15 字符查询。第一次输入将 1,000 条缩为唯一结果。后续字符仍匹配同一行。应用记录绑定收到输入、首个结果计数及记录行布局、SwiftUI 结果更新和下一次 `CADisplayLink` 回调。测试另用真实软件键盘提交，核对键盘消失、查询保留且唯一记录行可点。编辑感受和删除后的查询回归同时通过。 [定向运行 45179488037](https://github.com/betterfxb/private-moments-ios/actions/runs/45179488037) · [三次样本及范围](evidence/batch-20/45179488037/metrics.json) · [应用测点](evidence/batch-20/45179488037/app-trace.txt) · [XCTest 摘录](evidence/batch-20/45179488037/xctest-extract.txt)

| 指标 | 中位数 | 三次实测范围 |
| --- | ---: | ---: |
| 应用收到首字符至唯一记录行布局 | 51.6 ms | 38.5–52.1 ms |
| 应用收到首字符至显示刷新回调 | 255.6 ms | 107.0–299.3 ms |
| 应用收到整个查询的首字符至末字符 | 268.0 ms | 254.7–321.3 ms |
| 完整查询的过滤与分组 | 6.7 ms | 5.9–8.5 ms |
| 应用收到末字符至 SwiftUI 结果更新 | 12.3 ms | 9.4–13.4 ms |
| 应用收到末字符至显示刷新回调 | 89.5 ms | 31.3–110.3 ms |
| 实际手势从滚动交互到停止 | 2.49 s | 2.48–2.50 s |
| 其中系统滚动减速 | 2.31 s | 2.30–2.33 s |
| XCTest 开始驱动输入至确认唯一匹配 | 2.56 s | 2.51–2.65 s |
| XCTest 提交至确认收键盘及记录行可点 | 2.66 s | 2.29–2.67 s |

过滤和分组在此工作负载下只占应用局部计时的毫秒级时间。首个结果的布局比下一次刷新回调稳定。滚动约 93% 的观测时长来自系统减速。XCTest 两项秒级读数包括驱动、界面查询与等待，应用与测试驱动之间各自的成本及真机可感知延迟仍有待测量。刷新回调是时序代理，SwiftUI 更新也仅记录应用侧边界。保留现有搜索算法与滚动参数，后续如真机复现明显延迟，可对首次更新到呈现以及提交到结果可操作这两段独立测量。 [Apple 对 CADisplayLink 的说明](https://developer.apple.com/documentation/quartzcore/cadisplaylink)

前两轮各通过两个 XCTest 方法。第一轮已经显示首字符就命中，但更快的新按键会替换部分刷新观察，而且后续几何没有变化。第二轮保留了首次刷新，子视图的输入值在结果条数相同时仍未变化。最终版本把查询代次作为实际视图输入，三次分别观测到首次布局和末键更新。测点仅在 Debug 的隔离合成库启用，记录时间、计数、阶段和长度。 [初轮 45174147654](https://github.com/betterfxb/private-moments-ios/actions/runs/45174147654) · [第二轮 45177044372](https://github.com/betterfxb/private-moments-ios/actions/runs/45177044372)

## 3 · iOS 17 兼容路径

### 验收步骤

通过 GitHub Actions 的 `iOS validation` 手动选择 `legacy_ios17`。脚本先打印实际 macOS、Xcode、磁盘及模拟器库存，再验证无签名 Release 产品的 `MinimumOSVersion=17.0` 和 Debug 测试钩子排除。若库存没有 iOS 17，使用 Apple 的命令下载并导入 iOS 17.5。运行时可用后新建一次性 iPhone 15，执行现有搜索编辑删除及补记保存持久化两个真实 UI 方法。标准矩阵仍使用原来固定的 iOS 26.2 运行时。 [验证脚本](../scripts/verify-ios17.sh) · [Apple 工具链要求](https://developer.apple.com/xcode/system-requirements) · [Apple 运行时安装说明](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components) · [GitHub 托管镜像库存](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md)

首轮云端库存没有 iOS 17。Xcode 26.2 从 Apple 下载、导入并实际在 iPhone 15 上启动 `iOS 17.5 (21F79)`。Release 产品记录最低版本 `17.0`。搜索用例通过，覆盖补记后返回首页、软件键盘提交及消失、查询保留和编辑删除后更新。完整补记用例第一次在放弃草稿断言停止。XCTest 合成事件显示在 393 × 852 点窗口中的触点为 `(291, 830)`，离底部 22 点。取消后的原生层级显示已回首页。调整仅发生在测试，通过整控件滚入后单次点击，并立即核对选中状态。 [初轮 45181575195](https://github.com/betterfxb/private-moments-ios/actions/runs/45181575195) · [触点收据](evidence/batch-20/45181575195/tap-diagnostic.json) · [失败时原生层级](evidence/batch-20/45181575195/observed-hierarchy.txt)

第一轮修订复验在 ARM64 队列约 15 分钟后被服务端取消，未分配执行器、未执行任何测试步骤。随后以既有 Intel 执行器选项在同一提交复验。 [无执行器的 45185121354](https://github.com/betterfxb/private-moments-ios/actions/runs/45185121354)

**最终复验通过。** GitHub Intel macOS 使用 Xcode 26.2 启动实际 iOS 17.5（21F79）iPhone 15。源码 `11acd1403ab8f8131c4538a9433b8dc61e9b47d5` 的两个原生 UI 用例均通过。补记覆盖草稿保留、撤销更改、错误恢复、软件键盘、保存返回、日期筛选与重启读回。搜索覆盖提交收键盘、唯一结果及编辑删除后更新。无签名 Release 再次确认 `MinimumOSVersion=17.0` 并排除 Debug 测试钩子。实际运行点为 17.5，17.0 仅具备当前构建目标证据。 [最终复验 45187823979](https://github.com/betterfxb/private-moments-ios/actions/runs/45187823979) · [兼容性 XCTest 摘录](evidence/batch-20/45187823979/xctest-extract.txt)

## 4 · 真机复用清单 / Physical-device checklist

状态为待真机执行。预备一台可安装测试构建的 iPhone，使用独立的合成日记。记录构建提交、机型、系统版本、语言、字号和结果。使用合成备注和测试文件保存证据。 / Pending on a physical iPhone with an installable test build. Use a separate synthetic journal. Record the source revision, device, OS version, language, text size, and result. Capture evidence with synthetic notes and files.

| 顺序 | 中文验收 | English acceptance |
| --- | --- | --- |
| 1 | 通过系统 Files 存到「我的 iPhone」。从独立测试库选择该文件，检查预览和合并后的条数。重启后复查时长及备注。 | Export through Files to On My iPhone. Select that file in a separate test journal. Check the preview and merged count, then confirm duration and note after relaunch. |
| 2 | 打开 VoiceOver，从首页日期移至「开始记录」及「补记」。走完补记并在详情听读。检查两个入口名称、选中状态、确认框焦点和错误反馈。 | Enable VoiceOver. Navigate from the Home date to Start a moment and Add past moment. Save a past moment and listen to its detail. Check control names, selection announcements, dialog focus, and error feedback. |
| 3 | 切到简体中文拼音键盘，显示候选后选词，验证已确认的文字只写入一次。分别在补记备注保存读回、在时间线用同一合成标签查询并收起键盘。 | Use the Simplified Chinese Pinyin keyboard. Pick a candidate and check that it enters once. Save and reopen the note, then search a matching synthetic tag and dismiss the keyboard. |
| 4 | 外接键盘并启用完全键盘控制。用 Tab／Shift-Tab 检查焦点，用键盘提交搜索并返回结果。核对补记可完成，且记录只保存一次。 | Attach a keyboard and enable Full Keyboard Access. Use Tab and Shift-Tab to check focus, then submit a search and return to its result. Save a past moment and verify a single record was stored. |

## 本地检查与交付范围

`python -m unittest discover -s tools -p 'test_*.py'` 通过 47 项。`node tools/audit-localization.mjs` 和 `node tools/audit-xcode-project.mjs` 通过 236 个本地化键和 111 个 Xcode 对象审计。`node tools/audit-release-materials.mjs` 通过双语材料检查，发行 Bundle ID、发布者和审核联系人仍是待填写项。`bash -n scripts/verify-ios17.sh`、Windows 宿主提示及 16 份视觉证据的 SHA-256 校验通过。开发交付在原有 GitHub 草稿分支。 [草稿 PR #1](https://github.com/betterfxb/private-moments-ios/pull/1)
