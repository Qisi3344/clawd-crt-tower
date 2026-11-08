# 资源来源与实际落地记录

ARCHIVE（2026-11-08）：用户提供 `ARCHIVE_Asset_Pack_v1.zip` 的背景、12 类道具与概念参考。原图保留；本工程做尺寸化、选段与场景装配，远景通过内置 imagegen 清除虚构道路。[接入、来源与实际截图](ARCHIVE_ART_INTEGRATION.md)。未将其标作 Kenney / CC0 素材。

更新：2026-11-08。参考规范位于项目外层 `CRT_CRAB_Code_B/`；所有“候选模型”与“实际使用资产”分开记录。

| 内容 | 来源/作者 | 实际文件 | 使用及修改 |
|---|---|---|---|
| 螃蟹形体、陶土色与单排四腿识别 | Qisi3344 / 绮思，clawd-motion，核对版本 1b9ba7949645c884e86f3f336595c439251d8cf1 | tools/build_pixel_assets.py、assets/pixel/sprites.png | 用户指定的角色参考，重新绘制侧视像素分件与动作；没有导入 SVG 渲染器。原仓库 All Rights Reserved，保留原作者权利，不当作公共开源美术包分发 |
| 像素平台、木箱、重石、梯子、压板、门、宝箱、裂墙、数据虫、晶体 | 本工程独立绘制 | assets/pixel/sprites.png、tiles.png | 32px 图集帧、16px 地图格，最近邻；生成源码可追溯，没有挪用《钻石狂潮》素材 |
| BOOT / ARCHIVE 背景与十二张待机图 | 本工程独立绘制 | assets/pixel/background_*.png、standby_*.png | 色板与图形为原创，待机图明确标注显示状态；Pillow 是作者工具，不是运行依赖，也没有打包外部字体文件 |
| 四类 CRT、支架、键盘、旋钮、背面接口、标签、胶带、底座、线缆、磁带机、软盘、通信盒、挂牌 | 本工程程序化低模独立构建 | scripts/monitor_device.gd、craft.gd、exterior_dressing.gd、data/monitor_layout.json | 2026-11-05 制作；未下载/导入第三方模型，不将原型网格冒称 Sketchfab 作品。便携型、厚办公型、窄一体型、浅工业电视型使用不同几何组合 |
| 风格参考五张图 | 用户提供；相关作品权利归各自权利人 | docs/参考图/ | 只作形体/层次/色彩研究，运行时不读取图像；未导入《绝区零》截图、商标、角色或专用图标 |
| 合成短音效 | 本工程 | scripts/audio.gd | 代码生成 PCM 波形，无外部游戏音频 |
| 字体 | 用户系统可用字体 / Godot 默认字体 | assets/theme.tres、运行时 SystemFont | 不复制或分发微软雅黑等字体文件 |
| 引擎 | Godot Engine 4.7.2，MIT | .tools/（本机便携，Git 忽略） | 官方发行运行时；授权 https://godotengine.org/license/ |

角色来源：https://github.com/Qisi3344/clawd-motion/blob/main/public/clawd.json 。该项目的比例/配色源于作者的 moontide-isle；指定参考不意味着向公众转授角色权利。

## 外围环境：实际下载与导入（2026-11-05）

从 Kenney 官方站下载了 Mini Arcade 1.2、Furniture Kit 2.0、Factory Kit 3.0、Survival Kit 2.0。四包均为 CC0 1.0，许可原件保留在 `assets/environment/originals/<包名>/LICENSE.txt`。Mini Arcade 附加致谢 Fleur Keijsers、Guus Vermeulen。所有修改版保留第三方来源，不将模型归为本工程原创。

共准备 20 个原始 GLB，实际使用其中 16 种、实例化 26 个。下表实例数为 0 的资源仅作选型留档，运行时不加载。场景均位于 `scenes/environment/`；原始文件位于 `assets/environment/originals/<包名>/<名称>.glb`，优化文件位于 `assets/environment/optimized/<包名>__<名称>.glb`。精确路径、SHA256、尺寸、三角面数和实例数见 [source_manifest.json](../assets/environment/source_manifest.json)。

统一修改：落地轴心、统一尺寸、哑光粗糙度、低饱和青灰/粉灰色板；原始几何保留。运行时进一步压低外围材质明度、关闭装饰阴影；工业机器被压缩纵深并加装盘位/指示灯，适配储存与配电用途，**不是 Sketchfab 服务器/配电箱资产**。街机换原创待机纹理与实体牌；贩卖机增加原创立体饮料陈列；源贴图最大 512px，无运行时联网。

