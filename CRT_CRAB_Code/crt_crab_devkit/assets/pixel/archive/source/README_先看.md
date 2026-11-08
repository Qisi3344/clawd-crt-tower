# ARCHIVE · 档案仓库美术素材包 v1.0

**适用项目**：`Qisi3344/clawd-crt-tower` → `CRT_CRAB_Code/crt_crab_devkit/`  
**目标关卡**：`ARCHIVE`（`data/levels/archive_01.json`；世界尺寸 **1024×640**）  
**活动 CRT 显示分辨率**：**320×240**（单个 `SubViewport`）  
**状态**：美术素材与拆分交付包，**尚未接入、未经过真实 Godot 截图/通关验收**。

## 文件用途（先读这里）

| 文件/目录 | 类型 | 实际用途 | 可直接放进关卡？ |
|---|---|---|---|
| `00_reference/ARCHIVE_完整场景概念图_参考勿直接入游戏.png` | 1448×1086，RGB | 统一风格、结构和色彩的**概念参考**：上层检索桥、中层归档大厅、下层破损记录仓 | **不可整张作为关卡**：图内存在不对应真实碰撞的楼梯/平台/终端及 CRT 边框 |
| `01_backgrounds/ARCHIVE_far_source_远景.png` | 2172×724，RGB | 远景：无限延伸的低对比柜墙、走廊与稀疏远处灯光。用于背景层，随镜头低速视差。 | **需要裁剪、缩放、检验接缝和对齐** |
| `01_backgrounds/ARCHIVE_mid_source_中景.png` | 2172×724，RGB | 中景：抽屉、检索桥、档案架、吊灯、检索台等。选段做区域背景或拆解后的局部立面。 | **需要拆分及适配关卡布局**，不能把图上装饰平台冒充真实可走地形 |
| `02_props/source_sheet/ARCHIVE_12道具原始图集.png` | 1448×1086，RGBA | 12 个道具原始整张图；留作美术修改、复核 | 不建议整张导入作为可摆放对象 |
| `02_props/split_png/*.png` | 12 张分离透明 PNG | 真正方便摆放的独立道具素材：推车、档案箱、抽屉、检索梯、柱子、灯、终端等 | **可以做 Sprite2D 静态装饰**，须选定显示尺寸并检查像素风格与遮挡 |
| `03_preview/ARCHIVE_道具总览.png` | 拼图预览 | 快速核对 12 件道具及编号 | 不用于关卡 |
| `docs/ARCHIVE_素材位置与Godot接入说明.md` | Markdown | 三层空间、道具摆放位置、接入顺序、禁止事项与验收条款 | 给 Codex/开发人员执行 |
| `docs/给Codex的执行任务.md` | Markdown | 可直接交给 Codex 的任务单 | 给 Codex，不是游戏素材 |

**重要说明**：图像生成提出的“横向可无缝”是设计目标，不代表已通过像素级左右边缘接缝校验；导入时必须检查。两张长图的透视、画面中预先画好的楼梯/平台，也必须先适配真实地形和碰撞。未实测之前不能称为游戏内完成版。

## 推荐接入位置

复制素材至 Godot 工程：

```
CRT_CRAB_Code/crt_crab_devkit/
└── assets/pixel/archive/
    ├── reference/   ← 00_reference/ （仅制作参考，可不打包进游戏）
    ├── far/         ← 01_backgrounds/ARCHIVE_far_source_远景.png
    ├── mid/         ← 01_backgrounds/ARCHIVE_mid_source_中景.png
    └── props/       ← 02_props/split_png/ 下的 12 张 PNG
```

**无需移动原来** `assets/pixel/background_archive.png`；先保留旧图便于回退。在 `scripts/world_backdrop.gd` 的 ARCHIVE 分支改造背景绘制；在 `scripts/side_world.gd` 中加载只用于 ARCHIVE 的环境道具。`data/levels/archive_01.json` 的关卡机关于此版本**不得修改**。

详见 `docs/ARCHIVE_素材位置与Godot接入说明.md`。
