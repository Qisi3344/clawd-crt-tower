# POP-UP · 弹窗区 美术素材包 v1.0

项目：`Qisi3344/clawd-crt-tower`；游戏内部 **1024×768** 的 POP-UP 连续地图，活动 CRT 屏幕 **320×240**。

## 内容与用途

- `reference/POPUP_full_concept_REFERENCE_ONLY.png`：**整体美术参考**，不能整张覆盖地图：画中桥、梯、广告牌没有实际碰撞。
- `reference/POPUP_mid_concept_REFERENCE_ONLY.png`：**中景视觉参考**，不能直接矩形切片重复铺；根据真实关卡坐标重绘无缝衔接的建筑层。
- `background/POPUP_far_source.png`：**远景原稿**（2172×724），远处弹窗城市、巨型 CRT、数字云；在 Godot 根据实际视口裁取并降低对比、做轻微视差。**未验证左右无缝，请勿直接循环**。
- `props/POPUP_original_12_props.png`：透明原始道具图集。
- `props/source_crops/`：12 件**原始分切透明 PNG**；可继续调整边缘和风格，保留较高像素尺寸。
- `props/game_candidates/`：12 件供 **320×240 游戏视口**试用的小尺寸 PNG；已经缩放但**未经游戏内视觉验收**，请不要当最终像素规范。
- `preview/`：道具预览与区域示意；**两者都不是游戏背景**。
- `manifest.json`：道具 ID、中文名称、尺寸、源图裁剪坐标、摆放建议等结构化数据。
- `docs/素材位置与接入说明.md`：五个区域的视觉方案与避让原则。
- `docs/给Codex的执行任务.md`：可直接投喂的执行说明。

## 最重要的界限

这是一套**生产素材与设计说明**，不是已经接入 Godot 的完工场景。不能拿整张概念图当背景、不能拿 12 件摆件当可交互机关、不能通过调透明度掩盖硬矩形裁切。仅修改 POP-UP，美术不扩玩法，不触碰其它五关。
