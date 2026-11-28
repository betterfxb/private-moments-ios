# 第十五批：独立冷启动旋转验收

日期：2026-11-14（Asia/Tokyo）。按[计划](BATCH-15-PLAN.md)顺序执行。默认四配置保持，完整回归仍以第十三批源码fb78856／运行43556512255为准；本批是定向Debug UI补充，0应用单元，无Release验收。

## 改动与验证条件

新增rotation_start显式入口：reference沿用真实Settings对照；cold-en与cold-zh-Hans各选唯一语言的独立方法。两个冷方法共享原有3分8秒／两行备注、实际窗口尺寸、取消继续编辑、原生返回、暂停及已保存内容重启流程；保持20秒旋转期限及精确断言。

每个冷语言在独立派发的新macOS任务中只运行一个UI方法，入口断言应用尚未运行，日志记录无系统参考调用；不在英文之后继续中文并冒充第二次冷启动，也不通过Settings预热。这里的冷启动是指定新任务中的应用首次运行，不等于物理设备首次安装、所有模拟器环境或统计稳定性证明。

任务环境独立性的依据是当前工作流使用GitHub托管macos-15运行器，以及[GitHub官方运行器说明](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)对每个托管任务使用新运行器镜像实例的约定；应用初始未运行与精确内容／几何另由本次原生日志核对，不以平台约定替代产品断言。

脚本和工作流拒绝冷入口搭配full／input／backup或非iPad；默认完整及其他定向显式排除两个冷方法。18项工具测试、729组脚本及72组工作流防护、Bash语法、230本地化键、109项目对象和发行材料审计通过。Windows初次测试因PATH无Bash失败，补充从已安装Git定位Bash后通过，无新增依赖。发行占位警告仍保留。

## 实际云端结果与原图

- [cold-en运行43588585515](https://github.com/betterfxb/private-moments-ios/actions/runs/43588585515)：源码`fbcae3f4b34055f719c2044f1adb322844349659`，方法`testIPadColdEnglishRotationContinuity`。
- [cold-zh-Hans运行43589974794](https://github.com/betterfxb/private-moments-ios/actions/runs/43589974794)：源码`fbcae3f4b34055f719c2044f1adb322844349659`，方法`testIPadColdChineseRotationContinuity`。
- [reference运行43591326457](https://github.com/betterfxb/private-moments-ios/actions/runs/43591326457)：源码`fbcae3f4b34055f719c2044f1adb322844349659`，方法`testIPadRotationContinuity`。

| 配置／入口 | 实际设备 | 语言 | UI方法秒数 | 应用窗口核对 | PNG核验／实际打开 | 显示像素尺寸 |
|---|---|---|---:|---:|---:|---|
| ipad-dark-accessibility／cold-en | iPad Pro 13-inch (M5) | en | 284.009 | 9 | 10／10 | 2064×2752、2752×2064 |
| ipad-dark-accessibility／cold-zh-Hans | iPad Pro 13-inch (M5) | zh-Hans | 257.200 | 9 | 10／10 | 2064×2752、2752×2064 |
| ipad-light／reference | iPad Pro 13-inch (M5) | en, zh-Hans | 583.108 | 18 | 22／22 | 2064×2752、2752×2064 |

每项方法仅实际开始／通过一次，云端任务成功；没有用自动重试覆盖失败。冷方法每语言9次应用几何、10张应用图；reference双语18次应用及4次系统参考核对、22张图。原始IHDR／EXIF显示方向与实际窗口点尺寸分列记录，方向值本身不作为窗口成功依据。

两组冷启动原图显示：英文／中文的两行备注及30字符计数保持，原生继续编辑／放弃操作同屏可见；Today两个主操作、时长3分8秒且评分4/5的1条记录、详情与重启备注均有实际现场。暂停页00:03及Resume／继续与Finish／结束可读，数字仅为截图当时值，不用于精度验收。最大字号下中英文搜索提示仍省略，宽屏居中限宽有明显留白；表单滚动后顶部内容进入系统导航模糊区域，部分字段不在取景内，不能声称整张表单同屏展示。

默认浅色Large字号的22张原图另逐张核对：两种语言的草稿备注与30字符计数、继续编辑确认、Today／Timeline的单条3分8秒及4/5记录、横竖详情、保存后重启备注均保持。应用设置显示1条已保存记录；独立系统Settings原图显示横屏参考现场。暂停页英文00:03、中文00:04只是当时值，两项主操作可见，计时页自身保持深色设计。默认英文搜索提示完整，中文仍省略；宽屏留白与表单滚动后的顶部模糊仍存在。

合计42张PNG完成精确核验，42张原图逐张实际打开并保留，见[原图索引](evidence/batch-15/index.html)及[来源收据](evidence/batch-15/verification.json)。原始日志、manifest、文本层级、下载收据与SHA-256一起保存；没有裁切、改色、重绘或用下载数代替实际检查数。方法耗时包含构建之外的自动化／系统查询／截图，不是产品响应时间基准。

## 结论与保留边界

这次补齐指定固定26.2云端环境中、未经Settings参考的独立英文与中文首次旋转条件；默认浅色reference共享流程另行回归。本批不修改生产Sources、Resources、应用Tests、Xcode项目或存储结构。第十四批三次旧失败仍保留其真实源码和现场，本轮成功不能反推其根因或宣称生产旋转故障已经修复。

键盘已收起后才旋转，备注为Rotation draft换行Keep every line的合成ASCII文本；没有验证中文IME组合候选、聚焦键盘中旋转、系统窗口缩放或多窗口、未保存草稿／计时终止恢复、真实认证／锁屏文件保护或真机辅助技术。

后续优先建立真实系统窗口控制的可复现操作与窗口几何／连续性证据，明确草稿和计时终止恢复产品策略，再补性能基线与真机验证。第十四批观察到的resize-grabber仍仅为系统层级线索，未证明可命中或能缩放；搜索提示省略、宽屏留白与视觉质感保留为产品设计工作，功能通过不等于审美认可或超过DO。

[项目记忆](../PROJECT-MEMORY.md)保存受测源码与后续边界。草稿PR、main不合并、暂不签名及Apple上传的约束保持。
