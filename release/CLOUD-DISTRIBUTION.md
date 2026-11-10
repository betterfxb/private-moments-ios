# 云端开发归档与后续 TestFlight 使用说明

## 当前阶段

项目继续开发。本批验证的是无签名开发归档，不需要 Apple Developer 付费账号，不上传 Apple，也不代表产品已经准备上线。

普通开发 CI 保留现有配置；新的归档流程单独选择 `release/distribution-config.json` 指定的 Xcode 26.2，并检查实际 iOS SDK。当前 Apple 上传最低要求为 Xcode 26／iOS 26 SDK；之前 Xcode 16.4 的模拟器测试结果不能替代这一要求。真正准备分发时，需要再次核实 Apple 的当时要求。

本批已于 2026-11-10 验证通过：[运行 42726665523](https://github.com/betterfxb/private-moments-ios/actions/runs/42726665523)，源码 `0d24c3b`。25 项工具测试、23 项应用单元测试、3 项 UI 测试、Debug／Release 构建及 arm64 真机目标无签名归档均通过；归档已下载并核对 SHA-256，28 张中英文小屏浅色截图已下载检查。详细记录见 `DISTRIBUTION-PLAN.md`；新 SDK 下的其他设备／外观验收仍在后续开发清单中。

## 在 Windows 上运行开发归档

1. 打开仓库的 **Actions → iOS development archive**。
2. 选择 **Run workflow**，分支为 `main`，版本默认 `0.1.0`；构建号留空时使用 `run_number.run_attempt`。
3. 等待轻量预检通过，再等待 macOS 测试和归档任务完成。
4. 下载运行页面的产物，在 Windows 解压查看报告与 PNG。这个操作不需要本机安装 Mac、Xcode 或 Python。

执行顺序：

```text
静态审计 + Python 行为测试 + 版本参数检查
  → 明确选择并验证 Xcode / iOS SDK
  → 启动与 SDK 匹配的 iPhone 模拟器
  → Debug / Release 模拟器构建 + 23 项应用单元测试 + 3 项 UI 测试
  → generic iOS device Release 无签名归档
  → 检查真实归档内容与 Mach-O 平台
  → 导出开发归档、报告、测试结果和中英文截图
```

任一步失败时，后续归档不会被当成成功产物。新工具不会静默回退到 runner 默认的旧版 Xcode。

| 产物 | 内容与用途 |
|---|---|
| `private-moments-unsigned-development-<run>-<attempt>` | `PrivateMoments-UNSIGNED.xcarchive.zip` 与 `distribution-report.json` |
| `private-moments-distribution-tests-<run>-<attempt>` | `.xcresult` 与 `DistributionScreenshots` 中的 PNG；覆盖本轮 SDK 下的核心 iPhone 流程及中英文界面 |

归档检查包含：Bundle ID／版本／构建号、iPhone 与 iPad 支持、最低系统版本、实际 SDK、arm64 真机架构与 Mach-O iOS 平台、AppIcon／资源目录、隐私清单、中英文 UI 与元数据、dSYM，以及 Release 不含 Debug UI 测试存储入口或私钥。

英文源语言可以使用原始文案键，Xcode 不必生成重复的英文 UI 字符串表；中文必须有编译后的翻译表。检查同时核对源语言与归档开发语言，并在报告的 `localizedUIResources` 中记录实际来源。两种语言的应用显示名与 Face ID 用途说明都必须随包存在。

报告会明确写出 `mode: unsigned-development`、`testflightReady: false`、`uploaded: false`。无签名归档不是可安装 IPA，不能直接用于 TestFlight。占位 Bundle ID 仅用于开发验证，后续分发要重新用注册身份构建。

产物保留七天，重要结果应下载保存。测试结果中的模拟器截图与归档中的真机二进制用途不同，报告会分别标明。

私有仓库使用 GitHub-hosted macOS runner 和产物存储会计入仓库所有者的 Actions 用量，超出套餐包含额度后可能产生费用；实际额度、预算与费率以账号 Billing 页面和 [GitHub Actions 计费说明](https://docs.github.com/en/billing/concepts/product-billing/github-actions) 为准。本流程采用手动触发和七天产物保留期，后续通常只需在准备验证一个开发版本时运行。

## 故障处理

- **版本参数无效：** 在 Ubuntu 预检阶段停止。版本使用三段数字；构建号首段为 1–9999，后续最多两段，每段 0–99。例如 `0.1.0`、`7.2`。
- **Xcode／运行时缺失：** 检查 runner 镜像与打包策略，明确更新选定版本和最低 SDK 后再验证。不要改为不检查版本的默认工具链。
- **测试或归档检查失败：** 查看原生编译日志、`.xcresult`、PNG 或检查错误；修正源代码后重新运行，不跳过失败断言。
- **runner 无法分配：** 查看 GitHub 注释确认容量问题。等当前运行结束后单独重跑未执行的任务，保留其他有效结果。
- **已经存在输出目录：** 工具拒绝覆盖既有产物。选择新的目录或新的 workflow 运行。

## 后续真正启用 TestFlight 时再配置

目前不要运行 **iOS TestFlight upload (future opt-in)**。当前没有账号和密钥，真实签名、上传及 Apple 处理结果均未做端到端验证。

以后需要付费 Apple Developer 账号、已注册的明确 Bundle ID、对应 App Store Connect app record、有效 Apple Distribution 证书及其私钥、匹配的 App Store provisioning profile，以及有上传权限的团队 App Store Connect API key。

在 GitHub 创建 `testflight` Environment，限制为 `main` 分支，并配置：

| 类型 | 名称 | 内容 |
|---|---|---|
| Variable | `PM_TESTFLIGHT_UPLOAD_ENABLED` | 真正准备分发后才设为小写 `true`；未配置时上传关闭 |
| Variable | `PM_BUNDLE_ID` | 已注册 Bundle ID，不接受 `com.example.*` |
| Variable | `PM_APPLE_TEAM_ID` | 10 位 Apple Team ID |
| Variable | `PM_ASC_KEY_ID` | 10 位团队 API Key ID |
| Variable | `PM_ASC_ISSUER_ID` | 团队 API key 的 Issuer UUID |
| Secret | `PM_DISTRIBUTION_P12_BASE64` | 包含证书及私钥的 `.p12` 文件的 Base64 |
| Secret | `PM_DISTRIBUTION_P12_PASSWORD` | `.p12` 密码 |
| Secret | `PM_APPSTORE_PROFILE_BASE64` | 匹配此 App／Team／证书的 App Store `.mobileprovision` Base64 |
| Secret | `PM_ASC_PRIVATE_KEY_BASE64` | 团队 API `.p8` 私钥文件的 Base64 |

证书、密码和私钥只放 GitHub Secrets，不写入代码、变量、聊天或普通构建产物。Windows 可用以下方式把文件复制为 Base64，避免在终端打印内容：

```powershell
Set-Clipboard -Value ([Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\path\distribution.p12')))
```

真正运行未来的 TestFlight 工作流时：先检查开关、分支、公开身份和密钥是否齐备；再复用无凭据开发验证；最后在独立 macOS job 中使用临时 keychain／profile，重新归档、导出签名 IPA，使用 Apple 原生命令校验并上传。工具在成功或失败后清理自建资源，恢复原 keychain 搜索列表，不覆盖或删除既有不同 profile。

签名路径会检查 profile 有效期、Team／明确 Bundle ID、分发类型，以及证书与私钥身份是否匹配。上传后的 Apple processing、出口合规问卷、测试者可用性和可能的 Beta App Review 仍需在 App Store Connect 确认；命令返回成功不能等同于测试者已经收到可用版本。流程不包含 App Review 提交或正式 App Store 发布。

## 后续开发与发布条件

当前仍需继续产品开发与打磨，尤其是发布版文案、最新 SDK 下更多设备／大字体布局、计时与异常恢复、备份恢复 UI、真机 VoiceOver／生物识别／后台隐私／文件保护。发布者资料、公开政策及支持 URL、出口合规、年龄分级、签名和 TestFlight 实测另行完成。本批不会代填这些声明。

建议下一批按以下顺序继续；这是待办计划，不是本轮已完成的功能：

| 顺序 | 目标／范围 | 依赖与完成标准 |
|---|---|---|
| 1 | 补齐备份恢复交互验收：导出警告、导入后合并／替换选择、二次确认、取消、空备份 | 使用合成备份与独立测试库；先验证原生文件选择和弹窗切换，再验证记录数量、内容及取消后不变。复用 `RESTORE-ACCEPTANCE.md`，不以 codec 单元测试代替 UI 验收 |
| 2 | 补齐异常界面：首次读取失败、缓存只读、重试中、重试成功／失败 | 在明确的测试依赖注入边界模拟故障，Release 不接受故障启动参数；验证错误卡片、未知数量、禁用动作及恢复后的旧记录，保留真实磁盘损坏的真机检查 |
| 3 | 定义并实现中断中的计时／回顾恢复 | 当前进程被强制退出后不会恢复活动会话。先确定运行／暂停、后台／重启、丢弃、保存后的清理规则，再设计受保护的最小草稿与迁移；避免把墙钟变化直接当作可靠计时时长，避免保存两条相同记录 |
| 4 | 在新 SDK 上完善视觉细节与产品文案 | 复用现有暖色 tokens，扩展 iPad、深色和最大辅助字号截图验收；依据实际截图调整控件与间距，整理界面中的 MVP／技术说明。两种语言同步更新，无需重新制作纯图片原型 |
| 5 | 真机可用性与隐私验收 | 先完成前四项及稳定归档，再验证 VoiceOver、Face ID／设备密码、后台遮挡、文件保护和备份恢复；自动化结果与人工记录分开保存 |
| 6 | 再决定是否启动内测分发 | 产品达到内测标准后再注册最终身份、配置账号、实测签名／上传和 Apple 处理；不将购买开发者账号作为当前开发的前置条件 |

第 3 项涉及持久化和计时状态，属于较大的产品修改，应先输出详细设计与影响范围再实施；本轮没有提前改动此行为。第 1、2 项优先补足已有功能的体验证据，之后再扩展功能。

## 来源与复核日期

2026-11-10 核实：

- [Apple SDK 最低要求](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
- [Apple 上传、版本匹配和处理流程](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [GitHub macOS 15 镜像中的 Xcode / SDK](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
- [GitHub 临时证书与 profile 安装、清理](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)
