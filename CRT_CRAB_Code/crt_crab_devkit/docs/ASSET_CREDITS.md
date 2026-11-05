# 资源来源与实际落地记录

更新：2026-11-05。参考规范位于项目外层 `CRT_CRAB_Code_B/`；所有“候选模型”与“实际使用资产”分开记录。

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

## 第三方模型候选的状态

新版场景书中的 MadeByYeshe、fizyman、Tomitos、Tobalation、Drillimpact、NobleCrowDev 等链接当前都只是候选。**本轮实际第三方模型下载数为 0，导入数为 0。** 本轮没有用模型页面截图冒充三维资源，也没有绕过登录下载。

若后续采用这些模型，必须重新核对实际页面、作者、许可、下载资格、面数、下载日期、源文件与修改记录；文档里原有的 CC BY 标注不能代替这一步。本轮样板使用可追溯的本工程网格；真实第三方模型选型/导入仍属后续美术工作。
