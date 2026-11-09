# 云端开发归档与后续 TestFlight 使用说明

## 当前阶段

项目继续开发。本批验证的是无签名开发归档，不需要 Apple Developer 付费账号，不上传 Apple，也不代表产品已经准备上线。

普通开发 CI 保留现有配置；新的归档流程单独选择 `release/distribution-config.json` 指定的 Xcode 26.2，并检查实际 iOS SDK。当前 Apple 上传最低要求为 Xcode 26／iOS 26 SDK；之前 Xcode 16.4 的模拟器测试结果不能替代这一要求。真正准备分发时，需要再次核实 Apple 的当时要求。

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

报告会明确写出 `mode: unsigned-development`、`testflightReady: false`、`uploaded: false`。无签名归档不是可安装 IPA，不能直接用于 TestFlight。占位 Bundle ID 仅用于开发验证，后续分发要重新用注册身份构建。

产物保留七天，重要结果应下载保存。测试结果中的模拟器截图与归档中的真机二进制用途不同，报告会分别标明。

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

## 来源与复核日期

2026-11-10 核实：

- [Apple SDK 最低要求](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
- [Apple 上传、版本匹配和处理流程](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [GitHub macOS 15 镜像中的 Xcode / SDK](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
- [GitHub 临时证书与 profile 安装、清理](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)
