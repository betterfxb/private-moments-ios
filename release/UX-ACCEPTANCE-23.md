# Private Moments 第二十三批云端验收

开发分支为 `feat/native-manual-entry`。云端受测源码为 `a171c7e1bdb307cc2c7433cce8b48374f2fb0a78`。[GitHub Actions 原始运行](https://github.com/betterfxb/private-moments-ios/actions/runs/45621760389)

## 耗时与拆分依据

上一批的 iPhone SE 深色最大辅助字号定向运行中，双语原生图库用时 2,874.728 秒，独立双语搜索用时 346.551 秒。XCTest、原图和结果包上传均成功，整项作业仍在 75 分钟预算附近记录为取消。同批复验中的一个深色辅助字号核心运行，五个双语功能用例共用时约 43 分钟。已成功的常规小屏英文系统文件用例用时 984.780 秒。这些数字含模拟器和 XCTest 驱动耗时。[上一批运行与限制](UX-ACCEPTANCE-22.md)

## 四套配置的验收范围

| 配置 | 保留的流程 | 独立作业 |
| --- | --- | --- |
| 常规小屏浅色 | 原生双语图库和键盘搜索，收藏、周期回顾和草稿，原有完整单元和基础 UI 测试，英文与中文系统 Files，无签名 Debug／Release、Release 测试钩子排除 | `gallery`、`journal`、`core`、`files`、`files-zh` |
| 常规手机深色 | 原生双语图库和键盘搜索，收藏、周期回顾和草稿，英文系统 Files | `gallery`、`journal`、`files` |
| 常规 iPad 浅色 | 原生双语图库和键盘搜索，收藏、周期回顾和草稿，英文系统 Files，系统旋转 | `gallery`、`journal`、`files`、`rotation` |
| 小屏深色最大辅助字号 | 原生双语图库和键盘搜索，收藏、周期回顾和草稿，英文系统 Files | `gallery`、`journal`、`files` |

本批完整运行展开 15 个命名作业。同一运行中的作业共享源码提交。截图和 XCTest 结果包按设备配置及分组命名，可以直接定位问题。每个分组选取现有用例，作业预算在测试步骤预算之外预留 25 分钟用于执行器准备、诊断及归档。`69365f7` 开始，重跑产生的归档增加重跑次数后缀，可保留原失败证据。继续保留手动专项诊断和单独的 iOS 17 兼容入口。[GitHub 作业与重跑上下文](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) · [GitHub 归档命名规则](https://github.com/actions/upload-artifact/blob/main/README.md)

## 本地和云端结果

- Windows 已通过 `python -m unittest discover -s tools` 的 51 项工具测试、本地化 270 键审计、Xcode 项目 113 对象审计、发行材料审计和 `git diff --check`。现有 Bundle ID 占位及发布者资料待填写提示仍存在。
- 云端 `plan` 作业已通过并展开 15 个模拟器作业。iPad Pro 13 英寸（M5）、iOS 26.2 的旋转作业通过。中英文都建立系统设置参照，检查草稿、详情往返、暂停计时和已保存记录重启后读回。作业上传 22 张原图及 XCTest 包，从中保存 6 张典型横竖屏原图和对应哈希。其余原生作业结果待查。[iPad 作业](https://github.com/betterfxb/private-moments-ios/actions/runs/45621760389/job/139231709031) · [XCTest 摘录](evidence/batch-23/45621760389/ipad-light-rotation/xctest-extract.txt) · [截图收据](evidence/batch-23/45621760389/ipad-light-rotation/screenshots.json)
- iPad 浅色图库和小屏深色最大字号图库均通过，分别上传 70 和 74 张截图，保留双语空结果与匹配搜索的实拍。iPhone 17 Pro 常规字号深色日记作业通过 16 项相关单测和 5 个双语原生流程。[iPad 图库](evidence/batch-23/45621760389/ipad-light-gallery/xctest-extract.txt) · [最大字号图库](evidence/batch-23/45621760389/compact-dark-accessibility-gallery/xctest-extract.txt) · [手机深色日记](evidence/batch-23/45621760389/phone-dark-journal/xctest-extract.txt)
- 小屏深色最大字号的草稿用例已明确保存并重启，时间线核对到一条记录。失败截图及界面树显示，随后的一次记录点按没有打开详情。`c98ed17` 先把记录完整滚出并检查其避开底部标签栏，等布局稳定后点一次，同时断言进入详情并继续检查原备注。相同环境复验已请求，结果待查。[失败现场](evidence/batch-23/45621760389/compact-dark-accessibility-journal/Control-unreachable.png) · [原始日志摘录](evidence/batch-23/45621760389/compact-dark-accessibility-journal/xctest-extract.txt) · [复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45633000627)
- 同一配置的 Files 作业通过 9 项单测，原生回路此前已选过实际文件。最后一次「恢复」点按后的截图和界面树显示应用停在时间线，随后也没有收到新的选档器事件。`85983a4` 在每次点击恢复前确认完整按钮处于可见区域且位置稳定。复验仍走系统 Files、取消、合并和替换，并核对重启后的内容。[失败现场](evidence/batch-23/45621760389/compact-dark-accessibility-files/Import-file-unavailable.png) · [原始日志摘录](evidence/batch-23/45621760389/compact-dark-accessibility-files/xctest-extract.txt) · [最大字号复验](https://github.com/betterfxb/private-moments-ios/actions/runs/45634179726) · [中文 Files 补跑](https://github.com/betterfxb/private-moments-ios/actions/runs/45634722050)
- 常规小屏图库作业在任何步骤开始前取消。GitHub 作业注释记录托管 ARM64 执行器因容量约束未领取。后续矩阵限制同一运行最多 4 个 macOS 作业并行，以减少一次分配全部设备组造成的竞争。[队列取消记录](https://github.com/betterfxb/private-moments-ios/actions/runs/45621760389/job/139231708779) · [GitHub 矩阵并发说明](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations#defining-the-maximum-number-of-concurrent-jobs)
