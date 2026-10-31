# Private Moments Privacy Policy — Draft

**Do not publish until every bracketed field is completed and the policy is reviewed against the final app build.** App Store Connect requires a public privacy policy URL, and Apple requires access to the policy from inside the app.

- Publisher/legal name: **[Developer or legal entity name]**
- Privacy contact: **[Privacy contact email]**
- Public HTTPS policy URL: **[URL where this policy will be hosted]**
- Effective date: **[Date of publication]**

## English

### Scope

This policy describes the current iOS version of Private Moments, a personal journal that stores entries locally on the device.

### Information used by the app

Journal entries may include a date, duration, moment type, mood, rating, tags, and an optional private note. The current screens do not request location access or let the user enter a place label. The backup format can preserve an optional place label if it is present in an imported file. App Lock stores an app-private enabled/disabled preference.

### Local storage and network use

The app uses journal information to create and display the user's local entries. The current version has no account, app-run server, analytics, advertising, health service, partner sharing, or cloud synchronization. It does not send journal entries to the publisher. Local files use iOS file protection. The app also requests exclusion of its data directory from device backups; Apple describes that setting as guidance, not a guarantee.

### Device authentication

If App Lock is enabled, the app asks iOS to authenticate using the method configured on the device. iOS returns an authentication result to the app. The app does not receive Face ID or Touch ID biometric data.

### Optional backups

The user can export a JSON file or restore one previously selected. A backup may contain every saved entry, including private notes and any place label carried in the file. The app does not encrypt the exported file. The user chooses its destination; a file provider may store it outside the device under that provider's terms. Deleting an entry in the app does not delete exported copies.

### Retention and deletion

Entries remain in the app until the user deletes them. The user can delete one entry from its detail screen or delete all local entries in Settings. The app cannot delete copies saved to a location selected during export; those copies must be managed with that provider.

### Changes and contact

If data practices change, this policy and the App Store privacy information must be updated before or with the affected release. For privacy questions, contact **[Privacy contact email]**.

## 简体中文

### 适用范围

本政策说明当前 iOS 版本「私密时刻」如何处理数据。本应用是一款将日记记录保存在用户设备本机的个人日记应用。

### 应用使用的信息

日记记录可能包含日期、时长、记录类型、心情、评分、标签和可选的私密笔记。当前界面不请求位置权限，也不提供地点输入功能。若导入的备份文件中包含可选地点标签，备份格式可以保留该字段。应用锁会在应用私有的偏好设置中保存开启或关闭状态。

### 本地存储与网络使用

应用使用日记信息来创建和显示用户的本地记录。当前版本没有账户、应用自建服务器、分析统计、广告、健康服务、伴侣共享或云同步，也不会将日记记录发送给开发者。本地文件使用 iOS 文件保护。应用还会请求将数据目录排除在设备备份之外；Apple 将此设置说明为建议而非保证。

### 设备验证

开启应用锁后，应用会请求 iOS 使用设备上已设置的验证方式。iOS 只向应用返回验证结果；应用不会接收 Face ID 或 Touch ID 生物识别数据。

### 可选备份

用户可以导出 JSON 文件，也可以恢复之前选择的文件。备份可能包含所有已保存记录，包括私密笔记，以及文件中携带的地点标签。本应用不会加密导出的文件。保存位置由用户选择；文件服务提供方可能按照其服务条款将文件存储在本机之外。在应用中删除记录不会删除已经导出的副本。

### 保留与删除

记录会保留在应用中，直到用户将其删除。用户可以在记录详情页删除单条记录，也可以在设置中删除本地全部记录。本应用无法删除导出时保存到其他位置的副本；用户需要通过对应的文件服务管理这些副本。

### 政策变更与联系

如果数据处理方式发生变化，我们会在相关版本发布前或发布时更新本政策和 App Store 隐私信息。如有隐私问题，请联系 **[隐私联系邮箱]**。

## Publication requirements

Before publishing, replace all bracketed fields, host the localized policy at a public HTTPS URL, place that URL in App Store Connect, and link to the policy from an easily accessible in-app screen. Apple's [App Privacy guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/) requires the URL for iOS apps; [Guideline 5.1.1](https://developer.apple.com/app-store/review/guidelines/) also requires an in-app policy link and clear retention/deletion terms.