| 模型（包/文件名） | 原模型 tris | 独立场景 | 实例数 |
|---|---:|---|---:|
| mini-arcade / arcade-machine | 392 | arcade_cabinet.tscn | 2 |
| mini-arcade / vending-machine | 176 | vending_machine.tscn | 1 |
| mini-arcade / ticket-machine | 277 | ticket_machine.tscn | 1 |
| furniture-kit / desk | 198 | repair_workbench.tscn | 1 |
| furniture-kit / bookcaseOpen | 320 | repair_shelf.tscn | 1 |
| furniture-kit / chairDesk | 588 | repair_chair.tscn | 1 |
| furniture-kit / computerKeyboard | 32 | repair_keyboard.tscn | 1 |
| furniture-kit / computerScreen | 72 | repair_terminal.tscn | 1 |
| furniture-kit / cardboardBoxOpen | 60 | parts_box.tscn | 2 |
| furniture-kit / lampRoundTable | 76 | repair_lamp.tscn | 1 |
| factory-kit / machine | 268 | distribution_box.tscn | 1 |
| factory-kit / machine-fortified | 320 | server_cabinet.tscn | 2 |
| factory-kit / pipe-large-long | 292 | 选型留档 | 0 |
| factory-kit / pipe-large-bend | 448 | pipe_bend.tscn | 1 |
| factory-kit / pipe-large-valve | 456 | pipe_valve.tscn | 1 |
| factory-kit / structure-high | 268 | 选型留档 | 0 |
| factory-kit / catwalk-straight | 328 | 选型留档 | 0 |
| survival-kit / workbench | 236 | 选型留档 | 0 |
| survival-kit / tool-hammer | 52 | repair_hammer.tscn | 1 |
| survival-kit / metal-panel-screws | 320 | background_panel.tscn | 8 |

作者/官方来源：[Kenney Mini Arcade](https://kenney.nl/assets/mini-arcade)、[Furniture Kit](https://kenney.nl/assets/furniture-kit)、[Factory Kit](https://kenney.nl/assets/factory-kit)、[Survival Kit](https://kenney.nl/assets/survival-kit)。许可：[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)。

原创部分：招牌、工位背板/纸条、摆臂灯、小风扇、盘位/LED、供电线、饮料陈列、梁架/灯轨/电缆桥、地台和两张街机待机 PNG。工具 `tools/prepare_environment_models.py` 使用本机 Blender 统一导出优化 GLB，运行游戏无需 Blender。原始目录由 `.gdignore` 排除 Godot 导入，保留完整可追溯文件。

游戏内路径：Esc → 素材署名 / CREDITS。仓库 README 引用本表。环境搭建初期未使用外部音乐；后续用户指定音乐见下文。

## 候选与受阻项目

早期 MadeByYeshe、fizyman、Tomitos、Tobalation、Drillimpact、NobleCrowDev 仍为历史候选；旧阶段的“下载 0 / 导入 0”只描述当时原创 CRT 样板，不适用于本次外围环境。

新策划书 SF-01～04 已核对模型页作者及 CC BY 4.0 标识；官方下载端点均返回 HTTP 401，记录为 **BLOCKED_DOWNLOAD**，没有导入、没有提取网页查看器缓存。逐项页面、作者、原因及人工落盘目录见 [待下载说明](../assets/environment/originals/sketchfab_pending/README.md) 和 [下载状态](../assets/environment/sketchfab_download_status.json)。SF-05～08 为可选候选，本轮未下载，也不声称完成；已有 CC0 管道、柜体、货架与贩卖机满足当前布景。

## 用户提供的音乐与平面装饰（2026-11-05）

用户明确指定使用工作区 `NO SIGNAL .mp3` 完整版（209 秒），原样复制到 `assets/audio/no_signal_full.mp3`；未使用 1分58秒 32k 版。循环播放，音效独立，默认音乐音量 35%（另有 -12dB 混音衰减），暂停菜单可关闭或调节。设置仅保存在 `user://audio.cfg`，QA/性能模式不读取、不写入该文件，也不自动播放音乐。

用户提供 `一些装饰.zip`，选用其中 CRT 标识、BOOT OK、NO SIGNAL、ARCHIVE LINK、CRT 海报、404 和爪痕，放在维修背板、街机下部和后侧工业板；图像保存在 `assets/environment/decals/user/`，为原图直接使用，未覆盖活动玻璃。其余图片留在用户原压缩包中。音乐与这些图片的来源为用户提供，作者/外部分发许可未附说明，不归入 Kenney CC0，也不更改它们的权属。

## 第二阶段像素外观与音效

`assets/pixel/skins/` 四套 256×192 PNG，均由现有原创角色六行动作图集调色并补眼镜/耳机/静态错位细节。作者工具为 `tools/build_pixel_assets.py`，预览与角色共用 `Cosmetics.frame`；原角色形体参考权利说明仍适用。`PortalFX2D` 按当前动作/服装的真实透明像素采样并分解/重组，位于内部 2D 世界，不导入外部特效资源。新增 start/select/purchase/error/transfer_exit/link/enter 为本工程代码合成电子短音，无真人语音。
