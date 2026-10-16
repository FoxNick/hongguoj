# 短句汇 · 手机 / Android TV 通用无广爽看版

基于 [guoapp](https://github.com/zhoufuweigg/guoapp) 的非官方独立客户端。手机与 Android TV 使用同一 Android 应用，保留原项目站源、播放和下载功能；“无广爽看”是此项目的使用体验定位，具体片源和广告情况取决于内容来源，不保证所有资源无广告。

当前源码版本为 **0.3.9+51**（电视提示条改居中浮层、选中态与聚焦态分离，待验证），前一版本为 **0.3.8+50**（下载目录自动隐藏、电视网格 cacheExtent），再前 **0.3.7+49**（提示条统一为 3 秒且不再排队、HLS 密钥挪进 `.meta` 并修好 HLS 整集缓冲），再前 **0.3.6+48**（安装程序改为强制关闭、首页菜单加退出、电视返回键原生拦截、HLS 密钥清理补齐），再前 **0.3.5+47**（下载转 MP4 补解密密钥并加校验、安装程序关闭检测、合并产物归位），再前 **0.3.4+46**（搜索态不再混排分类标签），再前 **0.3.3+45**（修复密码锁写盘被拒的回归、去掉旧名兼容副本、托盘右键菜单、CI 加入 Dart 回归测试），再前 **0.3.2+44**（电视标签焦点跟随修复、桌面版关闭隐藏到托盘），再前 **0.3.1+43**（产物更名、桌面版品牌与安装程序、下载目录改到系统下载夹、敏感站源默认隐藏、下载与返回键修复），再前 **0.3.0+42**（下载目录改为系统「下载 / 短句汇」、附属文件收进 .meta、历史按站源过滤、自动横屏播放、电视导航焦点跟随），再前 **0.2.9+41**（还原发现与榜单的位置），再前 **0.2.8+40**（播放器倍速新增 1.15 倍），再前 **0.2.7+39**（移除皮果、野果停用、默认显示全部站源、电视交互修复、榜单与发现对调、修复黄果榜单，已发布），再前 **0.2.6+38**（下载合集菜单新增一键合并本剧），再前 **0.2.5+37**（修复同剧共用目录互相删除，用户已实测确认），再前 **0.2.4+36**（下载按剧名组织、HLS 转 MP4），再前 **0.2.3+35**（红果取流编码优先、版本号偏移修复），再前 **0.2.2+34**（下载解密、合并导出 MP4），再前 **0.2.1+33**（更名短句汇、换品牌图、详情页预取提速），再前 **0.2.0+32**（更新频道切换与联系方式），其后为 **0.1.9+31**（红果取流签名补全，用户已确认真机可播），再后 **0.1.8+30**（迁回 12 个短剧站源），历史候选基线 **0.1.7+29**（手机顶部弹幕更新），正式基线 **0.1.6+28**，新增 Android 应用内更新，补充手机竖屏点按和快进后恢复播放、Android 返回与系统栏兼容性，以及内置 Fluent 3D 弹幕表情，保留自动连播末帧保留，构建、签名与发布状态以对应 Release 和校验报告为准。历史稳定版 [0.1.3](https://github.com/qq294716498/HongguoTV-Phone-TV-NoAds/releases/tag/app-v0.1.3-24) 仍可下载。推送提交会自动编译与静态检查，打 `app-v*` 标签或手动触发才会构建 APK 并发布，发布说明由本文件对应版本小节自动生成。原项目说明、历史改动和依赖许可见下文及各依赖目录。

## 0.3.9 电视提示条居中浮层、选中态与聚焦态分离（待验证）

**电视提示条**：Material 的 SnackBar 在 `fixed` 模式下必然占满整宽、文字左对齐，没法让背景跟随文字宽度。`showNotice` 在电视上改为自绘浮层（[widgets.dart](lib/widgets.dart)）：底部居中的圆角深色块，**宽度由文字决定**，3 秒自动消失；带「查看」这类按钮时同样可点，连点只保留最新一条（沿用 0.3.7 的「先收后弹」语义）。手机与桌面继续用标准 SnackBar。

**选中态与聚焦态分离**：[remote_widgets.dart](lib/remote_widgets.dart) 的 `RemoteTarget` 原先 `selected` 与 `_focused` 用同一个 `primaryContainer` 底色，于是焦点在左上角「红果」（它有红边框）时，「发现」和「全部」也因为 `selected=true` 顶着同一块粉底，看起来像有两个焦点。现在选中项默认不画底色（新增 `selectedBackground` 开关，**批量选择模式下的卡片仍传 `true`** 以保留勾选标记），改为图标与文字使用主色；聚焦态保留底色与边框。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；本地 `catalog_categories_test` 与 `library_features_widget_test` 通过，`television_test` 有 2 条**既存**失败（改动前的全量日志里同一对用例已失败，该文件在 CI 门槛的排除名单内）。电视上的实际观感需要在电视确认。

## 0.3.8 下载目录自动隐藏、电视端渲染优化（待验证）

**下载的视频不再进相册**：Android 的媒体扫描器会把公开目录里的视频加进相册与图库。此前需要在 `Download/短句汇/` 手动放一个 `.nomedia` 文件，它会让扫描器跳过整棵子树。现在 [nativeEnsureHiddenFromGallery](native/core/app_storage.go) 自动补写该标记（已存在则不动），三处调用：引擎启动确定下载目录时、用户更改保存目录后、迁移下载目录后；只在 Android 生效，桌面版不会产生无用文件。已经下过、在创建标记之前被扫描到的文件，在 MIUI 相册里可能仍有残留条目，需要清一次「相册」的媒体库缓存或重启手机才会消失。

**电视端渲染优化**：电视网格的 `CustomScrollView` 增加按行高计算的 `cacheExtent`（[remote_widgets.dart](lib/remote_widgets.dart)）。原先用默认的 250 逻辑像素，在电视的大卡片布局下不到一行，滚动时卡片被反复重建。

（同轮的另一个尝试——把封面解码宽度从写死的 440 物理像素改成跟随布局尺寸 × 设备像素比——已回退：它会改变图片的缓存键，测试 `cover_image_test.dart` 命中的是固定尺寸的预缓存条目，在 CI 上直接失败；重新计算后 440 宽的封面约 1.4MB、一屏 20 张约 27MB，并不是卡顿来源，不值得为此改动。）

**未做（需要单独一轮）**：[core_bridge.dart](lib/core_bridge.dart) 的每个核心调用都走 `Isolate.run`，也就是**每次请求都新开一个 isolate**（重新打开动态库、重新查符号）。电视 CPU 弱，这笔固定开销摊在每次按键触发的请求上，是电视端持续卡顿的嫌疑之一。改成常驻 worker 池可以省掉它，但一处写错会让所有核心调用一起失效，在没有真机验证手段的情况下不适合与本版一起发。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；`go build` / `go vet` 通过；`go test ./core/` 只剩既存的无关失败 `TestLegacyAnonymousCatalogAndSessionReuse`。`.nomedia` 是否让相册彻底不再显示（尤其 MIUI）、以及电视端流畅度提升，都需要真机确认。

## 0.3.7 提示条统一为 3 秒、HLS 密钥挪进 .meta（待验证）

**现象**：加入下载后底部那条「已加入 N 集，已有任务自动跳过 / 查看」点不掉、也不消失。

**原因**：Flutter 的 SnackBar 是**排队**的，全项目 20 处 `showSnackBar` 没有一处调用 `hideCurrentSnackBar()` 或 `clearSnackBars()`。同一动作连点多次就排一长串，每条默认 4 秒，几十条叠起来看起来就是「永远不消失」；点掉当前这条后，排队的下一条立刻顶上来，所以也像「点不动」。另外「查看」原本是 `Navigator.push` 一个新下载页，而多数时候用户已经在底部导航的「下载」标签上，界面毫无变化，更像「点了没反应」。

**修复**：[widgets.dart](lib/widgets.dart) 新增统一入口 `showNotice(context, message, {action, duration})`：先 `hideCurrentSnackBar()` 再 `showSnackBar()`，时长固定 **3 秒**。全项目 20 处提示全部切到该入口（现在只剩它内部一处 `showSnackBar`），连点只保留最新一条、3 秒必消失。「查看」改为先 `popUntil(isFirst)` 再 push 下载页，从任何位置点击都落在同一个下载页，不再叠层、也不再出现「界面没变」的错觉。

**HLS 密钥挪进 `.meta/`**：密钥不再落在剧集目录里。密钥分片的资产名改为 `.meta/<hash>.key`（[app_download_hls.go](native/core/app_download_hls.go)），播放列表里对应的 `URI` 同步指向 `.meta/<hash>.key`；资产已经在 `.meta/` 之内时，其传输状态文件就放在旁边而不再多套一层 `.meta`（[nativeDownloadMetaPath](native/core/app_download_transfer.go)）。连带四处适配：

- [localFilesValid](native/core/app_download_collections.go) 接受 `.meta/` 前缀
- [整集缓冲校验](native/core/app_episode_cache.go) 增加对 `.meta/` 内资源的遍历登记
- 串流路由允许 `cached/` 之后出现子路径，资源名按剩余路径段拼接
- [discardDownloadMediaDepth](native/core/app_downloads.go) 解析 `#EXT-X-KEY` 的 URI 一并删除，旧的平铺 `<hash>.key` 残留也会被清掉

**顺带修掉一个既存 bug**：整集缓冲的校验要求「入口文件必须有传输状态」，而 HLS 的入口是本地写出的 `.m3u8` 播放列表（没有也不需要状态），于是 **HLS 剧集的整集缓冲从来没有完成过**（一直重试到超时）。现在只对非播放列表的入口保留这项要求。修好后 `TestEpisodeCacheHLSIncludesEverySegmentAndKey`、`TestEpisodeCacheExtensionlessHLSIsNotACompleteVideo`、`TestEpisodeStartupPrioritizesHLSAudioVideoDependencies` 三个长期失败的用例全部转绿。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；`go build` / `go vet` 通过；`go test ./core/` 只剩一个既存无关失败 `TestLegacyAnonymousCatalogAndSessionReuse`（初始导入即失败，CI 里 `go test` 是 `continue-on-error` 的信息性步骤）。连点提示条、点「查看」、以及 HLS 剧集的下载与整集缓冲都需要在真机确认。

## 0.3.6 安装程序强制关闭、界面退出、电视返回键原生拦截、HLS 密钥清理（待验证）

**安装程序不再报文件被占用**：0.3.5 把 `CloseApplications` 设成 `no`，托盘进程仍占着 `avdevice-62.dll`，替换文件时报 `DeleteFile failed; code 5 拒绝访问`——从「卡在 Closing applications」变成「文件被占用」。现在 [windows_installer.iss](scripts/windows_installer.iss) 改为 `CloseApplications=force`：安装程序会强制结束占用文件的实例（托盘进程也能关掉），既不卡住也不报占用；`RestartApplications=no` 保持不自动重启；`AppMutex` 保留，对带互斥体的版本先给友好提示。

**界面里可以直接退出**：首页右上角菜单新增「退出$appName」。[home_screen.dart](lib/home_screen.dart) 在 Windows 走托盘销毁 + 关窗，其它平台走 `SystemNavigator.pop`。此前桌面版点 ✕ 只隐藏到托盘，而 0.3.2 的托盘右键菜单是坏的（0.3.3 才修），导致 0.3.2 从界面上根本退不掉、只能杀进程。

**电视返回键改为原生全程拦截**：以前只在播放中拦截返回键并转发给 Dart，首页返回依赖 Flutter 的 PopScope。现在电视上无论是否在播放，返回键都由 [MainActivity](android/app/src/main/kotlin/com/hongguo/tv/MainActivity.kt) 的 `dispatchKeyEvent` 消费并转发（播放中发给播放页，否则发给首页新通道 `duanju/home-back`），Activity 永远不会自己 finish；首页收到后走 `Navigator.maybePop()`，弹窗等路由照常自己关闭，根路由再交给既有的「再按一次退出」逻辑。手机不受影响（原生侧只在电视模式拦截）。

**HLS 密钥清理补齐**：`discardDownloadMediaDepth` 以前只删播放列表里非注释行引用的分片，而 HLS 密钥写在 `#EXT-X-KEY:…URI="…"` 注释里，所以 `<hash>.key` 从来不会被删、一直留在剧集目录。现在解析这些 URI 一并删除（含 `..` 越界防护），已经残留的旧密钥文件也会在下次放弃或重下该集时清掉。

**未做**：把 HLS 密钥挪进 `.meta/`。缓存与串流服务按「资源名」索引（[app_episode_cache.go](native/core/app_episode_cache.go) 用 `parts[2]` 取名字、按 `files[name]` 查找），密钥带上 `.meta/` 前缀后名字里多一个 `/`，请求路径分段对不上，已缓冲剧集会取不到密钥；而验证这条链的三个缓存测试目前全是既存失败状态，没有可用验证手段，因此没有随本版改动。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；`go build` / `go vet` 通过。`go test ./core/` 有 4 个既存失败用例（`TestEpisodeCacheHLSIncludesEverySegmentAndKey`、`TestEpisodeCacheExtensionlessHLSIsNotACompleteVideo`、`TestEpisodeStartupPrioritizesHLSAudioVideoDependencies`、`TestLegacyAnonymousCatalogAndSessionReuse`），在上一版代码上同样失败，与本次改动无关；CI 里 `go test` 仍是 `continue-on-error` 的信息性步骤。安装程序、界面退出、电视返回键、密钥清理都需要真机确认。

## 0.3.5 下载转换补解密密钥、安装程序关闭检测、合并产物归位（待验证）

**下载的视频打不开**：下载完成后由 Dart 把 HLS 播放列表转成 `<剧名> 001.mp4`，但那条路径**没有把 CENC 解密密钥传给 ffmpeg**（媒体库导出路径传了，所以同一集导出能播、下载的不能播）。Go 侧的就地解密在分片结构不认识时会静默跳过并把密钥往下传（[app_download_cenc.go](native/core/app_download_cenc.go) 的 `nativeDecryptDownloadedCENC` 返回 false，「按普通下载处理」），于是 `-c copy` 原样复制了加密流，包装成合法 MP4 —— 大小正常、容器合法、没有缩略图、播放器全打不开。

修复 [media_library.dart](lib/media_library.dart) 的转换步骤：`plan.decryptionKey` 非空时补 `-decryption_key`（与导出路径一致）；转换后先 `probe` 并 `verifyMediaDuration` 校验，不通过就删掉 staged 文件、**保留原分片**、把任务标记失败。此前只校验「文件大小 > 0」，所以坏文件能静默改名成 `001.mp4` 而分片被清掉。

**安装程序卡在 "Closing applications..."**：桌面版点 ✕ 只隐藏到托盘、进程仍在运行，安装程序替换 `duanjuhui.exe` 时文件被占用；Inno Setup 默认用 Restart Manager 去关闭它，而托盘应用没有可见窗口，关不掉就卡在那一步。现在 [windows_installer.iss](scripts/windows_installer.iss) 设 `CloseApplications=no`、`RestartApplications=no`，并用 `AppMutex=duanjuhui-app-mutex` 检测运行中的实例、提示先关闭；[main.cpp](windows/runner/main.cpp) 启动时创建该互斥体，顺带获得单实例行为（重复启动会显示已有窗口而不是多开一个托盘图标）。

**合并产物不在本剧目录、不叫本剧名字**：合并结果原本固定写到 `<媒体库根>/library/<任务id>/full.mp4`，那个根是应用私有目录，文件管理器看不到。现在改为写进该剧的下载目录，命名 `<剧名> <起始集号>-<结束集号> 合集.mp4`（集号不补零，例如 `云衡归序 1-30 合集.mp4`）；跨文件系统时先尝试改名、失败则复制后删除。媒体库条目为此支持库外文件（[fileFor](lib/media_library.dart) 识别绝对路径），播放、删除、导出、去重都走同一入口。已经合并出来的旧文件保持原样，不迁移。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；`go build` / `go vet` 通过。`go test ./core/` 有一个初始导入就存在、与本次无关的失败用例 `TestLegacyAnonymousCatalogAndSessionReuse`（CI 里 `go test` 本来就是 `continue-on-error` 的信息性步骤）。下载转换、安装程序关闭检测、合并产物归位都需要在真机上确认。

## 0.3.4 搜索态不再混排分类标签（待验证）

**问题**：搜索结果显示在发现页里，而分类标签行（全部 / 推荐 / 真人剧 / 漫剧 / AI 剧 / …）在 [home_screen.dart](lib/home_screen.dart) 中是无条件渲染的，搜索时标签仍压在结果上方。电视遥控按方向键会把焦点送进标签行，停在某个标签上就会把分类切走，搜索内容被换掉。0.3.2 的「焦点跟随只在同一排内部横向移动时生效」只挡住了"路过就切"，挡不住"停在上面"。

**修复**：搜索生效时（输入框非空）不再渲染 `CatalogFilters`，改为一行「“关键词” 的搜索结果」标题加「清除搜索」按钮：

```dart
if (_searching) <标题行> else CatalogFilters(...)
```

搜索态的焦点从输入框按下只能进入结果区，不会落到分类标签上；结果区同时拿到整屏宽度。清除搜索回到浏览态，标签行随之恢复，电视返回键清空关键词的行为不变。

**未验证**：`flutter analyze lib test` 无 error / 无 warning。电视遥控的实际手感需要在电视 / 盒子上确认。

## 0.3.3 修复密码锁写盘被拒的回归（待验证）

**现象**：0.3.1+43 与 0.3.2+44 的站源密码锁弹窗里，四个动作（不使用密码、启用密码锁、解锁、重新锁定）全部失败，弹窗只显示 `Bad state: 无效的本地配置字段`，敏感站源无法用任何方式打开。

**原因**：0.3.1 为「解锁后不再自动隐藏」新增了存档键 `sourceGateUnlocked`，[local_store.dart](lib/local_store.dart) 有四处写入它，但 [local_snapshot.dart](lib/local_snapshot.dart) 的键集合没有登记。`LocalSnapshot.commit()` 第一句是 `if (values.keys.any((key) => !owns(key))) throw StateError('无效的本地配置字段')`，未登记的键让整次写入被拒绝。当时为「缩小改动面」把登记撤掉，反而把功能整个写坏——存档校验与写入点必须同时改。

**修复**：把 `sourceGateUnlocked` 登记进 `globalKeys` 与布尔类型集合，四个写入点恢复可用，「不使用密码」重新回到默认隐藏下的显示路径。

**去掉旧名副本**：0.3.1 起每个 Release 都额外附了三份同内容的 `HongguoTV-<版本>-<架构>.apk`，原计划只保留 0.3.1 一版，但 [package_release.py](scripts/package_release.py) 一直无条件生成，0.3.2 也跟着带上了。现在删除该逻辑，Release 只保留 `duanjuhui-*` 产物；[app_updates.dart](lib/app_updates.dart) 里「优先新名、兼容旧名」的匹配保留不变。

**托盘右键菜单**：0.3.2+44 的托盘图标能出现、窗口也能隐藏进去，但右键没有任何菜单。tray_manager 在 Windows 上不会自动弹菜单，必须在 `onTrayIconRightMouseDown` 里显式调用 `trayManager.popUpContextMenu()`，0.3.2 只调了 `setContextMenu` 登记菜单、从未弹出。现在右键弹出「显示主界面 / 退出」，左键单击仍直接恢复窗口。

**未验证**：`flutter analyze lib test` 无 error / 无 warning。这是运行时错误，静态检查抓不到；能在发布前拦住的只有 Dart 测试——0.3.1 新增的 `source_gate_test` 用例（启用密码锁后重启仍解锁）会调用 `enableSourceGate`，在修复前必然失败。为此 `verify` 现在会跑 [run_dart_tests.sh](scripts/run_dart_tests.sh)（排除 15 个既存失败文件），`source_gate_test` 在纳入范围内，同类回归以后会被 CI 阻断。

## 0.3.2 电视标签焦点跟随修复与桌面托盘（待验证）

**修掉「焦点扫过标签就切换页面」**：此前电视遥控下，焦点只要落在某个筛选标签上，250 毫秒后就自动切分类（左侧导航同理，200 毫秒），于是搜索时按方向键、焦点路过标签就被切走。现在 [catalog_filters.dart](lib/catalog_filters.dart) 与 [home_screen.dart](lib/home_screen.dart) 改为**只在同一排标签内部横向移动时跟随**：用 FocusNode 判断整排是否持有焦点，并记住上一个获得焦点的标签，两者同时满足才切换；焦点从别处（例如搜索框按↓）进入、或整排失焦后都会重置，不再跟随。按确定键显式选择的行为不变。

**桌面版关闭即隐藏到托盘**：新增 [tray_support.dart](lib/tray_support.dart)，用 `tray_manager` 建立托盘图标（复用已经换好的无黑边图标），点窗口关闭按钮只隐藏窗口并保留后台运行，下载不受影响；托盘菜单提供「显示主界面」与「退出」，左键单击托盘图标恢复窗口。「退出」先关闭防误关、销毁托盘，再真正退出。托盘初始化失败时不启用防误关，窗口仍能正常关闭，不会出现关不掉又找不到图标的死局。

依赖只新增 `tray_manager: ^0.5.3`。该版本是传统 CMake 插件，只声明 Windows / macOS / Linux，不引入构建钩子，**安卓三个 ABI 的构建不新增任何原生编译**（最初选的 0.8.0 会把 `cnativeapi` 的 C++ 核心按平台编进安卓，已换掉）。

**未验证**：`flutter analyze lib test` 无 error / 无 warning。标签跟随需要在电视遥控或键盘上确认；托盘隐藏、恢复与退出需要在 Windows 上确认。本轮未在本地构建产物。

## 0.3.1 产物更名、桌面版品牌与安装程序、下载目录、敏感站源默认隐藏（待验证）

**产物统一更名**：APK 由 `HongguoTV-<版本>-<架构>.apk` 改为 `duanjuhui-<版本>-<架构>.apk`，Windows 包由 `zhenguojian-0.3.0+42-windows-x64.zip` 改为 `duanjuhui-0.3.1-windows-x64.zip`，版本串不再含 `+构建号`。为保证老版本的应用内更新不中断，本版**同时附带一份内容相同的 `HongguoTV-0.3.1-<架构>.apk`**，[app_updates.dart](lib/app_updates.dart) 改为**优先新名、兼容旧名**。旧名副本原计划只保留 0.3.1 一版，实现时漏改，实际一直附到 0.3.2，0.3.3 才真正去掉。

**Windows 桌面版品牌对齐**：窗口标题、主程序名（`zhenguojian.exe` → `duanjuhui.exe`）、版本信息里的产品名全部改为短句汇；文件与任务栏图标由旧的红色播放按钮换成「短句汇」品牌图，重新生成 16/24/32/48/64/128/256 多尺寸图标，圆角之外是真正的透明通道，不再出现黑边。[app_branding.cmake](windows/runner/app_branding.cmake) 里按站源开关切换两套名称的分支一并删除。

**桌面版数据与下载目录**：exe 版本信息里不再写 `CompanyName`，应用数据目录由 `%APPDATA%\真果鉴\真果鉴\` 变为 `%APPDATA%\短句汇\`；下载目录由应用私有目录改为 `C:\Users\<用户>\Downloads\短句汇\`，与安卓的 `Download/短句汇/` 对称，在资源管理器里能直接看到。[windows_storage.dart](lib/windows_storage.dart) 在启动最早期执行一次性迁移：新目录为空时把旧目录整体搬过来（含已下载的视频），并把下载位置写入 `download-location.json`；已有下载目录记录的环境不做改动。

**新增 Windows 安装程序**：除免安装 zip 外，另外产出 `duanjuhui-0.3.1-windows-x64.exe`（Inno Setup），默认装到 `Program Files\短句汇`，建立开始菜单快捷方式与卸载程序，桌面快捷方式可选；安装脚本见 [windows_installer.iss](scripts/windows_installer.iss)。

**敏感站源默认隐藏，解锁后保持可见**：[local_store.dart](lib/local_store.dart) 中 `sourceGateOff` 的默认值改回 `false`，未启用密码锁时只显示主站源，其余站源默认隐藏；在历史页连点六次打开密码锁面板，设置密码或输入密码解锁后**解锁状态会保存**（新增 `sourceGateUnlocked`），重启后保持解锁，不再自动隐藏。只有主动点「重新锁定」，或改密码 / 关闭密码功能时才恢复隐藏。此前解锁只在本次运行内有效，每次启动都要重新解锁。

**未验证**：`flutter analyze lib test` 无 error / 无 warning。桌面版的名字、图标、安装程序、数据目录迁移，以及安卓上敏感站源默认隐藏与旧名兼容更新，都需要在真机上确认；本轮未在本地构建产物，Kotlin、CMake 与资源只在打标签构建时编译。

## 0.3.0 下载目录、历史过滤、自动横屏与电视导航（待验证）

**默认下载目录改为系统公共下载目录**：Android 上新建的下载默认保存到 `Download/短句汇/`，在文件管理器、其他播放器和 Emby 中都能直接看到。此前默认落在应用私有目录（`<应用数据目录>/downloads`），只有本应用访问得到。

**需要「所有文件访问」权限，不做降级**：Android 11 及以上需要 `MANAGE_EXTERNAL_STORAGE`，Android 10 及以下使用 `WRITE_EXTERNAL_STORAGE`。[AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) 补声明这三项权限，[MainActivity.kt](android/app/src/main/kotlin/com/hongguo/tv/MainActivity.kt) 新增 `downloadDirectory` / `storagePermission` / `requestStoragePermission` 三个 `duanju/device` 通道方法，目录名取自新增资源 [strings.xml](android/app/src/main/res/values/strings.xml) 的 `app_label_download_folder`。未授权时**不退回应用私有目录**：点击下载会先弹出说明并跳转系统「所有文件访问」设置页，返回后再次点击即可继续；「下载目录与空间」页顶部也会显示授权入口，并在应用回到前台时自动复查。

**公共目录路径由平台层提供，不由 Go 硬编码**：Go 核心同时运行在 Android 和 Windows 两端，Windows 没有这个公共目录概念，因此目录路径由平台层给出。Go 侧新增 `setDownloadDirectory` 动作，只写入 `download-location.json` 并切换内存中的下载根目录，**不复制任何文件**（与 `moveDownloads` 的整体迁移是两件事），并要求当前没有下载记录与本地任务，避免切换根目录后已有任务的相对路径错位。[core_bridge.dart](lib/core_bridge.dart) 在启动时和每次加入下载前调用它，仅在「尚无下载目录记录」且「没有旧版 `downloads/index.json`」时才切换——已经下载过内容的旧安装保持原目录不动，不会出现下载列表突然清空。缓存目录仍留在应用私有目录。

**附属文件收进 .meta**：下载目录里原本为每个视频平铺的 `.part` 临时文件、`.json` 记录、`*.marker` 进度标记，全部移入隐藏子目录 `.meta/`，目录里只留可以直接播放的视频文件，便于整体加入媒体库。读取端保留对旧平铺路径的回退兼容，老下载照常识别。

**历史按当前站源过滤**：[saved_library.dart](lib/saved_library.dart) 新增 `sourceFilter` 参数，[home_screen.dart](lib/home_screen.dart) 把发现页左上角选中的站源传进去——选「全部站源」时显示全部观看记录，选中某个站源时只显示该站源的记录。`ValueKey` 带上站源标识，切换站源时历史列表随之重建；标题同时显示当前站源名称（如「历史 · 42 · 红果」）。追剧页不受影响，仍显示全部追剧。

**自动横屏播放**：移植 hongguoTV 的判定逻辑——播放器**首次拿到真实视频尺寸**时判定一次方向，横屏视频（宽大于高）自动转为横屏全屏，竖屏视频保持竖屏。判定只在每个视频开头做一次，用户手动切换过横竖屏（[_userOrientation](lib/player_screen.dart)）之后不再自动干预，避免和用户操作打架。手机与 iOS 生效；电视本就锁横屏，桌面沿用窗口全屏，都不受影响。

**首页按两次返回键退出**：在发现页且搜索框为空时按返回，第一次弹出「再按一次退出」提示，2 秒内再按一次才真正退出；其他情况（其他页签、搜索框有内容、选择模式）仍按原逻辑先回退一步。

**电视导航焦点跟随与选中样式**：[remote_widgets.dart](lib/remote_widgets.dart) 的 `RemoteTarget` 只在获得焦点时画边框，选中状态改为只画背景——此前选中和聚焦都用主色边框，导致左侧导航与顶部分类同时出现多个红框。左侧导航新增焦点跟随，遥控焦点移到某个页签 200ms 后自动切换（带防抖，避免快速划过时来回跳），焦点跟随不触发连点六次弹出站源密码锁的判定，那个仍只认 OK 键。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；Go 侧本轮已本地通过 `go build` 与 `go vet`，CI 的 `verify` 同样编译校验。Kotlin 与 Android 资源只在打标签构建 APK 时编译，尚未验证。真机上的首次授权流程、`Download/短句汇/` 实际写入、旧安装保持原目录的行为、历史站源过滤、自动横屏判定时机，以及电视遥控的焦点跟随手感均需实机确认；`.meta` 在 Windows 上不是隐藏目录（Windows 资源管理器只按属性隐藏，不认点号前缀）。

## 0.2.9 还原发现与榜单的位置（待验证）

**撤销 0.2.7 的「发现 / 榜单对调」**：0.2.7 曾把榜单提升为导航首项、并把发现移出导航改为右上角图标，现按用户要求整体还原——**发现重回导航首位并作为启动默认页签，榜单回到发现页右上角的图标入口**（`open-rankings`，推开独立的榜单页面）。

[home_screen.dart](lib/home_screen.dart) 的具体还原：删除 `_rankingsTab` 常量与 `_tab == 4` 的嵌入渲染分支，`_tab` 恢复为 `int _tab = 0`；电视左栏首项由榜单改回发现（`(0, Icons.explore_rounded, '发现')`）；桌面 `NavigationRail` 与手机底部导航首项同样改回发现，`selectedIndex` 不再需要 `-1` 表示「无选中项」；删除 0.2.7 新增的右上角「发现」图标（`open-catalog`）；电视返回键与 `PopScope` 的 `canPop` 恢复为以发现页为首页判定。[rankings_screen.dart](lib/rankings_screen.dart) 移除 `embedded` 选项及其内联刷新入口，恢复自带 `AppBar`，榜单芯片行恢复为只列当前站源组的榜单。

**保留不变**：「最近观看」更名为「历史」及其在导航中的次序（发现 / 历史 / 追剧 / 下载，历史排在追剧之前），导航顺序仍由 `_navOrder` 与页签编号解耦给出；黄果榜单修复、电视分类焦点跟随、播放器 1.15 倍速、默认显示全部站源等改动均不受影响。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；Go 侧由 CI 的 `verify` 编译校验。启动页签、榜单图标入口、电视左栏顺序与初始焦点需实机确认。

## 0.2.8 播放器倍速新增 1.15 倍（待验证）

**倍速新增 1.15 倍**：手机横屏倍速菜单与电视「倍速 / 画质」面板都是遍历 [playback_preferences.dart](lib/playback_preferences.dart) 的 `playbackSpeeds` 表渲染，因此只需在 `1.0` 与 `1.25` 之间插入 `1.15`，三个入口即同时生效（`player_menu.dart` 菜单、`television_controls.dart` 电视面板、以及 `playback_preferences.dart` 中 `playbackSpeeds.contains(speed)` 的取值校验）。1.15 未达到 `video_enhancement_policy.dart` 中 `rate >= 1.75` 的降画质阈值，走正常画质增强路径。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；Go 侧由 CI 的 `verify` 编译校验。1.15 倍速在手机与电视上的实际播放表现（音画同步、字幕与弹幕时间轴、长时间播放稳定性）需实机确认。

## 0.2.7 移除皮果、野果停用、默认显示全部站源与电视交互修复（开发快照，待验证）

**背景**：用户反馈野果、帝果、皮果三个站源失效。排查结论是三种不同原因：皮果按 IP 风控、帝果被 Cloudflare 挑战、野果站点改版。

**移除皮果**：皮果（`ptt.red`）直连稳定返回 `403`，开启代理后恢复正常，属站点按 IP 风控而非解析缺陷。用户决定不再保留该站源，本版整源移除——`provider_duanju.go` 的源常量、基址常量、站源表条目、别名映射、主机归属映射与分类表，`provider_duanju_maccms.go` 的目录 / 详情 / 搜索三个分支，`provider_duanju_dispatch.go` 的三处分发列表，以及 [models.dart](lib/models.dart) 的站源登记项全部删除，关联测试的站源清单同步更新。

**帝果改走 Chrome 指纹通道**：帝果（`www.dsd.com.se`）之前不在 TLS 指纹伪装名单内，走普通 HTTP 请求，稳定被 Cloudflare 返回 `403` 加 `Cf-Mitigated: challenge`。现将其加入 [network_browser.go](native/core/network_browser.go) 的指纹伪装主机列表，复用项目已有的 `bogdanfinn/tls-client`（`profiles.Chrome_150`）通道。**注意：Cloudflare 托管挑战要求执行 JS 挑战并取得 `cf_clearance` cookie，仅靠 TLS 指纹未必能通过，本改动属于低成本尝试，不保证生效**；对照组（同机同 UA）花果、网果、伍果均返回 200，发果为 Cloudflare 拒绝，说明并非全局网络问题。

**风控提示**：[network_limiter.go](native/core/network_limiter.go) 新增 `nativeSourceAdvice`，在请求被限流或拦截时按主机追加可操作建议——帝果（`dsd.com.se`）提示「启用了浏览器验证，开启代理也可能无法通过」，避免只给出无指导意义的报错。

**野果未修复（如实记录）**：野果已改版。其首页 `__NUXT_DATA__` 载荷中原本用于定位接口的 `apiBaseURL` 键已消失，取而代之的是 `latest_url` / `transit_page_url` / `permanent_url` / `releases_page` 等站点域名发布通道，以及新的 `api_crypt_ver: "v0"` 请求加密版本。实测四条线路（`able.fzchosdi.cc`、`analyze.buxefaex.cc`、`ability.buxefaex.cc`、`analyze.fzchosdi.cc`）首页均 200 且载荷一致，但全部发布域名的 `/api/*` 都不提供接口——同源 `/api/theater/exploreList` 与刻意编造的 `/api/__nope__` 返回同一个 404 页面，证明该源站不含接口；`transit_page_url` 返回的是 `<noscript>error ..</noscript>` 反爬中转页；32 个 JS bundle 内接口均为相对路径，base 由运行时注入但载荷中并无该值。官方公告亦自述「由于风控原因，域名经常被和谐」（当前最新地址 `ygdj15.com`、永久入口 `yeguodj.com`）。结论：**不逆向其官方 APK 无法定位新接口主机并实现 crypt v0**。用户决定保留该站源但不提供入口，故本版将其标记为**已停用**：[models.dart](lib/models.dart) 的 `SourceSite` 新增 `retired` 标记，`isAvailable` 排除停用站源（不可选择、也不可访问其内容），条目移到站源列表**最末**；[sources_screen.dart](lib/sources_screen.dart) 照常展示该卡片但禁用「更新」「检测连接与播放」按钮，并附「该站源已停用，暂不可选择或访问」说明。

**默认显示全部站源**：[local_store.dart](lib/local_store.dart) 中 `sourceGateOff` 的默认值由 `false` 改为 `true`，未设置过密码锁的环境直接进入「不使用密码、显示全部站源」状态，不再默认隐藏敏感站源。已启用密码锁的环境（`sourceGateEnabled` 为真且盐值 / 哈希有效）行为不变，仍按原逻辑锁定与解锁。

**电视焦点修复**：在电视上用遥控连点 6 次「最近观看」打开站源密码锁弹窗后，焦点停在第一个密码输入框内无法下移。原因是单行 `TextField` 会消费上下方向键（映射为文本选区意图），键盘事件走不到焦点遍历。现于 [source_gate_dialog.dart](lib/source_gate_dialog.dart) 的弹窗外层包一个 `Focus` 拦截上下键并改为 `focusInDirection`，因此可以从输入框走到「解锁」等按钮；左右键仍留给输入框移动光标。

**电视分类改为焦点跟随**：电视上分类行虽然已经是遥控可聚焦按钮，但只有按确定才切换（`RemoteButton` 原本没有暴露 `onFocus`），于是焦点停在某个分类上、内容却还是上一个分类，观感上像「焦点和加载不同步」。现为 [remote_widgets.dart](lib/remote_widgets.dart) 的 `RemoteButton` 增加 `onFocus` 透传，[catalog_filters.dart](lib/catalog_filters.dart) 增加 `followFocus` 选项：开启后焦点落到分类上即切换，并带 250ms 防抖（遥控连续划过只发一次请求）；显式按确定会立即切换并取消待执行项，分类变化时同样取消。手机端仍是点击切换，不受影响；[home_screen.dart](lib/home_screen.dart)、[rankings_screen.dart](lib/rankings_screen.dart) 与 [recommendations_screen.dart](lib/recommendations_screen.dart) 均已开启该选项。

**榜单与发现对调位置**：此前榜单只能从发现页右上角的榜单图标推开独立页面。现把两者对调——榜单升为导航项「榜单」并排在首位（应用启动默认停在该页），发现则从导航中移出、改为右上角图标入口（其他页签下显示 `open-catalog` 图标，作用于切回剧库页；剧库页自身仍保留原榜单图标与独立榜单页面）。导航最终为四项：**榜单 / 历史 / 追剧 / 下载**（「最近观看」同时更名为「历史」，含历史页自身标题）。榜单数据本就一次性拉取全部站源（`rankingBoards()` 全量后按 `initialGroup` 选中），因此嵌入不损失站源切换能力；[rankings_screen.dart](lib/rankings_screen.dart) 新增 `embedded` 选项，嵌入时不再使用自带 `AppBar`，刷新入口移到榜单说明行。[home_screen.dart](lib/home_screen.dart) 的电视左栏、桌面 NavigationRail 与手机底部导航顺序一致；导航顺序由 `_navOrder` 统一给出，位置与页签编号解耦，其余页签编号保持不变（发现 0、追剧 1、历史 2、下载 3、榜单 4）。处于剧库页（发现）时导航四项均不高亮：桌面 `NavigationRail` 传 `null`，手机自定义底部导航传 `-1`。电视返回键与 `canPop` 的「首页」判定同步改为榜单。

**修复黄果榜单无法加载**：黄果（`huangguoai.com`）站点把榜单条目的详情路径从 `/detail/<id>/` 换成了 `/video/<id>/`。榜单页的 JSON-LD 结构未变（`@id` 仍以 `/ranks/<path>/#itemlist` 结尾，条目的 `name` / `position` / `url` 齐全），但 [provider_rankings_parse.go](native/core/provider_rankings_parse.go) 在解析条目时硬性要求路径以 `/detail/` 开头，前缀不匹配即 `return rankingPage{}, failure`——因此是整榜失败并显示「榜单暂时无法加载」，而不是少几项。实测证据：榜单页 `/video/<id>/` 链接 54 处、`/detail/<id>/` 0 处；`https://huangguoai.com/video/2833/` 返回 200（276 KB），旧路径 `/detail/2833/` 已是 301 重定向。现改为同时接受 `/video/` 与 `/detail/` 两种前缀，其余校验（`rankingSourceID`、序号递增、去重）不变。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；Go 侧由 CI 的 `verify` 编译校验。帝果是否能通过指纹通道过挑战、默认显示全部站源后的站源列表与 `--all-sources` 行为、野果停用后的站源管理与选择界面、电视遥控在弹窗内的焦点移动、分类焦点跟随的实际手感（250ms 防抖是否合适）、以及**默认页签改为热榜后受影响的既有测试**（`catalog_categories_test`、`television_test`、`theme_test`、`library_features_widget_test`、`downloads_test` 中假设启动即发现页的用例），均需实机或测试运行确认。

## 0.2.6 下载合集菜单新增一键合并本剧（开发快照，待验证）

**新增入口**：[downloads_screen.dart](lib/downloads_screen.dart) 的下载合集弹出菜单新增「一键合并本剧」，位于「更新本剧」之下。此前合并只能从「下载页右上角图标 → 本地媒体 → 合并已下载分集」进入，需要先在队列页逐部勾选；现在对着某一部剧直接点一次即可整组入队。

**行为**：取该合集内所有**已下载完成**的集（失败与进行中自动排除）整组加入合并队列，随后提示「共 N 集已加入合并队列」并附「查看」按钮，点击跳转合并队列查看看进度。合并本身复用既有链路，连续性校验、断点续跑与 H.264 选项不变。

**边界**：已下载不足两集时提示并拒绝入队；集数不连续时沿用队列原有校验并提示缺哪几集；该剧已在队列中时不重复入队；当前用户无权合并该站源时拒绝并入队。提示条新增可选操作按钮，原有单参数调用不受影响。

**未验证**：`flutter analyze lib test` 无 error / 无 warning；一键入队后的实际合并产物仍需实机确认。

## 0.2.5 修复同剧共用下载目录导致的互相删除（开发快照，待验证）

**问题**：0.2.4 改为同剧共用一个目录后，下载几乎全部失败。实机表现为 `rename .../<剧名> 003.mp4.part .../<剧名> 003.mp4: no such file or directory`，以及部分集报「本地文件缺失，请重新下载」。

**根因**：[app_download_transfer.go](native/core/app_download_transfer.go) 在下载计划指纹变化时会执行 `os.RemoveAll(directory)` 清理旧产物。每集独立目录时该操作只影响自己，改成同剧共用目录后就变成**删除同剧其他集的文件**，包括其他集正在写入的 `.part`。默认同时下载 2 集，两集互相删除对方的临时文件，于是全部失败。同一处还有第二个问题：HLS 顶层播放列表固定命名为 `index.m3u8`，同目录下会互相覆盖，且集数缓存里两处 `result.file != "index.m3u8"` 的判断随之失效。

**修复**：下载指纹标记改为**按集隔离**（`.bundle-001`）并在标记里记录该集文件清单，指纹变化时只清理这一集的播放列表、分片、`.part` 和 `.json`，不再删除整个目录；HLS 顶层播放列表改为按集命名（`<剧名> 001.m3u8`），`downloadBundle` 接收目标名以保证写盘文件名与下载记录一致；`discardDownloadMedia` 改为通用递归清理；播放列表判断改用后缀而非硬编码文件名；[media_library.dart](lib/media_library.dart) 的转码显式指定 `-f mp4`，避免 `.part` 扩展名影响封装格式推断。

**验证**：本地无 Go 工具链，Go 侧改动由 CI 的 `verify` 编译校验（`go build` / `go vet` / `go test` / `flutter analyze` 全部通过）。用户 2026-10-16 已实测 0.2.5：同剧多集下载正常，原先的 `rename ... .part` 报错不再出现。

## 0.2.4 下载按剧名组织与 HLS 转 MP4（开发快照，待验证）

**问题**：下载目录名是 `sha256(剧ID + 集号)` 的前 16 字节（32 位哈希），文件名固定为 `media.mp4` 或 `index.m3u8`，文件管理器里完全看不懂；同一部剧的各集散落在几十个哈希目录中。HLS 站源（多数短剧站源）下载后是一堆分片，既不是可单独使用的 MP4，也无法参与合并。

**目录与命名**：新增 [app_download_naming.go](native/core/app_download_naming.go)。下载目录改为 `<站源>/<剧名>/`，文件名改为 `<剧名> 001.mp4`（三位集号），与用户此前使用的红果短剧下载器命名一致。剧名与站源名会做非法字符净化（`/\:*?"<>|` 与控制字符）、长度截断（60 字符）和 Windows 保留名处理（CON / PRN / NUL / COM1-9 / LPT1-9）。原「按站源分类保存」开关随之移除——站源层级改为始终启用，否则不同站源的同名剧会互相覆盖。

**HLS 自动转 MP4**：[media_library.dart](lib/media_library.dart) 新增 `maybePromoteMedia`，由后台下载服务轮询调用。发现已完成任务的产物是 `index.m3u8` 时，用项目已有的 ffmpeg 做一次流复制（`-c copy -movflags +faststart`，不转码）输出单个 MP4，成功后经新增的 `promoteDownloadMedia` action 更新下载记录并删除原分片。转换失败保留原分片，不影响应用内播放；单集失败不影响其他集。

**校验放宽**：`record.File` 原先被硬编码限制为 `media.mp4` / `index.m3u8` 两个值，现改为校验「安全文件名」（非空、无路径分隔符、无控制字符、长度上限）；`record.Folder` 改为允许任意安全的多级相对路径。**旧记录（哈希目录 + `media.mp4`）继续可用，不需要重新下载或迁移**。

**未验证**：本地无 Go 工具链，**Go 侧改动未经编译**；`flutter analyze lib test` 返回 0 error / 0 warning。命名规则、HLS 转换、旧下载兼容均需实机确认。

## 0.2.3 红果取流编码优先与版本号偏移修复（开发快照，待验证）

**问题**：红果同一集通常同时给出 H.264 与 HEVC 的多档清晰度，取流原先按清晰度排序、只有同清晰度时才偏好 H.264，因此默认起播会落在 HEVC；部分设备 HEVC 硬解花屏或黑屏，软解又吃 CPU。

**播放改为编码优先**：[provider_media.go](native/core/provider_media.go) 新增 `providerCodecRank`（h264/avc/avc1 = 0、未知 = 1、hevc/bytevc1/hvc1/hev1/h265 = 2、bytevc2 = 3，与 `abai569/hongguoTV` 的 `codecRank` 一致）与 `providerMedia.Codec` 字段；[provider_hongguo_media.go](native/core/provider_hongguo_media.go) 的 `multi_video_model` 取流与 [provider_hongguo_native_media.go](native/core/provider_hongguo_native_media.go) 的原生接口取流都改为「编码 rank 升序 → 同编码内清晰度降序」。关键是 [app_playback_routes.go](native/core/app_playback_routes.go)：该函数原先会把候选按清晰度重排、覆盖掉取自流时的编码偏好，现在播放与整集缓存按编码优先排序，更高清晰度的 HEVC 保留为回落线路。

**下载仍优先高清**：下载改走新增的 `nativeDownloadChoices`，排序保持清晰度降序，自动档不会因为编码偏好降低分辨率；其余站源未设置编码信息，排序行为不变。

**显式选清晰度仍然生效**：选 1080P 时会直接落到该清晰度的 HEVC 线路。播放清晰度菜单与下载偏好的「自动」文案由「优先高清」改为「优先 H.264」，与实际策略一致。

**验证**：`go vet ./...` 通过；`go test ./...` 仅 `TestLegacyAnonymousCatalogAndSessionReuse` 失败，已用 `git stash` 在改动前复现同样的失败，确认与本次改动无关；新增 `TestHongguoRoutesPreferH264OverHigherQualityHevc` 覆盖播放编码优先、显式清晰度、下载高清优先三种行为。`dart analyze lib test packages/video_player_android/lib` 返回 0，无 error / warning，改动文件无告警。**版本号偏移修复**：应用内「检查更新」自 0.2.0 起恒定显示「已是最新稳定版本」，与签名和网络无关。根因是 `flutter build apk --split-per-abi` 会按 ABI 叠加 versionCode（armeabi-v7a +1000、arm64-v8a +2000、x86_64 +4000），用 aapt2 实测 0.2.1 的 APK versionCode 为 2033、0.2.2 为 2034；而 0.2.0 的更新器把 Release 构建号当作完整 versionCode（`code = build`，如 34），与已安装的 2034 比较时 `34 <= 2034` 恒成立，于是无论发多少版都判定为无更新。项目原有的 `updateAbiOffsets` 偏移计算在 0.2.0 被误删——当时依据 `pubspec.yaml` 的构建号推断「偏移从未生效」，属从源码推断而非实测 APK，判断有误。现恢复 [app_updates.dart](lib/app_updates.dart) 的 `code = offset + build`、`InstalledApp` 的架构白名单，[UpdateValidation.java](android/app/src/main/java/com/hongguo/tv/UpdateValidation.java) 恢复「已安装与待安装 versionCode 都必须落在 `offset+1 … offset+999`」的校验，两处测试断言同步恢复为带偏移形式；`flutter analyze lib test` 返回 0，无 error / warning。**0.2.0 / 0.2.1 / 0.2.2 三个版本的应用内更新均不可用，需手动安装 0.2.3 一次，从 0.2.3 起应用内更新才真正可用**（验证方式：安装 0.2.2 后检查更新应能发现 0.2.3）。

本轮**未在本地编译、未出包、未在真机验证**：H.264 优先能否减少黑屏与花屏、以及 720P H.264 与 1080P HEVC 的画质取舍需实机确认。

## 0.2.2 下载解密与合并导出 MP4（开发快照，待验证）

**问题**：此前下载保存的是 CENC 加密的原始分片，只能在应用内经本地流服务解密播放；拿出去是密文，合并产物又是 `.mkv`，等于下载了却用不上。

**下载即解密**：新增 [app_download_cenc.go](native/core/app_download_cenc.go)，复用播放链路上已有的 CENC 能力（`parseCENCMP4` + `cencIndex.transform`，base 取 0 即整文件解密），在 [app_download_transfer.go](native/core/app_download_transfer.go) 落盘后把 `media.mp4` 还原为明文。全部候选解密成功时清空下载记录里的密钥，本地播放与合并随即走明文路径；结构不支持时保持原文件不动，不阻断下载。

**合并产物改为 MP4**：合并输出原先硬编码为 `full.mkv`（[media_merge.dart](lib/media_merge.dart)），现改为 `full.mp4`，并补 `-movflags +faststart`；未转码的 HEVC 额外加 `-tag:v hvc1` 以兼容 Apple 系与部分剪辑软件。Emby 导出与归一化中间文件仍用 mkv，不受影响。

**合并转码 H.264**：红果等源是 HEVC 编码，`MergePlan` 原有策略是「统一到多数派编码」——全集同为 HEVC 时不转码，产物仍是 HEVC，剪辑软件兼容性差。新增 [下载偏好](lib/resource_settings_screen.dart) 里的「合并时转码为 H.264」开关（默认开启，属 [download_preferences.dart](lib/download_preferences.dart) 的 `mergeH264`），开启后所有分集统一走 libx264 并把像素格式规范为 `yuv420p`（源为 10bit 时必需），输出标准 H.264 MP4；关闭则保持原有的原编码直拼，速度更快。

**已有下载需重新下载**：已经存到磁盘的加密分片不会被自动转换，需删除后重新下载才能得到明文产物。

本轮**未在本地编译或运行测试**。解密后的文件能否被系统播放器与剪辑软件正常导入、HEVC 转 H.264 的画质与耗时、以及合并产物在剪辑软件中的实际表现均需实机确认。

## 0.2.1 更名短句汇、品牌图与详情页预取（开发快照，待验证）

**更名**：显示名由「红果TV」改为「短句汇」。Dart 侧 [app_build.dart](lib/app_build.dart) 的 `appName`、Android 的 `appLabel`、更新页标题与 Release 标题同步更新。更新页原先硬编码品牌名，现改为引用 `appName` 常量，避免以后再改时漏改。

**图标与横幅**：应用图标 `drawable-nodpi/hongguo_logo.png`（512×512，经 [app_icon.xml](android/app/src/main/res/drawable/app_icon.xml) 生效）与五个密度的 `ic_launcher.png`（192 / 144 / 96 / 72 / 48）由用户提供的 640×640 源图按 LANCZOS 缩放生成并保留 alpha；Android TV 横幅 `drawable-xhdpi/tv_banner_hongguo.png`（640×360）替换为同批新图。

**详情页预取**：对齐 `abai569/hongguoTV` 的秒播做法，取流不再等到进入播放页才开始。详情页数据就绪后立即对「上次观看的集 / 第 1 集」发起预取（[detail_screen.dart](lib/detail_screen.dart)），加载页在算出目标集后也并行预取（[playback_launch_screen.dart](lib/playback_launch_screen.dart)）；预取器跨页面传递，播放页首集命中即直接起播，未命中则自动退回正常取流。`PlaybackPreloader` 新增 `hasPending`，首集在预取仍在途时会等待（1200 ms 超时兜底），不再立刻回退。红果取流路径补上 m3u8 预取（`prepareHongguoPlaylist`），起播少一次远程往返；预取失败不阻断播放。

**未改动**：包名 / namespace 仍为 `com.hongguo.tv`，`appSlug`、APK 文件名前缀 `HongguoTV-` 与各资源文件名保持不变。改包名会导致无法覆盖升级、本机数据丢失并使应用内更新失效；APK 命名前缀被更新器按字面校验，改动同样会中断更新。

本轮**未在本地编译或运行测试**。图标在真实桌面与 TV Launcher 上的显示、覆盖安装后名称与图的刷新、以及预取命中率与起播耗时均需实机确认。

## 0.2.0 更新频道切换与联系方式（开发快照，待验证）

本轮按用户要求做三项修改。

**联系方式**：首页右上角菜单的「关于短句汇」弹窗内新增一行「BUG 反馈 / 定制软件请联系微信：abai531」，点击即复制微信号并提示，手机用户可直接去微信搜索，TV 上也能看到文字。

**应用内更新频道切换**：更新仓库由原 `qq294716498/HongguoTV-Phone-TV-NoAds` 改为本仓库 `abai569/hongguoj`，API 地址、更新页地址与下载地址白名单随之派生。同时把更新校验的正式证书指纹从 `55c3c3…` 改为当前实际发布证书 `d04a0d1a…`。此前已发布的 0.1.8 / 0.1.9 使用新证书签名，而 APK 内固化的期望指纹仍是旧值，`检查更新` 会在读取已安装信息时直接失败；本次修正后新版本的更新功能才与发布签名一致。

**版本号比较规则修正**：更新器原按「架构偏移 + 构建号」计算期望 versionCode（arm64 例如 `2000 + 32 = 2032`），但 APK 的实际 versionCode 就是 `pubspec.yaml` 的构建号（如 `32`）——两者从未一致，安装校验 `archiveCode == expectedCode` 必然被拒，即能发现新版本、能下载校验，但点安装一定失败。回溯 `app-v0.1.3-24` 至 `app-v0.1.7-29` 的 `pubspec.yaml` 确认构建号始终不含偏移量，说明该偏移设计从未生效，历史文档中「versionCode 2024 / 1024 / 4024」的描述与实际不符。现统一按构建号比较，架构隔离改由三层保证：APK 文件名含 ABI、已安装 ABI 必须等于请求 ABI、APK 包内 `.so` 目录必须与已安装架构一致。

**国内加速镜像轮询**：国内直连 `api.github.com` 与下载域名通常不可用，更新链路改为按镜像轮询。两个方向顺序相反：检查更新**优先直连**，因为镜像出口 IP 由所有使用者共享，GitHub 对未认证请求按 IP 限流（每小时 60 次），实测经 `git-proxy.abai.eu.org` 请求会返回 `API rate limit exceeded`；直连失败才退回支持 API 的镜像。下载则**镜像优先、直连兜底**，依次尝试 `gh-proxy.com`、`ghfast.top`、`git-proxy.abai.eu.org`。镜像地址按「前缀 + 原始 GitHub 地址」拼接，白名单只放行上述三个镜像与官方下载域名，未登记的前缀一律拒绝；安装包仍经 SHA-256 与正式签名双重校验，镜像无法替换内容。实测 `gh-proxy.com` 与 `ghfast.top` 以 206 分段直接回源，`git-proxy.abai.eu.org` 302 到官方下载域名；`ghfast.top` 不代理 API，故不参与检查更新的轮询。

以上改动**未在本地编译或运行测试**，应用内更新的下载与安装流程仍需实机验收；不将源码生成等同于可用成品。

## 0.1.9 红果取流签名补全（用户已确认真机可播）

线上反馈红果取流失败，播放日记显示三条取流路径同时失效：App 接口未返回有效数据、网页入口未提供公开播放地址、备用接口未返回可用媒体与密钥。

代码核对确认根因是 **App 侧签名不完整**：原实现只发送简化 `X-Gorgon` 与 `X-Khronos`，缺少字节系必需的 `X-Helios`、`X-Medusa`、`X-Argus`、`X-Ladon`；同时仍在调用旧的 `video_model` 接口，未跟进 `multi_video_model` 与 `fallback_api` 两段式取流，也没有 spade 播放地址解密。

本版自 `hongguo.cjs`（DRPY 插件）移植全套签名到 Go，新增 `provider_hongguo_medusa_tables.go`、`provider_hongguo_medusa_proto.go`、`provider_hongguo_medusa_hash.go`、`provider_hongguo_medusa_cipher.go`、`provider_hongguo_medusa.go`、`provider_hongguo_media.go`：

- **X-Gorgon** 改用变种 RC4（KSA 只覆写不交换）与半字节变换；**X-Helios** 走 34 轮表扩展与 64 位异或链；**X-Medusa** 走手写 protobuf + 变种 MD5 三分支哈希 + 自研 AES 变体（S 盒按 `khronos` 低两位分四段）；**X-Argus**/**X-Ladon** 使用取流接口的时间戳简版。
- 请求参数按客户端原始顺序拼接（Go 的 map 会重排键，故改用有序切片），URL 编码对齐 `encodeURIComponent`（`+` 转 `%20`、`%2A` 保留 `*`）。
- `_rticket` 逐毫秒抖动，绕过服务端不接受的 branch 1 签名变体。
- 取流改为 `multi_video_model` 取模型、`fallback_api` 取清晰度列表，新增 spade 播放地址解密（AES-128-CBC + SHA-512 派生），`spade_a` 仍走既有 CENC 密钥派生。
- 原 `video_model` 逻辑保留为 `resolveHongguoLegacyMedia`，新路径失败时自动回退，三级取流顺序不变。

本轮**未在本地编译或运行测试**（按既定流程只做源码整理与归档），仅完成逐行移植核对与符号唯一性检查。用户已在真机确认红果可正常取流播放；清晰度切换、长时间连播与下载链路仍待验证。

## 0.1.7 手机顶部弹幕（开发候选，尚未发布）

手机模式弹幕改为从整个观看区域顶部进入，避开顶部控制栏，竖屏最多 4 行，白色 16px 常规字重，透明度 95%，继续使用内置 Fluent 3D 表情和重复内容的爱心计数。横屏 / 较矮窗口按顶部可用空间减少行数；不改变视频的居中等比显示，不强制裁剪或下移竖版内容。参考图中的横版视频处于竖屏时，弹幕位于视频上方留白区域。

手机滚动使用独立真实时间，长短句以相同像素速度移动，约 10 秒穿过一屏宽度。改变播放倍速、点击快进、拖动进度、前后跳转不推进或重置正在显示的弹幕位置；跳转期间不加入新弹幕，跳转完成后只加入目标时间附近的内容，不补刷跳过的弹幕。暂停和缓冲时停止滚动，退后台、关闭弹幕、换集或切换用户时清除旧内容。TV 原有 2 行、慢速低透明度及 seek 清屏规则保留；桌面原有时间同步规则保留。

本轮源码从 0.1.6+28 归档（SHA-256：a0c6dfb1fa40082756aecfc5861f1f9b0a7a0bb50da916a58d488304f1324692）恢复，基线提交为 944e87b9eab53c60bc505459a78282ef7f3ac378。更新器、自动连播末帧保留和本地表情素材未修改。

补充边界修正：定位尚未结束时，暂停 / 缓冲 / 恢复也直接驱动弹幕动画停止与恢复；仅窗口高度改变导致轨道重排时，同步重置布局时钟与单条动画，避免位置跳回旧轨迹。

本轮 GitHub Actions 已验证：Flutter 默认配置 364 项通过、1 项既有跳过，全站源配置 365 项通过；静态分析无 error / warning，保留 107 项既有 info；Python 23 项及两种 Go `-race` 回归通过，Android ARM64 独立 debug 变体编译通过。已应用 Dart 自动格式补丁，精确提交复验及 Android 原生测试 / lint 待通过。首轮原生测试遇到 Robolectric Android 16 模拟环境要求 Java 21 的环境问题；CI 已调整为应用编译使用 Java 17、原生测试使用 Java 21，不降低测试 SDK 或跳过测试。正式 APK 尚需由仓库所有者配置原正式签名 Secrets 后构建；当前无正式安装包或 Release，不将 debug 编译检查或云端回归等同于实机验收。

## 0.1.6 手机播放交互补充

手机竖屏控制栏自动隐藏后，单击观看区域只唤出控制栏，保持原播放 / 暂停状态；控制栏已显示时仍可单击切换播放 / 暂停。手机竖屏和全屏共用的「+15s」按钮在点击前为暂停时，先完成跳转再自动播放；本来正在播放时继续播放。仍限制在本集时长以内，到达结尾不重新从零播放；未知时长、加载中、锁屏和隐藏控件不可触发按钮。双击快进、进度条定位和 TV 遥控快进保持原行为。

延迟跳转返回时，只有仍为同一集、同一次定位且期间没有更新的播放操作，才恢复播放；后台、退出和跳转失败不补发播放。已补充隐藏 / 显示单击、暂停后快进、连续快进、片尾、禁用触点和延迟返回中断的回归用例。

2026-10-12 本轮集中验证：播放控件 / 手势 / 真实页面连线 39 项通过，包含 12 项新增回归；最终合并源码的全站源 Flutter 全量 357 项通过，默认单站源 356 项通过、1 项既有跳过；播放、返回和弹幕专项均已计入全量。150 个 Dart 文件格式检查通过，工作流范围静态分析无 error / warning，保留 107 项既有风格 info。Python 全量 23 项通过，其中原生 Java 更新策略 / 安装会话包含 54 个断言；两种 Go 全量 `-race` 分别为 146 / 145 项测试及子测试通过、1 / 2 项既有跳过，无竞态。Android 更新安装包查询补充显式 `Array<Any>` 类型，解决 Kotlin 对文件名与文件大小混合数组的类型推断编译错误；复验更新专项 30 项与 Python 20 项 / 原生 54 断言通过。修正后应用 Kotlin / Java 集成编译通过。应用 lint 随后发现两项来自 0.1.5 的既有兼容性错误，经用户同意进行最小修正，说明见下一节。APK 构建、签名和安装包校验状态以随包校验报告为准。未连接真实手机 / TV，不把合成回归当作实机验收。

## 0.1.6 弹幕标签与本地图片表情

补全包含 `[爽]`、`[怒]`、`[撇嘴]` 的已知括号表情名称，共 231 项；保留原有 58 项含义映射，新增 173 项。识别成对的 `[]`、`【】`、`［］` 及英文名称大小写别名。普通正文中的“爽”“怒”、未知名称、不匹配括号和既有 Emoji 的文本含义保持原样。手机与 TV 使用同一转换链路，既有去重、字幕时间、字号、透明度和速度规则不变。

按用户对系统表情外观的反馈，显示改用随应用内置的 Microsoft Fluent Emoji 3D 图片。144 个不同图形覆盖全部 231 项名称，原始 PNG 合计 5,239,895 字节。它们是获得 MIT 许可的独立素材，不是原平台私有表情的复刻或下载；完整许可证及固定来源清单随资源打包，应用“关于”的许可列表可查看 Microsoft Fluent Emoji 许可。

图片只从本地资源加载，播放时不请求素材网络。每个弹幕层最多保存 144 张、每张不超过 64×64 像素的解码图片，像素内存上限 2.25 MiB；最多同时解码 4 张，退出释放缓存并丢弃迟到结果。文字解析缓存有条数上限，不在每个动画帧重复扫描未变化的数据。图片与文字共用占位宽度计算，混排不因加载完成改变弹幕轨迹；尚未解码或资源加载失败时保留系统文本回退，不把缺图显示成空白。实际设备字体回退和图形显示仍需实机确认。

弹幕专项 54 项通过，包含 24 项新增覆盖；逐项校验全部 144 张图片的上游 Git blob SHA-1 与固定 SHA-256。合成 Flutter 实际混排截图已检查。测试初次等待方式阻塞了模拟异步图片加载，调整测试泵帧后通过；另一次测量断言发现主题继承字间距导致宽度相差 3px，生产渲染改用明确样式后复验通过，保留失败与最终日志。以上不能代替真实手机 / TV 验收。

## 0.1.6 Android 返回与系统栏兼容性补充

最低系统仍为 Android 8.0（API 26）。将只在 API 27 及以上存在的浅色导航栏图标属性放到 `values-v27`，公共状态栏与导航栏主题共用原设置；不提高最低版本、不改变新系统的颜色策略。移除自定义旧 `onBackPressed` 覆写，显式启用系统现代返回回调，交由当前 Flutter 引擎处理完整的开始 / 进度 / 取消 / 提交过程及旧系统兼容；保留 TV 遥控 BACK / ESC 按键分发与播放器既有返回规则。手机全屏先退出全屏再返回上一页，TV 先关闭弹层与控件，再离开播放页。

针对性返回回归 13 项通过，包含取消手势、手机横竖屏、暂停 TV 的弹层 / 控件 / 返回栈和既有遥控行为；新增 3 项资源与回调契约检查后，Python 全量 23 项通过。首轮一项新测试未先启动路由退出动画就断言移除，补齐测试帧后复验通过，没有改变生产行为或放宽断言。应用 Kotlin / Java 集成编译通过，应用 lint 无 error、21 项 warning，其中 1 项是旧系统不使用 API 33 现代返回 opt-in 属性的预期提示；没有屏蔽检查。播放器 Android 原生 141 项测试重新执行通过，插件 lint 无 error / warning、1 项既有基线提示。以上不是 Android 8.0 / 16 或 TV 真机验收。

## 0.1.6 应用更新（本地测试候选，尚未发布）

新增 Android 手机 / TV 共用的软件更新页：启动和恢复前台时异步检查本仓库的 GitHub 稳定 Release，正常结果缓存 12 小时，失败后在本次运行中至少等待 1 小时再自动尝试；关于和设置中可手动检查。首页只显示新版提示按钮，不弹窗、不停止播放，也不会自动下载。设置可关闭自动检查。首次从 0.1.5 或更早版本升级到带更新功能的版本，仍需手动安装一次。

用户查看版本、更新说明、架构和大小后点击下载，可取消 / 重新下载。临时文件保存在应用私有缓存，未完成文件使用 `.part`，成功下载后逐项核验大小、SHA-256、包名 `com.hongguo.tv`、当前正式证书、实际 Android 版本编号和已安装 ABI；没有校验信息或不匹配时拒绝安装。显示版本号只用于展示，更新比较不使用历史显示回退字符串。安装前再次核验，不把 64 位设备上的 32 位应用直接换为另一架构。APK 元数据解析和 SHA-256 在原生工作线程执行。

仅允许 HTTPS 本仓库精确发布附件地址以及受限的 GitHub 官方附件重定向；不放宽播放器已有的网络策略，不使用第三方代理或内嵌令牌。GitHub 不可达、限流、非稳定版、缺包或校验失败均明确显示失败并允许手动重试。此版本保持全部现有站源、开关、默认行为及播放后端不变。此公共更新频道用于本项目现有全部站源正式构建；单站源构建在 Dart 编译标志和 Android 原生编译标志两层拒绝使用它，避免升级时改变站源范围。

点击安装后，由 Android 系统显示确认界面。若缺少安装权限，先展示说明，用户再点击进入系统设置；返回后仍需再次点击安装，不会代替用户授权。取消 / 返回不代表安装成功，可回到更新页重试。安装器请求按独立代号隔离，旧回调不能结束新请求。下一次启动清理中断的部分下载；只有实际已安装版本达到之前提交给安装器的编号，才清理对应完整 APK。安装可能让系统重启应用，请在安装前保存或结束播放；不自动强停、卸载或删除观看记录。

发布契约：稳定 tag 必须为 `app-v<三段版本>-<构建号>`，例如 `app-v0.1.6-28`；全部站源 Android 附件由打包脚本生成 `HongguoTV-<三段版本>-<ABI>.apk`，分别为 `arm64-v8a`、`armeabi-v7a`、`x86_64`。构建号当前限定 1–999，实际版本编号分别为构建号 + 2000 / + 1000 / + 4000。GitHub Release API 必须提供附件大小、`sha256:` digest 和 uploaded 状态；发布后应验证这三项。公共频道固定为本仓库，不回退到上游。私有仓库需要另行设计授权分发，不能在 APK 内放 GitHub 密钥。

应用更新冻结快照验证（手机播放补充前）：新增更新策略 / 下载传输 / 生命周期 / 手机与 TV 页面专项 30 项通过，包含 TLS / 重定向、限流、压缩、大小、缺失 hash、版本 / ABI、取消与重试、安装权限返回、旧安装回调、路由离开和单站源隔离。全站源 Flutter 全量 316 项通过，默认单站源 315 项通过、1 项既有跳过；工作流范围静态分析无 error / warning，保留 107 项既有风格 info。Python 全量 20 项通过，其中原生 Java 校验 / 安装会话回归包含 54 个断言；这些是纯策略与生命周期测试，不能代替 Android PackageManager、系统安装器或真机验收。两种 Go 全量 `-race` 分别为 146 / 145 项测试及子测试通过、1 / 2 项既有跳过，无竞态。最终受影响范围复验 33 项通过。Android 原生集成编译在执行阶段被取消，未得到编译器结果；尚未构建、签名或校验本轮 APK，也未发布 GitHub Release。真实手机 / TV、Android PackageManager、私有安装包提供器及系统安装界面尚未运行验证。

---

## 0.1.5 手机竖屏快进与自动连播末帧保留

2026-10-12 按用户截图，在手机竖屏 / 非全屏底部工具栏的播放按钮右侧增加「+15s」，与已有全屏按钮使用同样的样式、48×48 点击区域和「快进15秒」无障碍名称。复用原 seek 链路，保持播放 / 暂停意图并限制在本集时长以内；时长未知或加载中禁用，禁用触点不会穿透并切换播放状态。锁屏和隐藏控制层不触发快进。窄屏将辅助选项换行，不压缩点击区域；「下一集」仍仅在原有全屏工具栏中显示，TV 遥控焦点逻辑保持不变。连续点击沿用既有 seek 行为，原生尚未完成上一跳时不承诺每次都累加十五秒。

针对 0.1.4 自动播放下一集时短暂黑屏的反馈，保持既有共享起播缓存、预备样本和单播放器链路，仅补充自动相邻集 / 自动续季的画面交接。播放器当前使用直接 Surface / SurfaceView，没有 PlayerView 的保留遮罩开关；原有切集也不主动拆除 Surface，因此增加有边界的末帧保留兜底。

自动切集在替换媒体前尝试捕获并解码上一集已实际渲染的画面，先完成 Flutter 一帧合成，再继续复用播放器。READY 与目标首帧分开处理：每次替换都有独立 transitionGeneration，只在对应媒体的原生实际首帧回调到达后撤下旧帧，不用预加载代号或 READY 冒充首帧。等待期间沿用真实衔接提示；首帧等待失败会撤下旧帧、暂停并交给既有有次数上限的恢复链路，不无限显示旧画面。

保留原有单解码器。手机捕获最长边 960px，TV 仅在自动切集时启用捕获，最长边 640px，至多一张图；原生 JPEG 不超过 1MiB、复制等待 150ms，Flutter 捕获和解码合计最多 250ms。图片只在内存中使用，不写磁盘、不上传、不进入全局图片缓存。图像、编解码对象、等待器在真实首帧、手动换集、暂停 / 退后台、重试、取消、退出时释放；旧结果不能覆盖新集。原有竖屏滑动的 220ms 动画和手势行为不变。

捕获属于尽力兜底：旋转或非方形像素格式、无可用画面、失效 Surface、资源上限或超时会跳过。单次旧帧最多保留 12 秒，包含取址时间；原生真实首帧等待从替换源开始最多 8 秒。网络异常或特别慢的取址仍可显示等待 / 恢复界面，不能保证所有设备上完全没有黑闪。没有真实手机 / Android TV 验收结果。

集中回归：全站源 Flutter 全量 286 项通过，默认单站源 285 项通过、1 项既有不适用用例跳过；手机控件、真实页面连线、滑动和自动连播专项合计 52 项通过，已计入全量。Android 播放插件完整单元测试 141 项通过，原生 lint 无 error / warning，仅保留 1 项既有基线提示；初次检查发现的内部回调访问 lint 问题修正后已完整复验。两种 Go 全量 `-race` 分别为 146 / 145 项测试及子测试通过、1 / 2 项既有跳过，无竞态；Python 脚本 18 项通过。138 个 Dart 文件格式通过，静态分析无 error / warning、107 项既有风格 info。合成页面验证 READY 之后仍显示旧帧，收到目标实际首帧信号后才显示新画面；同时覆盖迟到回调、手动打断、暂停、失败恢复、退出、末集与 TV 捕获上限，不将合成截图当作真机验收。

本轮按用户要求用于正式发布，取代未公开发布的 0.1.5+26 测试候选。包名仍为 `com.hongguo.tv`，沿用原正式证书；ARM64 / ARMv7 / x86_64 的 versionCode 分别为 `2027` / `1027` / `4027`，以支持同签名、同架构覆盖升级。正式包的签名、原生库、完整性、递增版本号、源码快照与 APK 对应关系以随包校验报告为准；不把旧候选包作为本轮成品。既有 [0.1.4 切集优化预发布](https://github.com/qq294716498/HongguoTV-Phone-TV-NoAds/releases/tag/app-v0.1.4-test-25) 与 0.1.3 历史包保留。

---

## 0.1.4 切集优化测试候选

2026-10-11 针对下一集按钮、片尾自动连播和手机非全屏竖滑等待调整共用播放链路。相邻集切换统一复用同一播放器和输出视图，接管已准备或仍在解析的下一集计划，保存进度与旧会话清理不再阻塞已准备内容的起播。当前播放稳定且缓冲足够后立即准备下一集。

整集下载同时发布有边界、经过资源身份校验的起播数据：MP4 前缀与必要解密索引，或 HLS 播放列表、密钥、初始化段和首段。播放器可复用这些已接收数据，整集完整性核验仍独立保留。Android 使用既有 Media3 1.9.2 的预加载管理器预备一集约 1.5 秒的样本，保留同一 ExoPlayer，不预热第二套解码器，也不让原生列表自行跨季。切集按会话、URL、请求头和媒体格式匹配并提升预备源；错误、退出、换画质和作废计划清理对应资源。

手机非全屏滑动在松手时立即提交切集，与 220ms 入场动画同时进行；拖动时尝试在内存中保留当前视频帧作为滑出的旧页，不创建第二套解码器，不将帧写入磁盘或上传。旧帧仅保留在 220ms 滑出动画内，随后释放；捕获不可用时才使用带原集信息的短暂过渡页。目标尚未就绪时仍显示真实等待状态，不无限冻结旧帧冒充新集；缓存未命中、网络或设备解码仍可能造成可见等待。支持快速甩动、反向取消和首末集阻尼。连续提交在当前切换完成前受控阻止，全屏亮度/音量手势保持不变。播放日记新增预备样本结果、请求到准备完成耗时、是否命中预备源，以及原生实际首帧时间。准备完成和真实首帧分开记录，未收到首帧不能当作零间隙成功。

集中回归：全站源 Flutter 全量 246 项通过，默认单站源 245 项通过、1 项既有不适用用例跳过；两种 Go 全量 `-race` 分别为 146 / 145 项测试及子测试通过、1 / 2 项既有跳过，无竞态。Android 播放插件完整单元测试 127 项通过，包含真实 Media3 合成媒体的预备周期复用与释放验证；原生 lint 无错误或警告。Python 脚本 18 项通过，135 个 Dart 文件格式通过，静态分析无 error / warning、107 项风格 info。手机滑动专项 20 项通过，检查拖动、提交、过渡中、提前就绪和落定五个合成截图；这些不是实机延迟测量。

这是用户授权的本地测试候选，尚未替换 GitHub 稳定版本。测试包的正式证书、包名、三架构版本号、原生库、ZIP 对齐、完整性及源码快照对应关系以随包校验报告为准；不将未提交源码标为干净发布提交。没有连接真实手机或 Android TV，不把合成测试、控件动画或打包成功当作原版红果/抖音级实机流畅度验收。保留正式包名和生产签名，用于同架构覆盖升级测试。

---

## 0.1.3 全屏播放快捷按钮

2026-10-11 按用户提供的横屏全屏界面，在播放 / 暂停按钮右侧依次增加「+15s」快进十五秒和「下一集」，沿用原有按钮样式、48×48 点击区域和无障碍名称。快进复用既有 seek 逻辑，不超过当前集时长，也不改变暂停状态；时长未知时禁用。下一集复用当前选集播放流程，末集禁用。锁屏、加载中及隐藏控制层不能触发这些按钮。横屏保持同一行，较窄全屏界面将辅助选项放到第二行，避免挤压或溢出；非全屏竖屏控件保持原样。TV 已有相同顺序与遥控焦点逻辑，本次只补充验证，不新增重复按钮。

版本递增为 `0.1.3+24`，继续使用原正式签名、包名、站源与依赖锁文件。前一轮 `0.1.2+23` 尚未上传 GitHub Release，现由本次构建取代，不发布旧候选 APK。新增按钮排列、连点、片尾边界、时长未知、末集、加载、锁屏及解锁、窄屏布局、真实页面 seek / 切集连接和 TV 遥控操作回归；本轮针对性 UI / 手势 / 页面连接测试 23 项通过；全站源 Flutter 全量 226 项通过，单站源 225 项通过并保留 1 项既有不适用用例跳过。两种 Go 全量 `-race` 分别通过 137 / 136 项测试及子测试，保留 1 / 2 项原有跳过，无竞态。Python 脚本 18 项通过，135 个 Dart 文件格式通过；静态分析无 error / warning，保留 107 项原有风格 info。新增测试首轮发现的是测试清理顺序与合成播放器尺寸通知未设置，补齐资源释放及视频尺寸事件后复验通过，没有放宽行为断言。已检查 960×540 横屏及 390×844 窄屏的 Flutter 实际渲染截图；截图使用合成画面，不代表实机运行。

APK 包名仍为 `com.hongguo.tv`，versionName `0.1.3`，ARM64 / ARMv7 / x86_64 的 versionCode 分别为 `2024` / `1024` / `4024`，较上一轮各自递增。沿用正式证书 SHA256 `55c3c3395a00e56e99b8bfd580b14c99618da74db19692a2e42606eb05c47ba9`；同架构正式版可覆盖升级，Alpha 签名不兼容。全部站源标志保持开启，依赖锁文件 SHA256 仍为 `064ad8cf90f71b8e9276449255a2f7af7daeefbd116d8346963e088b84f9f8b0`，官方 Pub enforce-lockfile 通过。本次 GitHub Release 仅附本轮三架构 APK 和 `SHA256SUMS.txt`，源码由相同 tag 的仓库提供，不混入旧候选或签名材料。

未连接真实手机 / TV，未执行实机安装或真实站源长时间连播，不宣称实机验收或零间隙切集。本轮未修改 Android Java / Go 业务逻辑；Android 原生切集及诊断的 8 项回归记录见前一轮，本轮不把它重复计为新执行。

---

## 0.1.2 前一轮候选（云端验证通过，未发布，已由 0.1.3 取代）

2026-10-10 根据最新最终发布要求恢复集中验证，沿用 Flutter 3.47.4 / Dart 3.13.3、Go 1.24.1、JDK 17 和原依赖锁文件。手机与 Android TV 共用同一应用，保留全部站源及既有功能，不更换播放器。

本轮修复：保持亮屏通道短暂失败后允许健康检查重试，旧请求失败不覆盖新状态；复用播放器切集后若时长暂时未知，按受限频率刷新原生时长，更新播放进度、弹幕及预缓冲判断，旧集迟到元数据不能污染新集。补充相应 Flutter / 原生回归。完整回归另查出打开播放器期间的错误在准备完成时被清除，现改为退出加载后处理既有待恢复错误，避免启动失败被当作成功；保持恢复次数与备用线路限制。

发布流程改为检查失败即阻止 Android 和 Release；缺少正式签名立即失败，必须核对已知正式证书指纹，不再输出 debug 签名正式包。发布绑定实际提交，不覆盖既有版本，不再描述未构建的 Windows / iOS 附件。

集中验证结果：全站源 Flutter 全量 219 项通过；单站源 218 项通过、1 项既有全站源专用用例跳过。两种构建的 Go 全量 `-race` 分别为 137 / 136 项测试及子测试通过，分别保留 1 / 2 项原有跳过（真实站源烟测，以及单站源不适用的全站源权限场景），无竞态报告。Python 构建 / 归档 / 签名脚本 18 项通过；134 个 Dart 文件格式检查通过，静态分析无 error / warning，保留 107 项风格 info。测试使用合成数据及本地服务，不访问站源图片。既有 UI、目录分页、聚合分类及媒体规范化测试的旧假设已按当前实现校正，保留具体行为断言；封闭封面缓存失败测试的真实站源回退，显式拒绝非本地请求。

云端 release 已生成 ARM64、32 位 ARM 与 x86_64 三种 APK，包名 `com.hongguo.tv`、versionName `0.1.2`，versionCode 分别为 `2023` / `1023` / `4023`，最低 Android 8.0（API 26）。各 ABI 的 ELF、关键媒体库、TV Launcher、非必需触屏、非调试属性、ZIP CRC、正式签名及 16 KiB ZIP 对齐均通过。全部使用已备份的 0.1.0 / 0.1.1 正式密钥，证书 SHA256 为 `55c3c3395a00e56e99b8bfd580b14c99618da74db19692a2e42606eb05c47ba9`，未新建或公开私钥。ARM64 包可覆盖同架构的 0.1.0 / 0.1.1；旧 Alpha 签名不兼容，不能把卸载当成无损升级。

Android 原生切集及诊断 8 项 Robolectric 回归通过（API 34 / 28，JDK 17），包括 READY 无首帧、未知时长后更新、超时、释放和旧请求隔离；通过启动时加载原版 Mockito agent 适配云端 JVM，没有改变应用依赖或关闭安全校验。完整 Android 插件测试集及 API 36 模拟验证未执行。第一次冷构建 Gradle daemon 中断、一次受控重试未得到完成结果；离线诊断定位缺失的两项官方 AndroidX 依赖后，恢复官方依赖下载并降低云端并发，三架构 release 成功。保留这些初次失败及最终复验日志，不用候选包代替绑定最终源码的交付包。

APK 校验值与精确源码提交由同一 Release 的 `SHA256SUMS.txt` 和 `HongguoTV-0.1.2-validation.json` 提供，源码及验证日志单独附上。未连接真实手机 / TV，实机安装、真实站源长时间连续播放、缓存完成率、切集观感及遥控 / 手势体验尚未验收；自动化验证不能证明所有网络或设备都能零间隙衔接。

---

## 0.1.2-dev.1 重复弹幕合并（源码开发快照，未构建）

2026-10-10 按用户要求仅修改源码，版本递增为 `0.1.2-dev.1+22`。在 0.1.1 切集修复基础上，将同一集相邻 3 秒内、显示内容相同的弹幕合并为一条，重复时显示 `文字 ♥ 3`，单条不加次数。3 秒从该组合首条弹幕时间算起，不因后续重复无限延长；超出时间段的同文弹幕仍正常出现。

合并前仍按原始 ID 去重，分页重叠或重复拉取不会增加次数；相邻分页共同参与合并，切集清空。匹配使用完整显示文字，保留 Emoji 转换并统一多余空白，不把截断后相似的不同长句误合并。爱心旁数字为本客户端收到的合并弹幕条数，不是源站真实点赞数，也不提交点赞。手机与 TV 共用计数显示，保留小字号、透明度、顶部轨道和 TV 每 32 秒一个画面宽度的等速滚动；分页后已上屏的 TV 弹幕原位更新次数，不重新发射。

已补充待运行的合并边界、同 ID 去重、跨分页、换集清空以及手机 / TV 显示用例。按 AGENTS.md 的开发快照流程只做 Dart 格式整理和源码归档同步，本轮不运行回归、不构建 / 签名 APK、不宣称真机验收通过。未修改播放器、缓存、站源、依赖或锁文件；下方 0.1.1 APK 及测试记录属于上一轮，不代表这次修改已出包。

---

# 红果TV 0.1.1 切集等待修复（云端 release 已出包，待实机验证）

2026-10-10 根据“正在衔接下一集”停住的实机反馈，从已交付的 `HongguoTV-0.1.0-source.zip`（SHA256 `3da236a71d14e2f85e948cc93fb0778819e08e16a7a1b33583eab1944de89369`）恢复源码。版本递增为 `0.1.1+21`，保留全部站源、依赖及既有整集预缓冲、TV 弹幕、手机手势等功能。

代码检查发现 Android 切集把播放器暂停后必须等首帧才能恢复播放；已 READY 但没有首帧回调时会等到 30 秒，随后还有同地址冷启动等待。现在已 READY 后最多额外等待 250ms 首帧；没有回调也把真实准备状态返回 Dart，由其按当前前台 / 暂停意图开始播放，日志独立记录 `firstFrame`，不会把 READY 伪称为已渲染。原生未 READY 的切集 8 秒超时，Dart 通道 10 秒兜底；旧 surface / controller 复用路径保留，出错时仍按既有机制重新初始化。

预取缓存交接失败时不再冷启动同一失效 URL，优先重新解析当前集地址；后续恢复次数仍有上限。取址最多 20 秒，取消等待最多 2 秒，迟到结果释放且不能覆盖新请求，过期请求也不能取消当前请求。播放器单次初始化 20 秒，整个打开流程 45 秒兜底，释放等待最多 2 秒。初始化期间的错误不再另外插入并发恢复，失败后明确退出加载状态再恢复；恢复失败显示可重试错误。增加按集号记录的 preload / transition / open / ready 阶段日志。上述是静态检查确认的风险路径修复，缺少本次实机卡住日记，尚不能断言覆盖全部真实故障。

Flutter 相关回归 31 项最终通过，其中切集专项 8 项通过；首次新增 UI 失败测试的虚拟等待只覆盖前 4 秒，增加至覆盖释放和恢复期限的 12 秒后通过。集中静态检查无 error / warning，107 项既有及风格 info。原生 ARM64 全站源核心已重新构建。Android 原生切集 6 项 Robolectric 回归通过（API 34 / JDK 17），覆盖 READY 后缺少首帧、重新进入 BUFFERING、未知时长、超时、释放及替换回复唯一性。原生测试只存在 debug 单元测试任务，首次误用 release 任务失败；Mockito 默认动态自附加在云端 JVM 不可用，改为在同一测试 JVM 启动时加载原版 Mockito agent 后通过，没有修改应用依赖或关闭 TLS / 沙箱。云端 ARM64 release 构建返回 0，Gradle 阶段 186.0 秒。沿用 0.1.0 正式版签名备份，未创建新密钥；本次 APK 已核对与 0.1.0 的签名证书、包名相同且版本号递增，支持覆盖该正式版；旧 Alpha 的签名仍不匹配。未连接真实手机 / TV，不宣称完成真机验证或达到零间隙切集。

交付 `HongguoTV-0.1.1-arm64.apk`，32,371,855 字节，SHA256 `8b002ee9215b31a1edf38f86e48dadc5b5cf2441625a2838c176dc0559d3e1f2`。包名 `com.hongguo.tv`、显示名“红果TV”、versionName `0.1.1`、versionCode `2021`、MainActivity、TV Launcher、非必需触屏、非调试属性均已检查；17 个 SO 全部为 ARM64，关键原生库齐全，原生核心与本轮构建匹配，签名与 16 KiB ZIP 对齐通过。沿用 0.1.0 的图标和 Banner 图像；系统及应用内版本号为 0.1.1。

使用原 Flutter 3.47.4 / Dart 3.13.3、Go 1.24.1、JDK 17、SDK 35 / 36、NDK 28.2.13676358 和既有构建流程，Go 与 Dart 的全部站源标志均为 true。`pubspec.lock` SHA256 仍为 `064ad8cf90f71b8e9276449255a2f7af7daeefbd116d8346963e088b84f9f8b0`，官方 Pub 的 enforce-lockfile 通过。初次工具链恢复时因 Flutter Git 元数据和旧 SDK 路径缺失，Pub / 分析 / 测试启动失败；恢复官方精确 commit 与 tag、生成新 SDK 路径后重新完成检查，未升级应用依赖。源码修改、首次失败及复验日志、包检查报告均随源码包及日志包交付，签名材料不包含其中。

若实机仍卡住，请保留播放日记里的 `[Switch]`、`[Resolve]`、`[Transition]`、`[Recovery]` 段，能够区分地址解析、缓存交接、原生准备或恢复失败。

---

# 红果TV 0.1.0 正式版（云端 release 已出包，待实机验证）

2026-10-09 按用户要求在云端 Linux 生成正式版，源码版本 `0.1.0+20`，APK versionName `0.1.0`、versionCode `2020`（ARM64 分包编号）。显示名“红果TV”、包名 / namespace `com.hongguo.tv`，手机与 Android TV 共用同一个 ARM64 客户端。当前目录从已交付的 Alpha 18 纯源码归档恢复，包含 Alpha 19 的整集预缓冲与 TV 弹幕修复；原项目精确基线仍为 `0e60928514c31a96ade9b31866948f15da5ca2a6`（tag `app-v0.2.64-71`，原版本 `0.2.64+71`）。下方“未打包”记录是此前开发快照的状态。

实际产物 `HongguoTV-0.1.0-arm64.apk`，32,369,807 字节，SHA256 `698d5b1fc454b6a56afb0ffae59f03e0c170fe1dbfc0e1cbcc26bec3b3dbfb40`。保留全部站源、播放器、依赖与手机 / TV 累计功能。本轮正式版调整为版本号、Banner、既有缓存测试的虚拟计时和本 README；依赖声明未改，`pubspec.lock` 与 Alpha 18 / 19 逐字节相同，官方 Pub 的 `--enforce-lockfile` 检查通过。没有全量升级、上游推送或商店发布。

针对性 Flutter 回归共 43 项通过，覆盖整集缓存状态核验、在途交接与连续 20 集切换、TV 弹幕等速 / 播放倍速隔离 / 暂停 / 定位、手机与 TV 亮屏、控制栏、长按、竖屏滑动、跨季和时间电量。首轮只有新增缓存测试因零延迟虚拟计时尚未推进而失败，改为推进 1ms 后三项缓存测试复验通过；应用实现未因此改动。`dart analyze lib test packages/video_player_android/lib` 返回 0，无 error / warning，107 项非阻断风格提示。Alpha 19 的原生合成 MP4 / HLS / CENC 完整缓存、断点续传、关闭源站后读取和独立 FFmpeg 帧哈希 / Range 检查结果与日志保留。验证使用合成数据及 `DISABLE_REMOTE_IMAGES=true`，未请求站源图片。

构建使用 Flutter 3.47.4 / Dart 3.13.3、完整 Eclipse Temurin JDK 17.0.20.1、Go 1.24.1、Android SDK 35 / 36、build-tools 36.0.0、NDK 28.2.13676358、CMake 3.22.1、Gradle 9.3.1。按既有全站源流程的等价步骤执行 `python3 scripts/build_native.py --platform android --abi arm64-v8a --all-sources`、`flutter --suppress-analytics pub get --enforce-lockfile`、`flutter --suppress-analytics build apk --release --build-name 0.1.0 --build-number 20 --split-per-abi --no-pub --dart-define=ALL_SOURCES=true --target-platform android-arm64` 和 `python3 scripts/package_release.py --platform android --abi arm64-v8a --all-sources`。Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 一致。源码归档无 Git 元数据，Go 通过标准 `GOFLAGS=-buildvcs=false` 构建；Flutter 通过 `CI=true`、`BOT=true` 跳过官方 Azure 元数据探测。云端 tar 使用 `--no-same-owner`，Java / Gradle 使用当前环境提供的代理及系统证书库，TLS 校验保持开启。

实际失败及恢复记录全部保留：Flutter 缓存解压尝试恢复不可映射的所有者而失败；初次 Go VCS 状态获取失败；Gradle 残留代理地址不可达；工作区下载的 Gradle ZIP 截断并校验失败，改在云端构建缓存中重新下载并通过官方 SHA256；MPV 插件通过 Java 下载被代理返回 403，同一官方 JAR 经下载后通过原插件 MD5 和 ZIP CRC 检查；预装 Java 17 缺少 javac，完整 JDK 17 下载后通过官方 SHA256；新 JDK 默认证书库不含云端代理证书，通过系统已有证书库修复 PKIX 错误。最终 release 构建返回 0，Gradle 阶段 592.8 秒。既有两个插件的 Built-in Kotlin 迁移警告保留，本次没有改变依赖版本。

APK ZIP CRC、包名、显示名、正式版版本号、MainActivity、`LEANBACK_LAUNCHER`、非必需触屏、非 debuggable、640×360 Banner 均已核对；17 个 SO 全部为 ARM64 ELF，包含 `libduanju_core.so`、`libflutter.so`、`libapp.so`、`libmpv.so`、`libffmpegkit.so`。包内 Go 核心与本次编译的可加载节及 Gradle 去符号产物一致，Dart AOT 中的整集完成日志和亮屏通道、DEX 中的 MainActivity / 亮屏通道已核对。APK v2 签名有效，`zipalign -c -P 16 4` 通过。

本版使用新建独立正式发布密钥，证书 SHA256 `55c3c3395a00e56e99b8bfd580b14c99618da74db19692a2e42606eb05c47ba9`。此前 Alpha 私钥未能从已重置的云端环境恢复，因此本版不能直接覆盖安装旧 Alpha；卸载旧版会清除其本地数据。正式签名材料单独私密备份，不混入普通源码、APK 附件或日志包。原项目包名不同，仍可与原项目共存。

沿用既有果实播放图标设计，TV Banner 的副标题从 `0.1.0 ALPHA` 改为 `0.1.0`。内置图像编辑的要求是“只替换副标题，保留红色果实播放标志、绿色叶子、深蓝背景、白色红果TV名称与既有布局，不新增宣传语”；输出按 Android 资源尺寸整理为 `android/app/src/main/res/drawable-xhdpi/tv_banner_hongguo.png`（640×360），中文字形已检查。图形来自此前临时设计的重制与本轮编辑，不是恢复早期已丢失的参考图片。

没有连接真实手机或 TV：本版完成自动化与安装包检查，安装、真实站源长时间连播、缓存完成率、切集观感、蓝牙音量及设备弹幕效果仍需实机验证。正式版是本次版本与 release 构建标识。按 `finish_task.py` 归档和 `sync_source.py --check` 校对，源码包排除签名私钥 / 密码、SDK、缓存、APK / SO 和其他编译产物；完整过程日志单独交付。

---

# 红果TV 0.1.0 Alpha 19 整集预缓冲与 TV 弹幕速度（此前源码快照，正式版已包含）

2026-10-09 在云端 Linux 从已交付的 Alpha 18 纯源码包恢复工作，版本递增为 `0.1.0-alpha.19+19`。本轮实际修改下一集完整预缓冲、状态核验和 TV 弹幕移动速度；保留全部站源、播放器、手机 UI、依赖声明及锁定版本。没有编译或签名新 APK，没有真实手机 / TV 验收。原项目精确基线和 Alpha 18 出包记录保留在下文。

代码检查确认旧预取最多 4 MiB / 6 秒，并可能把只有地址的结果当成“已准备”。现在当前集完整缓冲后立即准备下一集；尚未完整时，在已播放至少 2 秒且当前缓冲领先至少 5 秒后提前启动。任务一旦启动，不因瞬时暂停 / 缓冲通知丢弃。使用独立临时文件复用原下载器，持续接收整集；连接中断按 3、6、12、24、30 秒退避重试，符合验证器条件时续传，失效地址定期重新解析，地址 / 资源身份变化时重新缓存以避免拼接不同文件。没有 4 MiB 或 6 秒上限，不写入用户下载列表，也不把整集放在内存中。

整集状态分为缓冲中、重试续传、完整性核验、已完成。接收完成必须通过 HTTP 结束 / 声明长度、磁盘文件大小、HLS 所选音视频分片 / 初始化段 / 密钥 / 播放列表引用和 CENC 元数据检查；空响应、截断内容和缺失文件不能显示完成。没有 `.m3u8` 后缀的 HLS 地址根据密钥信息或接收内容重新识别并下载完整资源列表，不能把一份播放列表当成完整视频。日志记录 `verified-complete`、已缓存字节数和总量。此处是资源完整性检查，不声称拥有源站未提供的内容校验哈希。已完成结果直接由本机代理读取临时文件，保留原 URL 和会话，下一集不必重新从源站下载；完整本地缓存不因旧的两分钟地址准备期限被丢弃。切集时尚未完成则沿用原在线播放和恢复流程，本次播放不在中途切换到另一份缓存资源，不能保证慢网条件下每次都提前缓存完，也不宣称播放器首帧切换绝对零间隙。退出 / 换剧 / 作废会话会清理临时缓存，异常退出残留在下次初始化时清理。

TV 速度检查确认：旧的 32 秒是视频时间，2 倍速时实际约 16 秒；所有文本在相同生命周期内走完，长句移动速度更高。本轮 TV 改为独立的前台播放计时，同屏所有弹幕使用一致速度，每 32 秒移动一个实际视频画面宽度；长句尾部移出需要更长时间，不额外加速。播放倍速不改变 TV 弹幕速度，暂停 / 缓冲停住，恢复接续；切集、定位、关闭弹幕清理旧轨迹，只显示当前位置附近的新弹幕，避免跳转后旧弹幕突然冲出。保留顶部最多两行、14 号常规字重、55% 白色透明度、Emoji 显示和手机原有弹幕逻辑。

针对性原生检查已实际执行并通过：10 项缓存 / 下载相关顶层 Go 测试（含空响应、截断、错误内容、范围变化等子场景），5 项整集缓存测试的 `-race` 复验，以及 CENC 独立 FFmpeg 音视频帧哈希和 Range / HEAD / 416 对照检查。整集测试使用超过 4 MiB 的合成视频，证明断点续传后全部字节一致；关闭合成源站后，MP4 与 HLS 全部所需资源仍可读取。CENC 整集缓存路径不再请求源站，解密后帧哈希与 FFmpeg 对照一致。初次原生检查因已无用途的 `time` 导入失败，移除后通过。全部只用合成媒体，未请求站源图片。

已补充待运行的 Dart 预缓冲完成 / 地址过期检查，并更新 TV 弹幕等速、倍速、暂停与定位测试。Dart 格式解析完成，但 Flutter 测试和静态类型分析没有执行：重建 Flutter 3.47.4 工具环境的 `flutter pub get --enforce-lockfile` 引导阶段输出 `fatal library error, lookup self`，执行会话随后被自动审批拒绝，原因是依赖解析意外请求云实例元数据地址，可能涉及云凭据，超出了公开依赖下载授权。已停止该路径，未绕过拒绝。不能将原生测试通过当成 TV 界面回归或完整应用验收通过；这份源码仍是待 Flutter 回归、构建和实机检查的开发快照。

原生检查使用 Go 1.24.1；临时 Dart 3.12.0 仅用于源码格式解析，未替换项目锁文件或 Flutter 构建版本。按 `scripts/finish_task.py` 与 `scripts/sync_source.py --check` 归档，排除签名材料、SDK、缓存和编译产物。检查日志单独保存。未推送上游、未发布商店。

---

# 红果TV 0.1.0 Alpha 18 播放时保持亮屏（云端已出包，待实机验收）

用户反馈 Alpha 17 手机全屏播放仍会自动锁屏。代码检查确认：Android 的 LunaExoPlayer 路径未设置窗口保持亮屏标志；Alpha 13 的 `screenBrightness` 仅控制窗口亮度，不能代替防止系统超时熄屏。按 [Android 官方保持屏幕开启方式](https://developer.android.com/develop/background-work/background-tasks/awake/screen-on)，在已有设备通道新增 `setPlaybackScreenOn`，由 MainActivity 管理 `FLAG_KEEP_SCREEN_ON`。不新增权限 / 依赖，不更改系统熄屏时间，不阻止用户主动按电源键锁屏。

手机竖屏 / 全屏及 TV 在前台存在播放意图时保持亮屏，取流、缓冲、自动切集和查找下一季期间持续保持。根据播放意图而不是瞬时 playing / completed 事件判断，避免片尾先释放再申请。主动暂停、播放错误终止、无下一季、退出播放页、用户身份失效时释放；后台 / 画中画由 Dart 状态与 Activity 生命周期双重释放，回到前台按当前播放意图恢复。窗口请求只在状态变化时发送，复用既有健康计时器核对状态；没有新增常驻计时器、后台锁或系统设置写入。

版本 `0.1.0-alpha.18+18`，真实安装包 `HongguoTV-0.1.0-alpha.18-arm64.apk`，32,322,075 字节，SHA256 `cd4f81bf51a7f236a341a7e213f559f55ba4f61444c27d53ba9914d574ffa711`。显示名“红果TV”、包名 `com.hongguo.tv`、versionName `0.1.0-alpha.18`、versionCode `2018`，沿用既有 Alpha 签名，可覆盖测试。保留 Alpha 17 累计功能、全部站源、播放器、依赖锁文件、新图标与 Banner，未修改原生 Go 业务逻辑。

集中检查覆盖 31 项相关回归：新增 3 项分别验证手机竖屏、全屏和 TV 的亮屏请求、缓冲、延迟下一集、暂停 / 恢复、后台 / 前台和退出释放；既有切集、跨季、播放页及 TV 回归通过。首轮新测试发现片尾瞬时释放亮屏，调整为播放意图后通过；全屏测试补充真实宽高模拟。电量测试在分钟边界可能提前触发请求超时，改为等待实际第二次请求再隐藏，最终 10 项相关复验全部通过，其他 21 项已通过。静态分析 `dart analyze lib test packages/video_player_android/lib` 返回 0，无错误和警告，103 项非阻断风格提示。

全程在云端 Linux 使用既有工具链，执行原生 ARM64 `--all-sources` 构建、`flutter pub get --offline --enforce-lockfile`、`flutter build apk --release --build-name 0.1.0-alpha.18 --build-number 18 --split-per-abi --no-pub --dart-define=ALL_SOURCES=true --target-platform android-arm64` 和既有打包脚本。第一次在 `:app:packageRelease` 因输出目录临时 `.rsync-tmp` 消失失败；仅清理生成的 APK release 输出目录后重试成功，重试 Gradle 阶段 15.6 秒。两次完整构建日志均保留。

APK ZIP 完整性、MainActivity、TV Launcher、非必需触屏、640×360 Banner、17 个 ARM64 SO、核心产物一致性、既有证书 / v2 签名及 `zipalign -c -P 16 4` 均通过；Dart AOT 与 Android DEX 均包含新增亮屏通道。包检查最初还要求私有 Kotlin 方法名出现在 DEX，但发布混淆不保证保留该名字，改为核对稳定的通道协议字符串后通过，初次日志也保留。没有真实手机 / TV，尚未验证超过系统自动锁屏时长的实际持续播放；不能把自动化和包检查当作实机防熄屏验收。

原始基线、云端分支及签名保管方式同 Alpha 17。按 AGENTS.md 完成源码归档与同步检查；纯源码包不包含签名材料、SDK、缓存或编译产物。未推送上游、未发布应用商店。

---

# 红果TV 0.1.0 Alpha 17 集中验证测试包（云端已出包，待实机验收）

2026-10-03 按用户“可以再打包一个测测了”恢复集中检查和实际构建。版本 `0.1.0-alpha.17+17`，真实安装包 `HongguoTV-0.1.0-alpha.17-arm64.apk`，32,321,347 字节，SHA256 `8daf5c9a742c3597ef4cd833639c3ea01158e52c6fd2aaefe9926504e397fadd`。本节为本次出包结果，下方 Alpha 12–17 的“未构建”条目保留为开发过程记录。

本包包含 Alpha 11 后累计的手机全屏时间 / 电量、全屏窗口亮度防护、同剧下一季自动查找与续播提醒、弹幕命名表情转 Emoji，以及 Alpha 17 的预取交接和切集控件闪现优化。保留全部站源、原播放器和手机 / TV 自动适配；沿用 Alpha 8 重新设计的图标及 Banner，不是恢复旧会话中已丢失的参考图。包名 / namespace 为 `com.hongguo.tv`，显示名“红果TV”，独立于原项目；签名证书与此前已交付 Alpha 包一致，versionCode 为 `2017`，可供覆盖测试。

云端 Linux 原目录与分支 `hongguo-tv-0.1.0-alpha`，原始基线仍为 `0e60928514c31a96ade9b31866948f15da5ca2a6`（`app-v0.2.64-71`）。使用既有 Flutter 3.47.4、JDK 17、Go 1.24.1、Android SDK 36 / build-tools 36.0.0、NDK 28.2.13676358 工具链。按既有 `scripts/build_android.py --all-sources --abi arm64-v8a` 的等价流程依次执行原生核心构建、`flutter pub get --offline --enforce-lockfile`、ARM64 release APK 构建和 `package_release.py`；全程使用官方源已缓存依赖，未全量升级。Go 构建参数 `buildAllSources=true` 与 Flutter `ALL_SOURCES=true` 一致；锁文件与 Alpha 17 开发快照逐字节相同。实际 Gradle 阶段 91.2 秒完成，构建返回 0。

集中回归 65 项全部通过，覆盖在途预取交接及超时释放、20 集连续切换与失败恢复、手机 / TV 控制栏、返回关闭、长按和竖屏手势、首页首次加载恢复、弹幕显示、跨季身份匹配 / 取消 / 进度归属 / 提醒，以及时间电量的隐藏停更和迟到响应。使用合成媒体、模拟播放器和 `DISABLE_REMOTE_IMAGES=true`，未获取站源图片。首轮旧测试缺少新增原生亮度通道模拟，产生 9 项等待计时器断言；补齐统一设备模拟后全部复验通过。衔接等待提示的既有测试期望同步为 4 秒，不改变产品实现。`dart analyze lib test packages/video_player_android/lib` 返回 0，无错误、无警告，有 103 项非阻断风格提示。初次分析遇到云端分析缓存只读，授权云端执行后恢复；另一次无范围分析扫入插件自有开发工具 / 测试，因未安装其 Pigeon / Mockito 开发依赖报错，实际应用与插件运行代码的定向分析通过。完整初次和最终日志均保留。

APK 已校验 ZIP 完整性、显示名、包名、versionName / versionCode、`com.hongguo.tv.MainActivity`、`LEANBACK_LAUNCHER`、非必需触屏、640×360 TV Banner；17 个 SO 均为 ARM64 ELF，包含 `libduanju_core.so`、`libflutter.so`、`libapp.so`、`libmpv.so`、`libffmpegkit.so`。包内核心与本次构建后的分配节、Gradle 去符号产物匹配。APK v2 签名有效，证书 SHA256 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`，`zipalign -c -P 16 4` 通过。此对齐检查不等同于所有设备或全部原生库的运行兼容性证明。

没有连接真实手机 / TV，未验证安装、真实站源连续播放、蓝牙媒体音量、系统亮度传感器或设备 Emoji 字形；模拟器 / 自动化通过不代表真实网络下零停顿。当前仍是复用播放器后等待新媒体首帧的衔接，未宣称原生预排队列级别的完全无缝。按 AGENTS.md 执行 `finish_task.py` 源码归档和 `sync_source.py --check`；源码包排除签名私钥 / 密码、SDK、缓存和编译产物，构建日志单独交付。未向上游推送或发布商店。

---

# 红果TV 0.1.0 Alpha 17 连播等待与 UI 闪现优化（仅源码开发快照，未构建）

版本 `0.1.0-alpha.17+17`，包含本轮先完成的 Alpha 16 弹幕 Emoji 转换。继续只修改云端源码，暂不构建、签名、运行分析器或自动化回归，没有新 APK，也没有设备无缝播放验收。

针对下一集切换仍有停顿和 UI 闪现，检查发现：播放停止事件可以在页面切集状态刷新前唤出控制栏；手机绘制逻辑还会因为 playing=false 无条件显示控件；当前集结束时，预取可能仍在完成，原来立即取消并重新取流；切集等待观看进度写入；Dart 与原生切集各调用一次暂停。

本版在有自动连播意图且本季存在下一集时识别片尾交接，保留在途预取，不因片尾的短暂暂停 / 缓冲通知直接取消。切集最多给同一在途预取 1.2 秒完成并移交，超过时仍走既有取流和恢复流程；已准备好的下一集仍立即使用，没有预取任务时不额外等待。所有移交计划按原清晰度 / 剧集身份匹配，过期、超时后迟到、退出或被新切集替换的会话按所有权释放；不同时启动第二个播放器或解码器。

复用播放器切集时先捕获旧集进度，异步保存，减少切集关键路径的等待；其他加载保持原保存顺序。移除 Dart 端重复暂停，原生 `PlaybackTransition.replace` 仍在替换媒体前暂停并等待下一集首帧，保留后台 / 主动暂停意图和既有出错重开机制。手机和 TV 的控制栏不再因片尾短暂停止或切集后的旧播放状态自动弹出，手动暂停 / 点击 / 遥控唤出保持可用。正常衔接时隐藏全屏页附加的返回 / 选集加载 UI；只有等待超过 4 秒才显示小型衔接提示及相关退出入口，返回键始终可用，错误提示仍保留。Alpha 15 的跨季成功提醒继续显示 4 秒，不属于每集切换提示。

这些改动减少可避免的重取流、存储等待和控件闪现，仍不是原生预排的无缝媒体队列。当前实现需等待新媒体准备与解码首帧，网络、编码或分辨率变化仍可能造成停顿，不声称已达到零间隙。保持原生核心、Android 插件源码、依赖声明与锁文件不变；播放器仍使用原实现。仅完成 Dart 格式整理、`finish_task.py` 源码归档与 `sync_source.py --check`，需要用户安排集中构建和连续切集实测。

---

# 红果TV 0.1.0 Alpha 16 弹幕 Emoji 转换（仅源码开发快照，未构建）

版本 `0.1.0-alpha.16+16`。代码检查确认弹幕绘制此前直接使用站源文本，没有解析 `[偷笑]` 等命名表情。手机 / TV 共用弹幕绘制新增常见标记到 Unicode Emoji 的显示映射，例如 `[偷笑]` → 🤭、`[笑哭]` → 😂、`[捂脸]` → 🤦、`[赞]` → 👍、`[爱心]` → ❤️。保留未知标记、普通文字和已经存在的 Emoji；只转换显示内容，不改原弹幕数据、时间点、ID、去重和请求 / 缓存逻辑。

转换在弹幕布局规划时执行，宽度测量与实际绘制使用同一转换结果，避免替换表情后仍按方括号文字宽度计算间距；不在逐帧动画中重复解析。绘制层的 100 字限制改按完整可见字符截断，避免该步骤拆开肤色、变体选择符和组合 Emoji。维持原有手机 / TV 弹幕字号、透明度、顶部范围和速度，不引入表情图片请求、新字体文件或依赖。表情使用系统 Emoji 字体，属于含义对应的通用图形，不是红果官方自定义表情贴图；具体字形及旧系统的字形覆盖仍需实机确认。

继续按用户要求只做云端源码修改，未编译、签名、运行自动化回归或实机测试，没有新增 APK。执行 Dart 格式整理、`finish_task.py` 归档及 `sync_source.py --check`；依赖声明、锁文件、播放器与原生核心未改动。此快照保留 Alpha 15 及此前全部修改，待用户安排集中构建与验收。

---

# 红果TV 0.1.0 Alpha 15 下一季续播提醒（仅源码开发快照，未构建）

版本 `0.1.0-alpha.15+15`，按用户要求补充手机和 TV 的下一季续播提醒。下一季第一集完成播放器加载后，观看区顶部显示“已自动续播下一季”及剧名 / 当前集数，4 秒后自动消失。采用半透明白色小字与文字阴影，不加黑色底板，不弹确认框，不抢触摸或遥控焦点，也不唤出播放控制栏。加载失败或已失效的请求不显示成功提醒；切集、返回、后台或退出播放页时清理提醒和计时器。其余 Alpha 14 自动跨季规则和既有功能不变。

本轮仅云端源码修改、Dart 格式整理、`finish_task.py` 归档及 `sync_source.py --check` 一致性检查；依赖及锁文件不变。继续遵守“先修改，暂不构建”：没有新 APK，没有执行分析器、自动化回归或实机验证，属于待验证源码快照。

---

# 红果TV 0.1.0 Alpha 14 本季播完续播下一季（仅源码开发快照，未构建）

版本递增至 `0.1.0-alpha.14+14`，继续按用户要求只在云端修改源码，暂不编译、签名或运行自动化回归，没有新增 APK。保留 Alpha 13 的手机全屏亮度防护、Alpha 12 时间 / 电量显示，以及此前的全部站源、播放器和依赖。

手机和 TV 共用的播放完成逻辑新增下一季接续。红果源当前季的最后一集正常播放结束后，使用既有季号识别规则，先从本地已知同系列剧集中查找；没有候选时搜索基础剧名。只接受同源、基础剧名归一化后完全相同、季号恰好加一的唯一候选；支持中文 / 阿拉伯数字和“季 / 部”，无季号标题按第一季匹配第二季。有明确季号时不混用季与部。出现多个版本、缺失下一季、详情身份不一致时提示并留在当前剧，不跳季、不跨站源，也不根据模糊标题自动播放。搜索最多五页，整个查找和详情加载共用 25 秒等待上限；网络失败提供重试入口，迟到结果不能切换失效页面。

确认下一季详情和可播放集数后，从第一集、零进度接续，复用当前播放页与播放器，不叠加新页面或新解码器。支持既有 ExoPlayer 首帧衔接，其他播放器沿用原加载流程；标题、当前集、简介、下载、选集、弹幕和局域网播放信息改为跟随当前季，旧季进度按实际打开的媒体所属剧保存，避免跨季时写错观看记录。倍速、画质、全屏、亮度、弹幕设置保留。网络获取和首帧准备仍可能需要等待，本次没有声称跨季绝对无缝或已实机验证。

本季仍标记连载中、仅本地播放、不允许在线回退、本地媒体记录，以及没有既有季关联规则的其他站源不自动跨季；这些模式保留原本季内播放行为。下一季首集为 VIP 时提示手动选择并确认试看，不绕过原确认流程。查找期间返回、操作播放 / 定位、切集、切换用户或退到后台会使待续播结果失效；重复完成事件不会重复进入下一季。

本轮仅执行 Dart 格式整理、`finish_task.py` 源码归档与 `sync_source.py --check` 一致性检查；没有执行分析器、功能回归、Android 构建或设备测试。源码包排除签名材料、SDK、缓存和编译产物，依赖声明及锁文件保持不变。上述行为属于待集中验证的开发实现。

---

# 红果TV 0.1.0 Alpha 13 手机全屏亮度防护（仅源码开发快照，未构建）

版本递增至 `0.1.0-alpha.13+13`，继续遵守用户“先修改，暂不构建”的要求；本轮仅云端源码修改、格式整理和源码归档，不执行编译、签名、自动化回归或实机测试，没有新增 APK。保留 Alpha 12 的全屏时间 / 电量显示及此前全部改动、站源、播放器和依赖。

针对“手挡住前置摄像头附近，全屏变暗”的反馈，代码检查没有发现使用摄像头、光线传感器或距离传感器调暗屏幕的逻辑，也没有使用距离感应熄屏锁。现有代码在用户手动滑动亮度之前仍使用系统默认窗口亮度，因此遮挡光线传感器后由系统自动亮度调暗是可能原因；全屏左半边起始触点无边缘保护，也存在握持触屏误触亮度手势的路径。未获得传感器 / 现场亮度日志，不能把两者中的任一个断言为唯一根因。

手机进入全屏后，保存进入前的窗口亮度覆盖值，以现有窗口亮度或可读的系统亮度设置值初始化全屏亮度，并使用 Android `WindowManager.LayoutParams.screenBrightness` 固定本窗口亮度；手动左侧滑动继续可调。退出全屏 / 播放页、切换 TV 模式或引擎清理时恢复进入前的值（原先为系统跟随时恢复系统跟随）；后台及画中画期间暂时恢复，返回全屏前台后重新应用保留的手动亮度。不改系统自动亮度开关，不新增权限，不调用受限的系统显示亮度控制接口。系统设置值未必等于厂商自动亮度的瞬时实测值，进入全屏时的初始亮度及厂商热保护等行为仍待实机验证。参考 [Android 窗口亮度字段](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#screenBrightness)。

全屏亮度和音量滑动新增边缘保护：起点需离左右边缘至少 32 个逻辑像素、上下至少 24 个逻辑像素，并兼顾可用的安全区内边距；从保护区开始的触点即使滑入画面，也不会变成亮度 / 音量调整。有效画面内仍需原有 28 像素、明显竖向移动才识别手势。竖屏上下滑切集保持原行为。原生端也拒绝非全屏、后台、TV 或画中画中的迟到亮度设置。

已有手势检查中的有效滑动坐标同步移入保护区内侧，但本次没有运行这些检查。执行 Dart 格式整理、`finish_task.py` 归档及 `sync_source.py --check`；源码快照排除私钥、密码、SDK、缓存和编译产物，锁文件不变。此版本仍属未编译、未验收的源码快照，后续由用户安排集中构建和实机确认。

---

# 红果TV 0.1.0 Alpha 12 手机全屏时间与电量（仅源码开发快照，未构建）

按用户本次“先不执行构建，先修改”的要求，只在云端修改源码，版本递增为 `0.1.0-alpha.12+12`，不生成或签名新 APK，不运行编译及自动化回归；已交付的 Alpha 11 安装包保持原样。本条记录不是可安装版本或通过验收的声明。

手机全屏播放控制栏右上角、弹幕和锁屏按钮左侧新增当前手机本地时间（24 小时制 HH:mm）、电池图标、电量百分比及充电标记，使用 12–13px 半透明白色，无额外黑底。随控制栏一起显示 / 隐藏，保留剧名和集数区域，竖屏与 TV 播控不显示此手机状态组件。进入全屏、控制栏再次显示以及回到前台时刷新；显示期间至多每 15 秒读取一次电量，时钟在分钟边界更新，隐藏、后台和退出后停止定时刷新，迟到响应不更新失效页面。

电量通过已有 `duanju/device` 原生通道新增 `batteryStatus` 方法，按 [Android 官方电量读取方式](https://developer.android.com/training/monitoring-device-state/battery-monitoring) 读取系统 `ACTION_BATTERY_CHANGED` 的电量与充电字段；无新增权限、依赖或联网请求，无法读取时显示未知电量而不伪造百分比。全部站源、播放器、手势及 Alpha 11 改动保留，依赖锁文件不变。

本轮只执行 Dart 格式整理、源码收尾归档和同步一致性检查；布局、Android 编译、实际时间 / 电量变化尚未测试，后续由用户安排集中构建与设备验证。

---

# 红果TV 0.1.0 Alpha 11 首页恢复、竖屏手势与切集衔接（云端已出包，待实机验收）

版本 `0.1.0-alpha.11+11`，包名 `com.hongguo.tv`，同一 ARM64 客户端自动适配手机和 Android TV，沿用独立 Alpha 签名，可覆盖此前 Alpha 版本。原始基线 `0e60928514c31a96ade9b31866948f15da5ca2a6`、tag `app-v0.2.64-71`、工作分支 `hongguo-tv-0.1.0-alpha` 保留。全部站源、播放器、依赖和业务功能保留；本轮修改、工具链、测试、编译、签名和归档都在云端 Linux 完成。

首次首页原本已有加载调用，但第一次请求挂起或失败后缺少自动恢复；站源由不可见变成可见、当前 source ID 又未变化时，也可能被原切换逻辑提前返回。现在首次请求最多等待 18 秒，失败后间隔 2 秒、4 秒各自动重试一次；超过次数显示错误与重试入口，不无限重试。加载中提供“立即重试”，取消和旧响应沿用代次隔离，防止迟到结果覆盖新页面。站源恢复可见时显式加载；新增 `[Home]` 日记记录首次加载结果。合成请求的失败恢复、挂起超时、迟到响应和重试上限检查通过，但没有现场冷启动日志，不能确定用户那次首页不加载的唯一原因。

手机竖屏上下滑在左右区域都用于上一集 / 下一集，不再调节亮度和音量。页面跟随手指移动并露出相邻集标题，达到阈值松手后以 220ms 动画切出，未达到阈值则回弹；切集请求期间保留反馈并阻止重复提交。只有全屏时，左侧上下滑调亮度、右侧上下滑调音量。音量从原来的播放器内部增益改为 Android `AudioManager.STREAM_MUSIC` 系统媒体音量，读取实际音量档位并显示系统返回值，同时将播放器内部增益恢复为 100%。固定音量设备或调用失败会明确提示，不显示虚假的调整成功。没有改变音频路由，蓝牙耳机的实际响度仍需设备测试。

自动连续切集与竖屏相邻集切换优先复用同一 ExoPlayer 控制器和输出视图，替换媒体源并等到新视频首帧准备好再结束衔接；不同时创建两套解码器。衔接过程中不再显示原来的全屏黑色加载遮罩，超过 900ms 才显示小型等待提示；旧 Go 播放会话保留到本次切换完成后释放。原生首帧等待有 30 秒超时，失败回退到既有重新初始化与资源恢复流程；后台 / 主动暂停意图、退出和旧结果隔离保留。仍沿用 Alpha 10 的下一集地址及数据预取。此实现减少重复创建与界面闪动，不是原生预排整部剧的无缝播放列表，网络、格式变化和设备解码准备仍可能造成等待，不能保证所有站源零间隙。播放日记新增 `[Transition]` 首帧衔接耗时。

弹幕进一步弱化：TV 14px、手机竖屏 12px / 横屏 14px，字重改为常规，白色不透明度分别为 55% / 62%，减淡阴影并限制大字体缩放。TV 继续只在视频顶部 18% 区域、最多两行、1.0 倍速时横穿 32 秒；手机最多三行、顶部 38% 区域。剧名和当前集数继续使用醒目的白色粗体，不随弹幕缩小。此前手机弹幕开关位置、全屏按钮位置、选集数字对比度、长按抑制点击、重复进入播放防护、TV 返回关闭覆盖层及新 logo 均保留。

云端定向检查：弹幕 / 播放器 / 预加载等一批 27 项通过，补充的完整播放器自动切集集成检查随后通过；最新手机手势 / 首页 / 分类 / 切集一批 23 项通过、1 项既有检查跳过，最后首页小幅收尾后 3 项复验通过。不同批次包含重复检查，不合并为独立检查总数。原生 Robolectric 检查 8 项通过，覆盖首帧等待、超时、替换、释放、Surface 生命周期和解码统计。连续 20 次同控制器切换、失败后释放再创建、后台暂停与退出隔离使用合成媒体和平台替身验证。静态分析无 error / warning，有 17 条导入 / 风格 info；检查不请求站源图片。

过程日志保留了云端受限测试进程无法绑定回环端口后的授权复验、原生检查计时 API 的修正，以及控件检查等待异步释放 / 下一帧绘制后的复验。初轮 APK 构建成功后用户追加了手机手势、系统音量和首页需求，因此未交付初轮包；完成这些修改后清理应用生成缓存并重新构建。额外 DEX 标记检查曾把 Dart 的 `firstFrameMs` 日记字段当成 Java 字段，改为原生实际返回的 `elapsedMs` 后通过；签名和包内容校验没有失败。

保持 Flutter 3.47.4、JDK 17、Go 1.24.1、SDK 35 / 36、build-tools 36.0.0、NDK 28.2.13676358、CMake 3.22.1。使用既有官方 Pub / Maven 缓存，`flutter pub get --offline --enforce-lockfile` 通过，锁文件与 Alpha 10 字节一致，没有升级依赖。等价全站源构建顺序为 `python3 scripts/build_native.py --platform android --abi arm64-v8a --all-sources`、上述锁文件检查、`flutter build apk --release --build-name 0.1.0-alpha.11 --build-number 11 --split-per-abi --no-pub --dart-define=ALL_SOURCES=true --target-platform android-arm64`、`python3 scripts/package_release.py --platform android --abi arm64-v8a --all-sources`。Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 一致；最终 assembleRelease 用时 89.5 秒，返回 0。环境启动器、构建包装脚本与校验脚本随日志交付。

最终 `HongguoTV-0.1.0-alpha.11-arm64.apk` 为 32,308,087 字节，SHA256 `b2206d73da75ea84afc3a7d4929a06c7d8f1862a796bc9c2fda19cb5fba2a81f`。确认 versionName `0.1.0-alpha.11`、versionCode `2011`、显示名“红果TV”、包名、MainActivity、LEANBACK_LAUNCHER、非必需触屏和 640×360 Banner。17 个 SO 全部为 ARM64 ELF，含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so；Go 核心可加载节与构建结果相符，包内核心等于 Gradle 剥离结果。系统媒体音量权限与原生方法、切集桥接标记已核对。APK v2 签名及 `zipalign -c -P 16 4` 通过，证书 SHA256 仍为 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

按 AGENTS.md 执行 `finish_task.py` 与 `sync_source.py --check`，归档干净源码，保留原说明及许可，排除签名材料、密码、SDK、缓存和编译产物；完整成功 / 失败日志随包交付。不推送上游、不发布商店。没有真实手机、Android TV 或蓝牙耳机测试，本版仅完成云端自动化与安装包检查，不能声称已验证安装、全部站源播放或用户设备上的连续切集观感。

---

# 红果TV 0.1.0 Alpha 10 缓冲完成后预加载与标题可读性（云端构建）

版本 `0.1.0-alpha.10+10`，包名 `com.hongguo.tv`，同一 ARM64 APK 自动适配手机与 Android TV，沿用独立 Alpha 签名，可覆盖此前 Alpha 版本。原始 Git 基线 `0e60928514c31a96ade9b31866948f15da5ca2a6`、tag `app-v0.2.64-71`、分支 `hongguo-tv-0.1.0-alpha` 保留。全部站源、原播放器、依赖、业务功能和此前的修复保留。本轮源码修改、验证、编译、签名、校验与归档全部在云端 Linux 完成。

正在播放的当集缓冲覆盖全部时长后，立即准备下一集，不再等待播放到后半段，也不再等待原有 600ms 延迟；未全部缓冲时保留原来的后半段预加载策略。只预备下一集，不创建第二套解码器。取消、暂停、切换剧集、退出和迟到的响应沿用会话隔离与释放处理；预备地址过期后刷新，切集直接提升仍有效的预备会话。新增 `[Preload]` 日记记录集数、触发条件、准备耗时和缓存字节数，便于实机检查是否提前完成。

代码检查发现 CENC MP4 原先虽然预取数据，但解密播放通道仍重新打开上游，没有复用预取数据。现修复为可复用完整缓存或有强 ETag 的同一资源前缀，并在预加载时准备 CENC 元数据索引。读取已缓存前缀无需等待新请求；未缓存的后续部分仍按 Range 读取并校验资源总长度与 ETag，拒绝拼接已变化的远端内容。保留原先最多 4MiB、6 秒、8 次请求及 HLS 预取限制，不下载整部剧。网络速度、源站限制及下一集资源变化仍可能导致切集等待，不能保证所有站源无缝衔接。

手机播放页顶部剧名改为白色粗体并加阴影；“第 N 集”单独显示在第二行，长标题截断不会挤掉集数。320 / 390 竖屏与 960 横屏均检查过，无溢出，原弹幕顶部位置及全屏按钮紧邻播放按钮左侧保留。TV 继续沿用已有白色标题、遥控控制栏、顶部 32 秒慢速弹幕和返回键关闭覆盖层行为。

22 项不同 Flutter 定向检查最终通过，覆盖缓冲完成后提前准备、自动切集复用、地址过期刷新、取消后迟到结果隔离、手机标题和集数样式、三种宽度控制栏与既有播放行为。首次两项纯预加载检查未推进零延迟虚拟计时，修正检查计时后复验通过；另三项控件检查复验并保存合成画面截图。6 项 Go 定向检查通过，包括连续 20 集原生会话、CENC 完整预取后解密播放无需新增上游请求、部分缓存立即读取和变更 ETag 拒绝拼接、Range / HEAD / 416，以及与独立 FFmpeg 解密后的全部音视频帧哈希一致。最后的 ETag 校验调整后，两项 CENC 检查再次通过。静态分析无 error / warning，保留 8 条既有风格 info。检查没有请求或处理站源图片。

沿用 Flutter 3.47.4、JDK 17、Go 1.24.1、SDK 35 / 36、build-tools 36.0.0、NDK 28.2.13676358、CMake 3.22.1。本次使用已有官方依赖缓存，`flutter pub get --offline --enforce-lockfile` 通过，锁文件与 Alpha 9 字节一致。构建按既有全站源流程执行 `build_native.py --platform android --abi arm64-v8a --all-sources`、离线锁文件检查、`flutter build apk --release --build-name 0.1.0-alpha.10 --build-number 10 --split-per-abi --no-pub --dart-define=ALL_SOURCES=true --target-platform android-arm64` 和 `package_release.py --platform android --abi arm64-v8a --all-sources`，Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 一致。云端环境启动器与等价构建包装脚本随日志交付，没有升级依赖或播放器。

第一轮构建返回 0，但包校验发现 APK 二进制清单仍为 Alpha 9，尽管合并清单已更新。未交付该包；清理应用生成的构建缓存并显式指定版本后重新完整构建，最终 assembleRelease 用时 55.8 秒，返回 0。最终包校验确认 versionName `0.1.0-alpha.10`、versionCode `2010`、显示名“红果TV”、包名、MainActivity、TV Launcher、非必需触屏及 640×360 Banner 正确。17 个原生库全部为 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so 和 libffmpegkit.so；包内核心与 Gradle 剥离结果一致，可加载节与本次 Go 构建一致。APK v2 签名与 `zipalign -c -P 16 4` 通过，继续使用独立 Alpha 证书，SHA256 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

实际安装包 `HongguoTV-0.1.0-alpha.10-arm64.apk`，32,289,879 字节，SHA256 `4462b77605561a3184402f1ae1bc126431792808f420d9f84d3fe90ca9e493d3`。按 AGENTS.md 执行收尾归档及同步检查，源码 ZIP 排除签名私钥、密码、SDK、缓存和编译产物；保留原说明和许可。所有实际失败、复验与成功日志一并交付。未推送上游或发布商店。云端完成自动化和安装包检查，没有真实手机 / TV 安装、播放和切集验收，实机效果仍需用户测试。

---

# 红果TV 0.1.0 Alpha 9 手机控制栏、选集可读性与进入播放修复（云端构建）

版本 `0.1.0-alpha.9+9`，包名 `com.hongguo.tv`。继续沿用原始 Git 基线 `0e60928514c31a96ade9b31866948f15da5ca2a6`（`app-v0.2.64-71`，原 pubspec `0.2.64+71`）与独立分支 `hongguo-tv-0.1.0-alpha`。本次源码修改、验证、资源检查、编译、签名与归档全部在云端 Linux 执行。手机与 Android TV 共用同一个 ARM64 APK，保留已有自动设备识别、全部站源、原播放器、依赖、下载与全部业务功能，以及 Alpha 8 的资源加载恢复、原生 Surface 输出、TV 顶部慢速弹幕与返回键处理、新 Logo 和 Banner。

已确认慢网络时重复进入播放的代码原因：原入口每次点击都会等待一次独立详情请求，多个请求返回后各自压入一个播放页面。现在点击立即显示“正在进入播放”，同一个入口在等待期间只接受一次进入请求；取消或系统返回会使旧请求失效，旧响应到达后不会再弹出播放页，也不会解除新请求的保护或关闭新对话框。失败会关闭加载提示并显示错误，用户可以重新选择。用户切换和入口离开也会使旧请求失效，播放页退出后恢复原入口焦点，保留 TV 遥控焦点行为。底层网络请求仍按原仓库的请求超时处理，取消入口通过丢弃过期响应避免全局取消影响其它业务。

手机播放控制栏的弹幕开关从视频右侧移到顶部，适合横向视频在竖屏观看时的上方黑色区域；全屏 / 退出全屏按钮移到下方播放 / 暂停按钮紧邻左侧，倍速、画质、投屏、画中画与横屏选集入口保留。移除顶部重复旋转入口，触摸区域保持至少 48 个逻辑像素。竖屏视频仍保持原有完整画面与布局，不改变裁剪或缩放逻辑。选集按钮明确指定与深浅主题匹配的数字颜色与独立背景，当前集使用暖色底和醒目数字，遥控焦点使用边框与背景变化，避免继承黑色文字导致深色背景上的集数看不清。

32 项云端定向检查通过，覆盖慢详情请求三连点只发起一次请求和一个播放页、取消后允许新选择且丢弃旧响应、失败提示及重试、320 / 390 竖屏和 960 横屏的完整手机控制栏、弹幕顶部位置、全屏与播放按钮相邻顺序和操作、长按倍速释放、原有弹幕控件、手机选集面板、TV 进入 VIP 确认后的遥控焦点和选集网格。浅色与深色主题下普通 / 当前 / 聚焦集数的文字对比度均达到 4.5:1。随后 7 项相关场景复验通过，并从真实 Flutter 控件渲染合成视频和选集面板预览，未请求或处理站源海报。最终静态分析无 error / warning，保留 1 条既有风格信息。首次运行受云端回环网络隔离阻止，以及检查中发现的 TV 焦点问题，均保留真实日志；修复后最终检查通过。

云端沿用 Flutter 3.47.4、JDK 17、Go 1.24.1、SDK 35 / 36、build-tools 36.0.0、NDK 28.2.13676358、CMake 3.22.1。官方 Pub 在线锁文件检查首次被云端网络隔离阻止，随后 `flutter --suppress-analytics pub get --offline --enforce-lockfile` 验证已有官方缓存成功；完整构建中既有流程的依赖获取成功。最终 `pubspec.lock` 与 Alpha 8 字节完全一致，未升级依赖。完整构建使用 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`，Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 由既有脚本同步设置，返回 0，Gradle assembleRelease 用时 81.4 秒。

实际产物 `HongguoTV-0.1.0-alpha.9-arm64.apk`，32,287,051 字节，SHA256 `e19c7f1ab9b0ea21337449a6136ff37d1db49d27e42feb97194feccd38e149ee`。包名、红果TV显示名、版本、`com.hongguo.tv.MainActivity`、TV Launcher、非必需触屏及 640×360 Banner 检查通过，versionName `0.1.0-alpha.9`、versionCode `2009`。17 个原生库全部为 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so；包内核心与 Gradle 剥离结果一致，可加载节与 Go 构建核心一致。APK v2 签名及 `zipalign -c -P 16 4` 通过，证书继续沿用独立 Alpha 签名，SHA256 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

按 AGENTS.md 执行 `finish_task.py` 和 `sync_source.py --check` 归档，源码包不含签名材料、密码、SDK、缓存和编译中间物。完整日志保存至随包交付的构建日志 ZIP。未向上游推送或发布商店。云端完成自动化控件与包检查，未在真实手机或 Android TV 上安装、遥控和连续播放验收，实机结果仍以用户继续测试为准。

---

# 红果TV 0.1.0 Alpha 8 连续切集恢复、顶部慢速弹幕与新图标（云端已出包，待实机验收）

版本 `0.1.0-alpha.8+8`，包名 `com.hongguo.tv`，沿用 Alpha 独立签名，可覆盖 Alpha 1–7。原始基线 `0e60928514c31a96ade9b31866948f15da5ca2a6`、tag `app-v0.2.64-71`、分支 `hongguo-tv-0.1.0-alpha` 已核对；同一 ARM64 客户端继续自动适配手机 / Android TV。全部站源、原播放器、CENC 解密转发、下载、手机竖屏 / 长按、TV 视频输出和依赖保留，未向上游推送或发布商店。

用户反馈是连续播放后，新一集视频资源不加载、停在 0:00 黑屏，重启后暂时恢复；不是自动暂停问题。照片没有本次失败的取流 / 原生异常日志，因此不能证明唯一根因。代码检查确认以下恢复缺口，并已修复：

- `LunaExoPlayer` 运行中收到视频资源 / 解码错误后，原先只写日记，没有向上层发送错误事件。现在发送一次错误事件，触发既有备用线路和重新取流，避免黑屏后恢复流程没有入口。
- 卡住检测原先要求底层 `playing=true`，资源加载失败使其变成 false 后就失去检测。现在依照用户播放意图检测前台无进度，20 秒无进展触发有限恢复；主动暂停和后台不自动重播。画中画状态刷新只有真正改变前后台可见性时才重置检测，避免无变化的状态回调延后恢复。
- 旧播放器原先保留到新一集初始化完成，可能同时占用解码资源；切集现在先释放旧播放器，再初始化新播放器，停止也真正释放资源并清空时长 / 缓冲。初始化最多等待 35 秒，超时释放失败实例并交给恢复流程，下一次重试可以重新创建。
- 最多三次自动恢复中保留一次重新获取播放地址的机会，避免多条旧线路耗尽全部次数；恢复耗尽后保留可操作的重试 / 换集。日记新增 `[Resolve]` 取流方式 / 集数 / 耗时及 `[Recovery]` 动作 / 进度，配合已有 Sniff、ExoPlayer 和 VideoStats 区分取流、媒体初始化与运行中错误。

取流 / 预加载 / 原生播放会话审查没有发现固定播放 8 集、10 集或 16 集后禁止继续的逻辑。播放会话上限 8 是同时存活数量，旧集释放后可继续创建；解析请求结束不会取消已经打开的媒体会话。合成数据验证连续 20 集自动切换、旧播放器先于新播放器释放、最多一套存活控制器，以及 20 次原生会话创建 / 释放后当前流仍可读取。此检查不等于在用户电视 / 用户网络连续观看 20 集，也不能排除具体 CDN、地址过期或设备故障；没有用“偶然网络问题”解释尚未复现的现场原因。

TV 弹幕只占视频画面顶部 18% 区域、最多两行，默认横穿时长改为 32 秒（1.0 倍播放速度时），即 Alpha 7 的四倍时长、四分之一移动速度；这是按用户要求在初次 16 秒方案上再慢一半。碰撞检测与显示时长同步调整，保留暂停、缓冲、定位、倍速同步；手机保持原 8 秒速度。TV 返回键先关闭当前弹窗，再立即隐藏控制栏或定位提示，控制栏隐藏后再次返回才离开播放；新增 Android 原生返回转发，覆盖原生视频视图获得焦点的情况。尚需用户遥控器实测，不把模拟按键检查当作实体遥控验收。

新 logo 为本次重新设计：深蓝底、红色电视形果实、绿色叶片和白色播放三角，替换之前临时图标；没有声称恢复旧会话中用户选定的图片。使用内置 image_gen 生成，项目保存于 `android/app/src/main/res/drawable-nodpi/hongguo_logo.png`（512×512），TV Banner 保存于 `android/app/src/main/res/drawable-xhdpi/tv_banner_hongguo.png`（640×360）。Banner 文字“红果TV / 0.1.0 ALPHA”经缩放后目视核对；原生 app_icon XML 引用新图像。完整英文提示词与原始生成文件路径记录在交付日志的 `logo-prompts.txt`，资源只做 Android 尺寸缩放。

定向 Flutter 检查共 48 项最终通过，含运行中资源错误传递、初始化超时 / 清理 / 重试、连续 20 集、卡住恢复与主动暂停、TV 返回优先级、弹幕速度 / 顶部范围 / 碰撞和既有手机播放行为。最新 32 秒弹幕改动再次通过相关 19 项。原生会话相关 Go 检查 6 项通过。首次检查中的合成播放器未发送 completed=false 和测试平台异步画中画状态回调影响计时已排查，相关复验通过；前者补齐测试替身契约，后者也修正生产代码的无变化可见性重置。所有失败、排查和成功日志保留，测试不用站源图片。定向静态分析无 error / warning，存在既有导入 / 风格 info（及随后已补括号的一条新检查风格 info）。

全部操作在云端 Linux，Flutter3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1 与既有工程一致。官方 Pub / Maven，`flutter pub get --enforce-lockfile` 通过，pubspec.lock 与 Alpha 7 字节一致。实际构建调用 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`，Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 一致。云端工具环境启动器随日志交付，可按自身工具链位置设置路径后复用。第一轮构建虽记录默认 Kotlin / Android 缓存目录只读提示，最终仍返回 0 出包；并非最终失败。用户追加弹幕速度后重新完整构建，最终 assembleRelease 返回 0，用时 51.8 秒。

最终安装包 `HongguoTV-0.1.0-alpha.8-arm64.apk`，32283019 字节，SHA256 `80dcb6f1637297e04469e416af782b7bdebb43d48cad71c738e4d0b346d2f807`。versionName `0.1.0-alpha.8`，versionCode `2008`，显示名、包名、MainActivity、LEANBACK_LAUNCHER、非必需触屏、640×360 Banner、新图标像素及原生返回桥已核对。17 个 SO 全部为 ARM64 ELF，含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so；Go 核心可加载节与构建结果一致，包内核心等于 Gradle 剥离结果。v2 签名及 `zipalign -c -P 16 4` 通过，证书 SHA256 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

按 AGENTS.md 完成源码收尾归档与同步检查；源码包排除签名私钥 / 密码、SDK、缓存、用户照片及编译中间物，保留原项目说明和许可。本轮 Android 原生播放器插件和 Go 业务源码未改动，Go 仅增加会话定向检查。云端没有真实 Android TV / 手机设备；只完成自动化和包检查，不能声称已经解决用户设备连续播放的所有失败，或已经验证安装 / 实际播放。

---

# 红果TV 0.1.0 Alpha 7 TV 视频输出与解码诊断（云端已出包，待实机体验）

版本 `0.1.0-alpha.7+7`，包名 `com.hongguo.tv`，同一 ARM64 客户端继续自动适配手机 / Android TV，沿用 Alpha 独立签名，可以覆盖 Alpha 1–6。精确原始基线 `0e60928514c31a96ade9b31866948f15da5ca2a6`、tag `app-v0.2.64-71` 与独立分支 `hongguo-tv-0.1.0-alpha` 保留。全部站源、取流、CENC 解密转发、下载、弹幕、手机竖屏和长按行为保持；没有替换 ExoPlayer / media_kit，没有向上游推送或发布商店。

用户的 Alpha 6 TV 日志显示 1080p、1.0 倍速，记录区间内前置缓冲 55144ms、缓冲次数 0。关闭弹幕仍有卡帧，所以不能直接归因于弹幕或该区间的网络供给；原日志中的 uiOverBudget / buildPeakMs 是 Flutter 界面指标，并不能证明视频解码丢帧。打开播放日记也可能包含界面峰值；本次没有把截图当成实际 MediaCodec 或硬解验证。

电视默认改用原生 SurfaceView，通过 Flutter 原生混合合成直接显示视频，保留 ExoPlayer 的默认解码器选择与初始化失败时的备用解码器回退。手机继续使用原 Flutter 视频纹理。Android 官方的 [Surface 类型说明](https://developer.android.com/media/media3/ui/surface) 指出 SurfaceView 的帧时序更准确，并推荐用于常规视频及 TV。此项是依据输出链路做出的修正，尚不是用户设备的卡帧根因结论。

[官方 video_player_android 2.12.2](https://pub.dev/packages/video_player_android/versions/2.12.2) 暂不建议默认 platformView，链接的 [Flutter #164899](https://github.com/flutter/flutter/issues/164899) 描述滚动移出视口时视频越过界面的问题。本版只在 TV 固定播放区域启用原生输出，并在同一锁定版本的源码中显式使用原生混合合成，避免视频 Surface 经纹理或虚拟显示转接；Surface 释放时移除回调、解绑匹配的输出，不主动释放由 Android 视图持有的 Surface。换集使用控制器关联的视图 key，避免旧视图复用到新播放器。真实电视的覆盖层、选集弹窗、切集、返回与画中画仍需验收。

TV 播放设置新增默认“流畅模式”和“兼容模式”，后者保留 Alpha 6 的纹理输出。切换会保存偏好并接续当前进度，维持暂停 / 播放意图；其他播放偏好保留，手机不受 TV 输出偏好影响。供出现黑屏、视频遮挡控件或需要对照卡帧时使用，不声称模式名称代表已经通过设备流畅度验证。

播放日记新增 `[VideoStats]`：实际解码器名称、系统硬解标记、视频格式 / 源帧率、累计已渲染 / 丢弃 / 跳过的视频帧、连续丢帧峰值、丢到关键帧次数、解码器初始化耗时 / 次数、平均帧处理偏移、缓冲前置时长及输出模式。播放开始后约 2 秒、每 30 秒和打开 TV 播放日记时采集，按活动播放器 ID 隔离，换片 / 释放清理定时器与旧结果。renderedTotal / droppedTotal 是 Media3 原生视频指标；PlayStats 的 uiFrames / uiOverBudget 仍是界面指标。Android 10 以上由系统 MediaCodecInfo 读取硬解标记，更早版本只报告实际名称并标记 hardware=unknown，不依据名称猜测硬解已启用。原生检查使用的 synthetic 解码器名称只在检查夹具中出现，不是用户电视结果。

依赖声明与其他锁定版本保留，`video_player_android` 从官方托管的 2.12.2 改为 `packages/video_player_android` 内同版本源码补丁，保留原 BSD-3-Clause 许可、作者信息与原有实现。锁文件仅这一项来源和依赖类别变为本地 override，没有升级 Media3 1.9.2 或其他播放器依赖。定向 Dart 检查 19 项通过，覆盖输出选择 / 偏好保存 / 控制器替换与原生诊断、手机手势 / 竖屏、TV 遥控 / 错误恢复；原生 Robolectric 检查 5 项通过，覆盖 Android 9 / 14 的 Surface 生命周期及解码统计跨重启的累加。使用合成数据并禁用站源图片。定向静态分析无 error / warning，原有信息提示保留。

检查过程完整记录：首次误选了不存在的 release 单测任务，改用插件实际提供的 debug 单测任务；首轮依赖下载遇到云端临时代理失效，重试后下载完成。原生单测随后受云端 JVM 自挂载限制导致 Mockito 初始化失败，通过仅用于云端检查进程的已缓存 Byte Buddy premain agent 解决，没有把该 agent 或云端 JVM 参数加进应用。此前失败和最终通过日志都随附，不把检查环境失败当成电视播放故障。

全部源码、资源、工具链、编译、签名与校验在云端 Linux 完成。保持 Flutter3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1，使用官方 Pub / Maven。`flutter --suppress-analytics pub get --enforce-lockfile` 通过；原完整构建命令 `python3 scripts/build_android.py --all-sources --abi arm64-v8a` 返回 0，assembleRelease 用时 93.2 秒，Go buildAllSources=true 与 Dart ALL_SOURCES=true 均启用。

实际 APK `HongguoTV-0.1.0-alpha.7-arm64.apk`，31,971,663 字节，SHA256 `aaa49b5b5a4bd33e7120e830ae5a62c2a9de23ae3fbb1296d4d6ab92c5cdb097`。versionName `0.1.0-alpha.7`、versionCode `2007`。显示名红果TV / MainActivity / LEANBACK_LAUNCHER / 非必需触屏 / 640×360 Banner 已核对；17 个 SO 全部是 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so。包内 Go 核心与 Gradle 剥离结果一致，可加载节与 Go 构建结果一致；原生诊断和输出补丁标记已在 DEX 中核对。v2 签名及 `zipalign -c -P 16 4` 通过，证书 SHA256 仍为 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

按 AGENTS.md 执行 finish_task.py 源码归档和 sync_source.py --check；源码包保留本地插件补丁及必要许可，排除私钥 / 密码、SDK、缓存、用户照片、预览字体、JVM 检查 agent 和编译中间物。图标和 Banner 仍为临时设计，没有恢复用户之前选中的图片。没有真实手机 / Android TV 安装、实际硬解状态、画中画或长时间播放验收，不能声称已经解决用户电视上的全部卡帧。建议覆盖安装后使用 TV 默认输出观察同一片段，如仍卡帧，从“播放日记”复制包含 VideoStats 的文字日志继续判断。

---

# 红果TV 0.1.0 Alpha 6 TV 选择与播放渲染优化（历史云端构建记录）

版本 `0.1.0-alpha.6+6`，ARM64 APK 继续自动适配手机 / Android TV，包名 `com.hongguo.tv`，沿用独立 Alpha 签名，可覆盖 Alpha 1–5。原始基线 `0e60928514c31a96ade9b31866948f15da5ca2a6` 与分支 `hongguo-tv-0.1.0-alpha` 再次核对。本轮针对用户电视截图中的选择异常、榜单条目过大和播放卡顿反馈进行修改；全部站源、依赖、原播放器、CENC 解密转发、下载、弹幕及手机竖屏 / 长按行为保留。

TV 首页站源、榜单站源和集数范围选择改用有高度上限的遥控选择对话框，打开时定位当前选择；方向键显式移动焦点并滚动到尚未创建的行，确认选择，取消后回到原按钮。手机继续使用原菜单。遥控确认键 / 手柄 A / 数字键盘确认使用一致的激活行为，按住确认不重复打开页面。

TV 榜单改为紧凑的遥控列表，正常字体下行高 88 个逻辑像素，封面 46×68，标题和热度保持可读；大字体时行高随之增加。保留原榜单序号、排序、切榜、站源过滤、详情入口、分页与刷新。合成数据在 960×540 布局下完整显示 4 条；方向键可滚到第 24 条，打开正确片子，返回恢复原焦点。“加载更多”在最后一行继续按下时滚入屏幕并取得焦点。

播放优化：TV 控制栏隐藏时不再随位置 / 时长 / 缓冲进度更新重建，缓冲状态变化仍正常显示转圈；弹幕整体加入重绘隔离，保留连续动画、倍速、暂停 / 缓冲同步和开关。视频仍按原比例适配，不根据照片改成裁切放大，不更换播放器或强制指定未经设备验证的解码器。

播放日记新增 `[PlayStats]`，正常播放每 30 秒及换片 / 关闭时记录视频尺寸、速度、缓冲前置时长、缓冲次数 / 总时长、Flutter 界面帧数、超过屏幕刷新预算的界面帧数、构建 / 栅格耗时峰值。计时与回调在换片 / 停止 / 关闭时清理。`uiFrames` 和 `uiOverBudget` 是 Flutter 界面指标，不是视频解码帧数 / 解码丢帧数；没有记录正在使用的 MediaCodec 名称。卡顿若继续出现，请从 TV 播放器的“日记”入口复制新版日志，结合缓冲和界面指标继续判断；电视配置高和照片本身均不能证明问题出在解码。

输出路径核查参考 [Android Media3 的 Surface 类型说明](https://developer.android.com/media/media3/ui/surface) 和 [当前锁定 video_player_android 2.12.2 的官方说明](https://pub.dev/packages/video_player_android/versions/2.12.2)。后者明确暂不建议 Android 使用 platformView，因此此次保留原输出路径，没有把换输出方式标为已解决卡顿。

最终定向检查 26 项通过，涵盖遥控选择、屏幕外行定位、榜单打开 / 返回、集数范围、分页焦点、TV 播控 / 返回 / 错误重试、弹幕动画和缓冲同步、手机原分类 / 榜单行为以及原生播放器适配层的缓冲诊断与换片 / 释放。使用合成数据，不请求站源图片。实际 Flutter 控件生成榜单 / 菜单预览并核对中文与图标；预览字体不进入 APK。首次检查发现新检查参数漏传、旧检查仍依赖旧详情 / 常驻选集流程、未解锁合成隐藏站源，以及分页末行焦点问题；已处理并复验。诊断检查最初在控件测试的虚拟时钟中等待平台释放时阻塞，最终改为真实异步事件的适配层检查并通过；此前失败与中断日志完整保留，不当作设备故障证据。

全部操作在云端 Linux，工具链仍为 Flutter3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1，官方 Pub / Maven。`flutter --suppress-analytics pub get --enforce-lockfile` 通过，依赖锁文件字节未变。原构建命令 `python3 scripts/build_android.py --all-sources --abi arm64-v8a` 完成，Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 保持一致；最终 assembleRelease 返回 0，用时 53.2 秒，构建日志包含此前首轮成功构建。

实际产物 `HongguoTV-0.1.0-alpha.6-arm64.apk`，31,971,331 字节，SHA256 `ba622af00cf4d9015f168397c07cdd0ca92162d2462a3d999927c09777a2b516`。versionName `0.1.0-alpha.6`，versionCode `2006`，沿用原 ARM64 split-per-abi 规则。显示名红果TV / MainActivity / TV Launcher / 非必需触屏 / 640×360 Banner 校验通过；17 个 SO 全部是 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so。包内 Go 核心与 Gradle 剥离结果一致，可加载节与 Go 构建结果一致；v2 签名与 `zipalign -c -P 16 4` 通过，证书 SHA256 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

相对 Alpha 5，Android / Go 原生源码、播放器依赖和锁文件字节未变。此次调整现有 Dart UI / 播放诊断、版本、README 和相关检查，新增两份用于复现用户反馈与诊断生命周期的定向检查。按 AGENTS.md 运行 `finish_task.py` 与 `sync_source.py --check`，源码归档排除签名私钥 / 密码、SDK、缓存、用户截图、预览字体和编译中间物。图标与 Banner 仍为临时设计，并非恢复用户之前选定的图片。未向上游推送、未发布商店。

云端检查通过；没有真实手机 / Android TV 安装、硬件解码丢帧、网络环境或长时间播放验收。不能声称新版已经解决用户电视上的全部卡顿。

---

# 红果TV 0.1.0 Alpha 5 竖屏观看与长按释放修正（历史云端构建记录）

版本 `0.1.0-alpha.5+5`，同一 ARM64 APK 自动适配手机 / Android TV，包名仍为 `com.hongguo.tv`，沿用独立 Alpha 签名和临时图标，可覆盖 Alpha 1–4。原始基线为 `0e60928514c31a96ade9b31866948f15da5ca2a6`，分支 `hongguo-tv-0.1.0-alpha`。本轮按用户截图及类似 HG1 的竖屏观看要求优化手机界面，保留播放器、全部站源、解密转发、下载 / 简介 / 追剧、弹幕、画中画、倍速 / 画质和 TV 交互。

手机长按的倍速提示移到观看区底边，改为 12 号、80% 白色透明小字和轻微文字阴影，去掉黑色矩形底板、描边与大块留白；长按释放立即清除提示，不再弹“恢复倍速”。原倍速仍正确恢复，横屏和竖屏采用相同低干扰提示。

用户追加反馈长按松手容易触发轻点、唤出进度条。原先通过原始指针计时加速，没有让长按和 Flutter 轻点手势互斥；释放后的保护只有 250ms，而单击识别可能等待双击窗口后才执行。现在触屏 400ms 长按识别会在手势竞争中取消该次单击 / 双击候选，释放只恢复倍速，不唤出控制栏或切换播放状态；随后独立轻点、双击和滑动功能保留。

手机未进入横屏全屏时，竖屏观看区占满状态栏和导航安全区之间的空间，不再被常驻选集列表挤压。保持视频原比例，黑色背景与浅色系统图标，播放控制自动隐藏；底部紧凑显示剧名 / 当前集，点选集、简介或下载展开深色底部面板。原三个 Tab、选集分页 / 定位、简介 / 追剧和下载设置保留。面板打开时不缩小视频、不重新加载当前视频、不强制暂停；选集后自动收起，关闭后回到观看。

定向检查 16 项全部通过：竖屏 / 横屏长按释放后，特意等待超过旧 250ms 保护窗口再触发延迟识别，确认不切换播放、不唤出进度条，倍速恢复且下一次正常轻点仍有效；透明提示位置 / 高度、锁屏、滑动定位 / 切集、竖屏安全区与画面高度、面板切 Tab / 关闭 / 切集、画中画及 TV 焦点 / 返回 / 定位等检查通过。使用合成媒体，关闭站源图片请求；手机观看 / 面板 / 长按界面由实际 Flutter 控件渲染预览，预览用字体不加入应用。定向静态分析无 error / warning，保留 8 条既有风格信息提示。首次集中检查发现面板主题参数尚未接齐的编译错误，已修正并完整复验，过程日志保留。

全部修改、验证、构建和签名均在云端 Linux 执行。工具链与之前一致：Flutter3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1，官方 Pub / Maven。先执行 `flutter --suppress-analytics pub get --enforce-lockfile`，再执行 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`；Go `buildAllSources=true` 和 Dart `ALL_SOURCES=true` 由原脚本同步设置，依赖锁文件字节未变。完整构建返回 0，Gradle assembleRelease 用时 81.0 秒。

实际产物 `HongguoTV-0.1.0-alpha.5-arm64.apk`，31,964,619 字节，SHA256 `b8a8094b1becb3d94a1685a818a883d5e445baf950cc864db1b92a3bb6a529bb`。包名 / 显示名 / MainActivity / TV Launcher / 非必需触屏 / 640×360 Banner 核对通过，versionName `0.1.0-alpha.5`，versionCode `2005`。17 个 SO 全部为 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so；包内核心与 Gradle 剥离后的核心一致，可加载节与 Go 构建核心一致。v2 签名及 `zipalign -c -P 16 4` 通过，证书 SHA256 沿用 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

相对 Alpha 4 仅修改 8 个既有 UI / 手势 / 版本 / 检查 / README 文件，不新增或删除原文件；原生核心、LunaExoPlayer、加载器、TV 控件和依赖锁文件字节未变。按 AGENTS.md 运行 `finish_task.py` 与 `sync_source.py --check` 归档，源码包排除签名私钥 / 密码、SDK、缓存、上传截图、预览字体和编译中间物。临时图标仍为深色背景、红色果实、绿色叶子和白色播放三角，并非恢复用户原先选定图片。未向上游推送、未发布商店。

新版已完成云端控件与安装包检查，尚无真实手机 / Android TV 安装、触摸 / 遥控或长时间播放验收；实机手感需以新版实际使用为准。

---

# 红果TV 0.1.0 Alpha 4 手机与电视播放交互（历史云端构建记录）

版本 `0.1.0-alpha.4+4`，包名 `com.hongguo.tv`，手机与 Android TV 共用同一 ARM64 APK，沿用自动设备识别、独立 Alpha 签名和临时图标。原始基线 `0e60928514c31a96ade9b31866948f15da5ca2a6`、分支 `hongguo-tv-0.1.0-alpha` 已核对；用户已反馈当前客户端可以播放。本次保留 Alpha 3 的播放地址、CENC 解密、播放器、全部站源、下载、弹幕、依赖和锁文件，集中调整播放交互，不向远程仓库推送或发布商店。

轻点误触亮度的原因是旧手势在按下时就按左右区域开启亮度 / 音量 HUD，没有等待用户明确滑动。现在按下不再弹出调节条，移动至少 28 个逻辑像素且方向明确后才识别滑动；轻点、轻微抖动和静止长按不调节亮度。手势参考 [YouTube 长按临时 2 倍速与锁屏](https://blog.youtube/news-and-events/youtube-new-features-2023/) 和 [Android TV 官方播放遥控规范](https://developer.android.com/training/tv/playback/controls)，采用成熟交互习惯；没有声称存在客观的热度最优方案，也没有复制红果官方播放器实现。

| 场景 | Alpha 4 操作 |
| --- | --- |
| 手机竖屏 | 空白画面轻点播放 / 暂停，播放时不常驻中央大按钮；底部仍有播放、倍速和画质入口，控制按钮触摸区域扩大 |
| 手机横屏 | 轻点显示 / 隐藏控制栏；选集、倍速、画质、弹幕、画中画等原有入口保留 |
| 手机长按 | 静止长按 400ms 临时 2 倍速，松手 / 取消恢复原选定倍速；已经选择高于 2 倍时保持更高倍速，避免反而减速 |
| 手机定位 | 双击左右侧分别后退 / 快进 15 秒，中间双击播放 / 暂停；横向拖动只预览目标时间，松手再定位，取消不定位 |
| 手机调节与切集 | 左侧 22% 区域上下滑动调亮度，右侧 22% 调音量，中间上下滑动保留前 / 后一集；锁屏后忽略画面触摸，点击解锁恢复 |
| 电视基本操作 | 画面模式下确认键直接播放 / 暂停，上 / 下唤出控制栏；控制栏默认焦点在播放按钮，持续播放约 5 秒后隐藏 |
| 电视快退 / 快进 | 画面模式或进度条聚焦时左右每次 ±15 秒；长按连续预览定位，持续重复后步长增为 30 秒，松开或重复停止再提交目标位置，保留原暂停状态 |
| 电视控制栏 | 顶部显示片名 / 当前集、倍速与画质；底部提供进度 / 缓冲、上一集 / 后退 / 播放 / 快进 / 下一集，再一行放选集、弹幕（支持时）、倍速 / 画质、播放日记；原增强入口条件保留 |
| 电视焦点与返回 | 控制栏内左右导航按钮；选集 / 设置关闭后恢复对应按钮焦点，长剧集列表滚动完成后定位当前集；第一次返回收起控制栏，第二次退出播放，Android 系统返回与遥控返回一致 |

云端定向检查共 14 项通过，覆盖轻点 / 抖动防误触、长按倍速恢复、亮度 / 音量边缘滑动、定位松手提交与取消、上下切集、手机实际控件的锁屏 / 双击、TV 连续定位 / 暂停保持 / 焦点、100 集列表当前集恢复、切画质、系统返回、失败重试、画中画和手机布局。测试使用合成媒体与禁用站源图片请求。已从实际 Flutter 控件渲染手机 / TV 预览，临时加载的中文字体与预览工具不加入应用或源码。定向静态分析无 error / warning，9 条既有风格信息提示保留；未启动全项目回归。首次检查发现旧 TV 测试仍期望 10 秒步长、长列表滚动后焦点丢失，以及返回测试未等待路由动画完成，已分别同步期望、修复焦点并修正测试等待，完整过程日志随附。

所有操作在云端 Linux 完成。保持 Flutter 3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1 和官方 Pub / Maven。依次运行 `flutter --suppress-analytics pub get --enforce-lockfile` 与 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`，原脚本同时设置 Go `buildAllSources=true`、Dart `ALL_SOURCES=true`，未升级依赖。构建返回 0，Gradle assembleRelease 用时 84.4 秒，生成真实 APK。

实际产物：`HongguoTV-0.1.0-alpha.4-arm64.apk`，31,961,127 字节，SHA256 `8d9eae0a74be8232232cc32a87c3feb2f5ef44e0a17cd7fd6453c8fe5f0a95ea`。包名 `com.hongguo.tv`，显示名红果TV，versionName `0.1.0-alpha.4`，versionCode `2004`。MainActivity、LEANBACK_LAUNCHER、非必需触屏及 640×360 Banner 已核对；17 个 SO 均为 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so。包内核心与 Gradle 剥离后的核心完全一致，可加载节与 Go 构建核心一致。v2 签名和 `zipalign -c -P 16 4` 通过，证书 SHA256 仍为 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`，可覆盖独立 Alpha 1–3。

相对 Alpha 3 修改 9 个既有源码 / 配置 / 文档文件、新增 1 个定向手势检查文件，无原文件删除；原生核心、播放器实现、加载器和依赖锁文件字节未变。按 AGENTS.md 执行 `finish_task.py` 归档和 `sync_source.py --check`，源码包排除签名私钥 / 密码、SDK、缓存、参考字体和编译中间物；附件包含完整检查 / 构建日志、包校验明细与源码改动清单。临时图标仍为深色背景、红色果实、绿色叶子、白色播放三角，不是恢复用户此前选中的图片。

新版尚未在真实手机 / Android TV 安装、触摸或遥控播放验收；云端控件检查与 APK 校验不等同于实机手感、硬解码或长时间播放通过。

---

# 红果TV 0.1.0 Alpha 3 播放修复（历史云端构建记录）

版本 `0.1.0-alpha.3+3`，包名 `com.hongguo.tv`，沿用 Alpha 独立签名和临时图标。保留全部站源、依赖、ExoPlayer / media_kit、页面 UI、TV 配置和遥控焦点行为；依赖锁文件与 Alpha 2 完全一致。原始基线 `0e60928514c31a96ade9b31866948f15da5ca2a6` 和独立分支 `hongguo-tv-0.1.0-alpha` 已再次核对，没有向远程推送。

用户提供的日志显示：回环地址已返回 HTTP 206 和 MP4 的 ftyp 头，但 Android ExoPlayer 初始化仍报 Source error。代码检查发现 Android 使用 LunaExoPlayer，其 platform 为 null；原有 decryption_key 只设置到 media_kit NativePlayer。视频地址获取成功并不表示加密采样已经能被播放器读取。Alpha 2 的 FFmpeg 检查额外提供了解密密钥，没有覆盖实际 ExoPlayer 路径，不能作为 Android 播放通过的结论。启动日志的 0.2.64+71 是原代码写死的文本，也不能用来认定用户装错版本。

此次在原有设备内回环转发中加入 CENC AES-CTR MP4 解密：读取有界 moov / 采样加密表，按采样 IV 和子采样表解密，原位恢复音视频 sample entry，同时保持文件长度和字节偏移。支持 Range、HEAD 和任意位置读取，按需流式解密，不先下载整集、不新增远程服务。仅 Android 加密播放计划启用明文回环地址并清空已处理的播放器密钥；在线播放、切换线路、已下载视频及接续播放采用相同通路。导出与合并仍通过原 localPlayback 返回原文件和密钥，其他平台保留原链路。暂不支持的分片或加密结构会明确失败，不把密文当作可播放内容。

LunaExoPlayer 改为依据 URL 路径、响应头和媒体签名判断格式，已确认 MP4 / HLS 后不再盲目切换格式重试。探测客户端会及时关闭，日志标明 clear-cenc-mp4 转发状态；启动日志读取实际安装版本。保留未知格式的原重试路径。定向回归另外复现了基线中的 HLS 缺陷：全会话存在 HLSKey 时，TS 分片也被误判为播放列表；仅移除这项全会话判断，保留入口、扩展名、响应头和内容签名识别。原嵌套 HLS 密钥 / Range 测试与无扩展名 / 重定向测试现已通过。

定向验证结果：合成加密视频经网络和本地文件转发后，在不提供播放器密钥的情况下解码；全部音视频帧的 framemd5 与 FFmpeg 自带 CENC 解密结果一致。任意偏移 37 字节块、HTTP Range、HEAD、416 和异常元数据检查通过。真实红果站源样本经过同一解密回环后返回 HTTP 206，不带播放器密钥完成约 1 秒音视频解码、输出 30 帧。没有访问站源图片。Flutter 播放加载器 4 项切集 / 取消 / 会话释放测试通过；定向静态分析无 error / warning，原 LunaExoPlayer 保留 6 条已有 import 信息提示。首次分析器缓存被沙箱限制后在云端受控重试完成。

全部操作均在云端 Linux 完成。工具链保持 Flutter 3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1，官方 Pub/Maven。先执行 `flutter --suppress-analytics pub get --enforce-lockfile`，再运行 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`；Go / Dart 全部站源开关一致。首轮完整构建停于 SDK36 目录无法识别；发现 SDK35/36 解压成嵌套目录，已用官方 SDK Manager 分别重装，未更换平台版本。完整脚本重试返回 0，Gradle assembleRelease 用时 156.2 秒，生成真实 ARM64 APK。平台工具由 Gradle 自动补装 37.0.1，编译所需 SDK / build-tools / NDK 版本未变。

实际产物：`HongguoTV-0.1.0-alpha.3-arm64.apk`，31,950,463 字节，SHA256 `ca5dd7e487b05cb63ab6893231364bb83c0b4ea6c8ea80c13bf6732ab6b6f659`。包名 com.hongguo.tv，显示名红果TV，versionName 0.1.0-alpha.3，versionCode 2003（原 split-per-abi 的 ARM64 基数 2000 + 构建号 3）。MainActivity、LEANBACK_LAUNCHER、非必需触屏、640×360 Banner 均核对。17 个 SO 全部为 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so；包内核心与 Gradle 剥离符号后的核心完全相同，并与 Go 编译核心的可加载节内容一致。v2 签名和 `zipalign -c -P 16 4` 通过，证书 SHA256 仍为 `3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`，可覆盖之前独立 Alpha 版本。

源码相对 Alpha 2 仅新增 3 个 CENC 实现 / 测试文件并修改 10 个相关文件，没有删除任何原源码；新增实现不引入第三方依赖。按 AGENTS.md 运行 finish_task.py 归档及 sync_source.py --check，完整首次失败、修复后成功构建、媒体定向验证和 APK 校验记录随日志附件交付。

尚无真实 Android TV 安装、Media3 硬解码和长时间播放结果。云端 FFmpeg 明文解码证明转发数据可解码，不等同于电视实机播放验收。临时图标仍为深色背景、红色果实、绿色叶子和白色播放三角，并非恢复用户此前选中的图片。源码归档排除签名私钥、密码、SDK、缓存、媒体样本及编译中间物。

---

# 红果TV 0.1.0 Alpha 2 播放修复（历史构建，未解决 Android 播放）

版本：`0.1.0-alpha.2+2`；沿用独立包名 `com.hongguo.tv`、全部站源、原播放器、UI、遥控焦点和临时图标。沿用 Alpha 1 独立签名，构建号递增以便覆盖安装。原始基线与 Alpha 1 构建记录保留如下。

本次参考用户提供的 `HG1.apk`（SHA256 `bee846d029ea6507a3fe019d0a4249b1004b7558150d26776355df66ae219ff8`）检查取流调用。手机版使用 POST `/novel/player/video_model/v1/`，短剧类型为 1、Outer 平台为 3，返回 `data.video_model`；TV 现有实现这些关键字段一致。未复制手机版二进制、私有 SDK 或替换播放器。

云端实际复现：TV 原取流代码得到 1080p 加密 MP4，CDN 的 Range 请求返回 HTTP 206；但 `nativeOpen` 对完整 URL 使用包含 `hls` 的判断，导致真正的 MP4 被误标为 HLS，应用回环转发返回 HTTP 502 和“播放列表无效”。另一个全 URL 包含 `m3u8` 的判断有同类风险。本次只移除这两种任意子串判断，继续根据已有播放列表/密钥、URL 路径扩展名、响应 Content-Type 和 `#EXTM3U` 内容识别 HLS；不修改签名、取流接口、媒体解密算法或站源业务逻辑。

定向验证：修复前真实媒体转发/解码失败；修复后原生网络客户端和回环转发返回 HTTP 206，并由云端 FFmpeg 6.1.1 完成约 1 秒音视频解码、输出 25 帧。新增合成 MP4 URL/Range 回归覆盖 `hls`、`m3u8` 出现在参数及路径的情况；已有无扩展名 HLS 与重定向测试通过。只进行了与缺陷直接相关的检查，没有启动全量回归或访问站源图片。接口详情请求曾返回空响应，现有网页详情回退成功；此次没有把它误当作播放根因。

该结果证实云端样本中的格式误判已修复，尚不能证明用户电视上的所有问题已经解决。未进行真实 Android TV 安装、硬解码和长时间播放验证。

云端构建：精确基线和 `hongguo-tv-0.1.0-alpha` 分支再次核对，Flutter 3.47.4、Temurin JDK17.0.20.1、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1。关闭 Flutter/Dart 遥测，使用官方 Pub/Maven；先执行 `flutter --suppress-analytics pub get --enforce-lockfile`，再执行 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`。锁文件与 Alpha 1 完全相同，Go `buildAllSources=true` 与 Dart `ALL_SOURCES=true` 均由原脚本启用。完整脚本返回 0，Gradle assembleRelease 用时 340.5 秒，FFmpeg 插件 javac 编译成功。工具恢复时发现 Flutter 解压后的 dartvm 和 engine flutter.jar 不完整，已从 SHA256 校验通过的官方压缩包恢复；没有更换 SDK 版本。

实际产物：`HongguoTV-0.1.0-alpha.2-arm64.apk`，31,927,343 字节；SHA256：`5cf4f477d0280fde7850ae87e3e0691049a526a9df881accd55435639b43dca5`。包名 `com.hongguo.tv`，显示名红果TV，versionName `0.1.0-alpha.2`，versionCode `2002`；MainActivity、TV Launcher、非必需触屏、640×360 Banner 均核对。17 个原生库全部为 ARM64 ELF，包含 libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so；打包核心库与 Gradle 剥离符号后的核心完全一致，所有已初始化的可加载节内容与编译原始库一致。RSA3072/v2 签名验证通过，证书 SHA256 与 Alpha 1 相同（`3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`），`zipalign -c -P 16 4` 通过。

本次相对 Alpha 1 纯源码归档仅修改 README、pubspec.yaml、native/core/app_stream.go 和 native/core/app_playback_test.go。签名私钥/密码、SDK、缓存、解出的手机版代码、参考 APK 和构建中间物均不进入源码包。

---

# 红果TV 0.1.0 Alpha 1 云端构建记录（历史结果）

基线：zhoufuweigg/guoapp，tag `app-v0.2.64-71`，commit `0e60928514c31a96ade9b31866948f15da5ca2a6`，原版本 `0.2.64+71`。独立分支 `hongguo-tv-0.1.0-alpha`。

本版仅修改 Android 品牌：应用名红果TV，namespace/applicationId `com.hongguo.tv`，版本 `0.1.0-alpha+1`，MainActivity 仅移动路径和修改 package；Dart 保留 ALL_SOURCES 判断，固定品牌名和导出文件名。保留依赖、播放器、所有业务/UI、TV 遥控行为和原站源。原 TV Launcher 与非必需触屏配置保留，可与原应用共存。

采用临时图标：深色背景、红色果实、绿色叶子、白色播放三角；640×360 Banner 使用中文字体，标注红果TV及0.1.0 ALPHA。这不是此前用户选定图片的恢复。

所有拉取、修改、资源和工具链操作均在云端 Linux 进行，没有使用 Windows 或用户本机执行器。工具链为官方 Flutter 3.47.4（压缩包 SHA256 已校验）、JDK17、Go1.24.1、SDK35/36、build-tools36.0.0、NDK28.2.13676358、CMake3.22.1。官方 Pub/Maven，构建命令 `python3 scripts/build_android.py --all-sources --abi arm64-v8a`，Go/Dart 均启用全部站源。

已生成独立云端测试签名密钥，私钥及密码不进入源码归档。未进行设备安装或播放验证，仅完成包级校验，未作为设备验收版本。

真实结果：原脚本 `--all-sources --abi arm64-v8a` 返回成功，产出 `HongguoTV-0.1.0-alpha-arm64.apk`（31,927,971字节）。SHA256：`1ff096ef5be25b4490ddafc69c22b482c41d6df2cddc1568e91709279ebcde31`。包名/显示名/MainActivity/LEANBACK_LAUNCHER/非必需触屏/仅 ARM64 ABI 已核对；17个SO均为ARM64 ELF，包含libduanju_core.so、libflutter.so、libapp.so、libmpv.so、libffmpegkit.so。独立 RSA3072 Alpha 证书的 v2 签名验证通过，`zipalign -c -P 16 4`通过。证书SHA256：`3c3c2b31092bd85809ff9654ce3b19ce2e0b3fc7baafff5d80e8900217c83711`。

Dart/pubspec版本为 `0.1.0-alpha+1`；Android versionName为 `0.1.0-alpha`，versionCode实际为 `2001`，沿用原Flutter split-per-abi规则（ARM64基数2000 + 构建号1），未更改原构建配置。

云端排障：首次 Java 未使用云端代理导致 Gradle 下载报 Network is unreachable；配置运行时Java/Gradle代理后解决。首次多包 SDK 安装使 build-tools36 与 SDK35出现嵌套目录，分别通过官方SDK Manager卸载重装解决。云端预装Java17仅运行时，后补装Temurin JDK17.0.20.1并使用云端系统证书信任。SDK35修复后，FFmpeg compileReleaseJavaWithJavac 已成功并完成APK构建。未升级依赖或改动播放器。Flutter与Dart遥测关闭。官方pub get只补齐csslib1.0.2、html0.15.7、video_player2.14.0、video_player_android2.12.2、video_player_avfoundation2.12.0、video_player_platform_interface6.9.0、video_player_web2.4.0，原锁定版本完整保留，enforce-lockfile通过。

构建日志与校验明细作为独立交付附件保存；签名密钥/密码、SDK、缓存、编译产物不进入源码包。未向上游推送，未发布商店。原项目说明保留如下。

---

# 红果鉴 / 真果鉴

> ⚠️ **免责声明**：本项目源码来自网上大名鼎鼎的**鱼佬**（原作者）。我只是把它拿来打包、测试着玩，方便自己用，**不保证任何可用性，随时可能删库**。

Flutter 多端独立短剧 / 影视应用，原名「短剧库 APP」。站源请求、解析、下载和播放均在设备上完成，不依赖自建服务。当前源码版本：**0.2.51+57**。

本轮在 0.2.50 基线上新增两个原生站源：**韩小圈**（`hanxiaoquan`，韩剧 / 韩国电影 / 韩国综艺 / 韩国动漫）与**鬼片网**（`guipian`，鬼片 / 电视剧 / 动漫）。默认可见站源顺序为：**红果 → 韩小圈 → 鬼片 → 青空**。

> 说明：应用长期按「只维护源码与定向测试，集中验证另行安排」的方式推进。未完成集中验证与真机验收的项目保持未验收状态；历史版本的检查记录不能作为后续新增功能的验收结论。

| 编译方式 | 应用名称 | 可用站源 |
| --- | --- | --- |
| 默认（不加参数） | 红果鉴 | 仅红果 |
| 加 `--all-sources` | 真果鉴 | 红果、韩小圈、鬼片、青空，以及黄豆、剧果、野果、帝果、黄果视频、黄果 AI、黄果旧版 |

默认可见站源（红果、韩小圈、鬼片、青空）无需密码；其余站源默认隐藏，在站源管理里通过密码锁解锁后显示。已有受限用户不会自动获得新增站源权限，管理员可在用户管理中勾选。

这是**编译选项**，应用内不能切换版本。标题、Android 桌面名称与电视横幅、Windows 窗口与分发文件名、iOS 显示名随编译选项变化。界面、站源调用、原生下载调度同时限制可用站源；红果版不会访问或继续执行其他站源的旧任务。

两版保留原 Android / iOS 应用标识及数据目录；Android 使用同一签名可相互覆盖升级，不能作为两个独立正式应用并排安装。切换版本保留追剧、观看记录、用户权限和下载记录；备份格式保持兼容。

## 使用

| 功能 | 操作 |
| --- | --- |
| 浏览 | 标题栏依次提供排序与筛选、榜单、多选下载和展开搜索。分类保持独立一行，内容区左右滑动切类；支持默认、名称、自然季号、上线日期、热度、播放量排序及连载状态筛选。列表下滑接近底部自动加载下一页，底部「加载更多」为兜底 |
| 搜索 | 红果合并官网与名称索引，输入停顿 300 毫秒显示最多 10 条联想；韩小圈、剧果、野果、鬼片调用各自的在线搜索并按分页继续加载。部分失败保留有效结果；最近 20 次搜索按用户保存 |
| 推荐 | 仅红果分类栏在「全部」后显示「推荐」，可切换真人剧、漫剧、AI 剧并分别记住位置 |
| 详情 | 普通点剧直接进入播放；下载和兜底入口保留详情页。详情页浏览封面、资料、追剧状态与可展开简介；底部固定「立即播放 / 继续播放」和下载入口。选集默认折叠，展开后每组 50 集，可切换范围、定位当前或输入集数跳转；宽屏与电视采用资料、选集分栏 |
| 追剧与历史 | 按想看 / 在看 / 已看 / 有更新筛选；红果已追剧发现新季后进入「有更新」。追剧和历史均可搜索。每个用户独立保存，每 5 秒及退出播放时记录真实进度 |
| 卡片与批量下载 | 卡片「更多」提供收藏、状态和下载选集；电脑右键，电视菜单键。发现页长按卡片或点标题栏「多选下载」，一次最多 50 部 |
| VIP | 全站源版浏览黄豆或全部站源时显示 VIP 图标，仅过滤黄豆；默认隐藏已确认的 VIP。未知、免费、VIP 分别保存，未知不会覆盖已知状态 |
| 手机播放 | 竖屏以视频为主，选集 / 简介 / 下载从底部面板展开，轻点播放 / 暂停；横屏轻点控制条；长按 400 毫秒临时 2 倍速，松手恢复原倍速（更高倍速保持）。双击左右侧后退 / 快进 15 秒，中间双击播放 / 暂停；横向拖动松手定位，左 / 右侧明确上下滑动调亮度 / 音量，中间上下滑动切集。新增锁屏按钮；「选集 / 简介 / 下载」Tab 保留在可展开面板中 |
| 画中画 | Android 手机 / 平板播放器接入画中画按钮；进入前隐藏自绘控制层与弹幕，小窗只保留画面。Android TV、Windows、iOS 暂未接入 |
| 画质增强 | 仅 Windows 桌面端显示并运行增强链路（关闭 / 自动 / 省电增强 / 清晰优先）；移动端与电视端隐藏 |
| 弹幕 | 红果在线播放默认开启；播放器侧边圆形「弹」字按钮可关闭、查看状态及失败重试。本地播放不加载弹幕 |
| 下载 | 播放页「下载」Tab 和详情页下载入口均可选择分集与画质；支持批量暂停、继续、重试、删除及清理任务但保留视频。「更新本剧」补新增或缺失分集 |
| 更多 | 站源管理、用户管理、设置与备份、界面模式、关于 |

| 站源 | 浏览与播放 | 搜索 |
| --- | --- | --- |
| 红果 | 真人剧、漫剧、AI 剧及分集 | 联网搜索与官网搜索联想 |
| 韩小圈 | MacCMS 模板：最新韩剧 / 韩国电影 / 韩国综艺 / 韩国动漫，多线路分集 | 站源在线搜索 |
| 鬼片 | MacCMS 站点：鬼片 / 电视剧 / 动漫，多线路分集 | RSS 最新条目标题匹配（站点搜索已停用） |
| 青空 | 番剧、剧场动画、特摄及分集 | 站源在线搜索 |
| 黄豆 | 列表、VIP 标记及分集 | 筛选已加载短剧 |
| 剧果 | 热门、最新、接口分类、详情及可播放分集；签名 Cookie 接入在线播放、预加载和下载 | 站源在线搜索，支持继续加载 |
| 野果 | 接口实际分类、目录、详情及真实分集；按分集重新取流，保留 H.264 / H.265 地址 | 站源在线分页搜索 |
| 帝果 | 网页分类、目录、详情及分集；vplayer 签名解析 | 站源在线分页搜索 |
| 黄果视频 / 黄果 AI / 黄果旧版 | 列表、分类、详情及分集 | 筛选已加载短剧 |

站源可用性、清晰度和区域限制取决于源站及网络；应用不解除源站 VIP 或其他授权限制。

### 网络与资源设置

管理员从「设置与备份 → 网络与资源」选择自动、直连或手动代理，手动地址支持 HTTP、HTTPS、SOCKS5 / SOCKS5h。代理地址默认遮蔽、不进入备份；设备内播放服务始终绕过代理。自动模式读取系统静态代理与排除列表，恢复前台及每 30 秒更新；代理不会关闭 TLS 校验。

目录请求并发可设 1–6、间隔 0–5000 毫秒（默认 3 / 250ms）；下载并发默认 2、可设 1–6。仍保留前台优先、后台让行、取消、退避及请求数量边界。

### 局域网互联：追剧同步与推送播放（已接入，待验证）

两台设备在同一局域网直连，自动同步追剧记录或接续播放，不依赖账号服务器。服务类型 `_zgj-link._tcp`（DNS-SD / mDNS），按设备 ID 合并多网卡地址，首次配对记录证书指纹，后续连接固定校验。

入口：「追剧 → 标题栏同步」或「设置与备份 → 设备互联」。手动同步默认「双向合并」，可选覆盖对方 / 覆盖本机，先「查看预览」再执行；自动同步仅发送改动条目与删除标记，播放期间约每 10 秒发送进度。冲突记录保留候选，用户从同步页逐项处理。

## 安装包与平台状态

| 平台 | 包与状态 |
| --- | --- |
| Android 8.0+ | 三架构（arm64-v8a / armeabi-v7a / x86_64）APK；同一签名可覆盖升级 |
| Windows 10/11 x64 | 免安装 ZIP 解压后运行 `duanjuhui.exe`，或直接用安装程序装到 `Program Files\短句汇`；保留所有 DLL 与 `data`；局域网原生发现依赖 Windows 10 1903+ |
| Android TV | 与手机共用源码，自动识别电视模式并保持横屏；待电视 / 盒子实机验收 |
| iOS 15.1+ | 已加入工程、Go 核心链接、媒体依赖、文件管理与构建脚本；iOS 播放页禁用 media_kit_video 硬件纹理加速以规避 libmpv 渲染崩溃；待 Xcode 构建与真机验收，无已签名 IPA |

`INSTALL_FAILED_NO_MATCHING_ABIS` 表示 APK 与设备架构不匹配，请更换对应架构安装包。

### GitHub Actions

工作流 **Build app packages** 按触发方式分两条路径：

| 触发 | 行为 |
| --- | --- |
| 推送到 `main`（或提交 PR 改动源码） | 只跑 `verify`：编译原生核心（`go build ./...`）、`go vet`、`flutter analyze`、**Dart 回归测试**，以及仅报告不阻断的 `go test`。约 3–5 分钟，**不构建 APK、不发布** |
| 推送 `app-v*` 标签 | `verify` 通过后 **Android 与 Windows 并行构建**；**哪个平台先完成就先创建 GitHub Release**，另一个完成后再把自己的产物、校验和与说明追加进同一个 Release |
| 手动 `workflow_dispatch` | 同上（未指定标签时按 `pubspec.yaml` 版本派生标签） |

两个平台的发布任务合并为一个共用脚本 [publish_release.sh](scripts/publish_release.sh)：Release 不存在就创建（说明取本文件的对应版本小节），已存在则追加产物、合并 `SHA256SUMS.txt`（按文件名去重）并补上本平台说明。两者共用 `app-publish-<ref>` 并发组串行执行，因此不会出现两边同时创建；不需要等待另一个平台，先编译完就先发布。

同名 Release 已存在时不再报错，而是直接追加。若要重发同一版本，按「发版」规则先删掉该 Release 再重新打标签。

`verify` 的 Dart 测试走 [run_dart_tests.sh](scripts/run_dart_tests.sh)：脚本排除 15 个存在**既存失败**用例的文件，其余全部纳入并阻断发布；等这些文件的失败清掉后再逐个收编。加上这步是因为 `flutter analyze` 只能抓静态问题，0.3.1 那次「密码锁写盘被拒」是运行时的 `StateError`，只有 Dart 测试能拦住。

推送标签前需先在 `pubspec.yaml` 提升 `version`；`verify` 会校验标签版本与 `pubspec.yaml` 一致（标签 `app-v0.2.4-36` 对应 `version: 0.2.4+36`），不一致直接失败。

| 任务 | 依赖 | 产物 |
| --- | --- | --- |
| `android` | `verify` | `duanjuhui-android`：三种架构 APK、旧名兼容副本和 SHA256 |
| `windows` | `verify`（与 `android` 并行） | `duanjuhui-windows`：Windows x64 免安装压缩包与安装程序 |
| `release` | 仅 `android` | 用 Android 产物创建 Release |
| `release-windows` | `release` 与 `windows` | 把 Windows 压缩包与更新后的 `SHA256SUMS.txt` 追加到该 Release，并补上 Windows 说明 |

Android 完成即发布，因此 Release 会先于 Windows 出现；Windows 的产物、校验和与说明由 `release-windows` 随后补齐。同名 Release 已存在则会失败并提示递增版本，不会覆盖既有发布文件。

Android 正式发布使用同一签名并递增构建号，在仓库 Secrets 配置：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。未配置时生成 debug 签名预览包。

本地不入库的 `android/key.properties`：

~~~properties
storeFile=/absolute/path/zhenguojian-release.jks
storePassword=你的密码
keyAlias=zhenguojian
keyPassword=你的密码
~~~

## 开发与构建

Flutter `3.47.4`、Dart `3.12+`、Go `1.24.1+`、Python `3.10+`。Android 需要 JDK 17、SDK 36、NDK `28.2.13676358`；Windows 需要 Visual Studio C++ 桌面组件及 MinGW-w64 x64；iOS 需要 macOS、完整 Xcode 和 CocoaPods。

构建脚本对子进程默认设置 `GOPROXY=https://goproxy.cn,direct`、`GOSUMDB=off`，同名环境变量可覆盖。

~~~sh
python3 scripts/build_android.py                 # 红果鉴
python3 scripts/build_android.py --all-sources   # 真果鉴
python3 scripts/build_android.py --abi arm64-v8a
python3 scripts/build_android.py --cn-mirrors    # 国内镜像
~~~

~~~powershell
.\scripts\build_windows.ps1
.\scripts\build_windows.ps1 -AllSources
.\scripts\build_windows.ps1 -ChinaMirrors
~~~

~~~sh
python3 scripts/build_ios.py
python3 scripts/build_ios.py --all-sources
python3 scripts/build_ios.py --core-only [--simulator]
python3 scripts/build_ios.py --export-options /path/to/ExportOptions.plist
~~~

产物在 `dist/android`、`dist/windows`、`dist/ios`，红果版以 `hongguojian-` 开头，全站源版以 `zhenguojian-` 开头。

首次 Android 调试先编译对应架构核心，再运行：

~~~sh
python3 scripts/build_native.py --platform android --abi arm64-v8a
flutter pub get --enforce-lockfile
flutter run
~~~

调试全站源版：先给 `build_native.py` 加 `--all-sources`，再 `flutter run --dart-define=ALL_SOURCES=true`；iOS 对应 `build_ios.py --core-only --all-sources`。脚本会同步设置 Dart 常量和 Go 编译参数，应用启动时校验二者一致，避免混装原生库。

播放器使用 [media_kit](https://github.com/media-kit/media-kit) / libmpv，合并和导出使用 [FFmpegKit min-gpl](https://github.com/sk3llo/ffmpeg_kit_flutter)（含 GPL 媒体组件）。FFmpegKit 不参与正常播放或下载的转码。

### 集中检查与真机回归

~~~sh
python3 -m unittest discover -s scripts -p 'test_*.py'
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
dart analyze --fatal-infos lib test integration_test test_driver
flutter test --dart-define=DISABLE_REMOTE_IMAGES=true
flutter test --dart-define=DISABLE_REMOTE_IMAGES=true --dart-define=ALL_SOURCES=true
cd native
go test -race ./...
go test -race -ldflags="-X duanjuapp/native/core.buildAllSources=true" ./...
~~~

Android 设备回归（连接并授权 USB 调试、保持解锁）：

~~~sh
python3 scripts/create_test_media.py
python3 scripts/serve_test_media.py
adb reverse tcp:38473 tcp:38473
flutter drive --driver=test_driver/playback.dart --target=integration_test/playback_test.dart \
  --dart-define=DISABLE_REMOTE_IMAGES=true --dart-define=FIXTURE_BASE_URL=http://127.0.0.1:38473
~~~

结果在 `build/device-test/results/`；结束后停服务并 `adb reverse --remove tcp:38473`。

### 源码校验

~~~sh
python3 scripts/finish_task.py --message "本次实际完成的变更"
~~~

脚本按收录规则统计并校验干净源码清单，不生成副本或压缩包，不执行 Git 提交、分支或推送。需要临时镜像时用 `python3 scripts/sync_source.py --destination <目录>` 显式指定目标。

## 目录结构

| 目录 | 内容 |
| --- | --- |
| `lib` | 页面、播放器、本地用户、FFI、下载和媒体处理 |
| `native/core`、`native/bridge` | 独立站源核心、缓存、下载、目录迁移及 C ABI |
| `android`、`windows`、`ios` | 平台工程与必要资源 |
| `assets/video_enhancement`、`packages/media_kit_libs_windows_video` | 增强 Shader 与许可、固定 Windows 媒体依赖插件 |
| `scripts`、`.github/workflows` | 构建、签名、验证、同步和版本快照 |
| `test`、`integration_test` | 自动化与设备回归 |

## 站源开发约定

站源是 Go 原生 provider（`native/core/provider_*.go`），不是运行期加载的 Python 源。新增站源需接入：`provider_huangguo.go`（常量 / 白名单 / `canonicalProviderSource` / `GetHuangguoChapters`）、`provider_media.go`（baseURL / host 反查 / 播放分派）、`app_categories.go`、`app_cover_metadata.go`、`app_runtime.go`（Config 字段 + 目录 / 搜索 / 详情分派 + 空页放行），并在 `lib/models.dart` 登记 `SourceSite`。

注意：Go RE2 正则**不支持 lookahead**。解析多线路播放列表时不能用 `(?=...)` 做分段，否则非捕获组会消耗下一段开头；应改用显式字符串截断（从容器标记之后查找下一段标记）。
