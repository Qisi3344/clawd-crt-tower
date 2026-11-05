# CRT小蟹闯塔记

一只橙色小螃蟹，在一座 360° 旧电脑塔的屏幕之间冒险。当前版本完成 **BOOT + ARCHIVE 两屏侧视动作解谜切片**；塔周边新增维修工位、电玩/贩卖角、供电储存区与顶部梁架。螃蟹始终只在 CRT 内部的 2D 屏幕活动。

仓库：[clawd-crt-tower](https://github.com/Qisi3344/clawd-crt-tower)。正式中文游戏名：**CRT小蟹闯塔记**。改名后仍使用原存档目录，已有进度不受名称变更影响。

## 开始游戏

Windows 双击 **PLAY.cmd**。本机便携 Godot 已准备好，不需要 npm、网络或账号。

其他电脑：安装 Godot 4.x（建议 4.7.2），导入 `project.godot` 后 F5；或者运行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/setup.ps1` 下载官方引擎，再打开 PLAY.cmd。首次启动脚本会生成导入缓存。源码不依赖开发者本机的绝对路径。

## 操作

| 按键 | 行为 |
|---|---|
| A / D、左右箭头 | 侧移 |
| 空格 | 跳跃，含短暂离地宽限与输入缓冲 |
| W / S、上下箭头 | 在梯子附近攀爬，不是自由飞行 |
| 按住 E / K + A / D | 面向箱石推拉；拉动时保持面向物体 |
| E / K | 开箱、使用终端、进入屏幕内端口 |
| J / 鼠标左键 | 螯击数据虫、破坏带裂纹的障碍 |
| R | 复位当前箱石谜题并返回检查点，保留宝箱/钥匙/晶体 |
| Tab | 阵列观察；拖动环绕、滚轮调高度；再按 Tab 回屏幕 |
| Esc / F3 | 暂停设置 / 性能面板 |

Shift 已保留输入，但冲刺是后续能力，本切片未开放。暂停菜单可重置箱石谜题、静音、减少转场动态、开关环境微动态、查看素材署名、保存退出。设置开关在本次会话生效。失焦自动暂停。

## 最短可复现路线

1. BOOT 向右收晶体、跳过小沟；靠近木箱，按住 E + D 将它推到 WEIGHT 1 压板。门打开后跳过箱子，继续向右。
2. 到梯子按 W 上平台，靠近宝箱按 E，取得启动密钥。继续向右到 ARCHIVE LINK 端口按 E。
3. ARCHIVE 用 J 击退数据虫。跳过入口木箱，到 W / J 的梯子上平台；向右靠近裂纹块，用 J 破坏。
4. 面向重石按住 E + D，把重石推离平台，让它落到下方 WEIGHT 2 压板。虚线箭头指示落点；角色自己的重量无法压住重板。
5. 跳过石块，通过已开启的信号门，开启档案宝箱。右侧裂墙可击破，梯子上的第二个宝箱是可选奖励。
6. 右端端口回 BOOT；ARCHIVE 中留下的重石会持续压板，所以 BOOT 的远端门也打开。向右取远端宝箱，再回端口可以重访 ARCHIVE。四个宝箱全部记录后显示切片完成提示。

石块推错时用 R；持续压板会随复位失效，但已开宝箱不会重新发奖。生命不足时，BOOT 左侧终端可花 1 晶体恢复 1 点生命，晶体不是空计数。

## 存档

自动保存生命、晶体、唯一宝箱、拾取物、当前电脑/关卡/位置、箱石位置、破墙和敌人状态。死亡在当前屏幕检查点重生。v1 原型存档会留备份并迁移到新关卡的安全入口；旧 3D 坐标和旧关卡奖励不会冒充新谜题已经完成。正式存档位于 Godot 的 user://progress.json。

## 代码与素材

- `scripts/main.gd`：会话、输入模式、路由、校验/回滚与存档联动。
- `side_world.gd`、`side_crab.gd`、`puzzle_block.gd`、`data_bug.gd`：2D 关卡与连续物理、网格步距机关、敌人。
- `monitor_device.gd`、`shell_director.gd`、`exterior_dressing.gd`：3D CRT、外部相机与装饰；键盘仅由布局字段决定。
- `scenes/environment/`、`environment_surroundings.gd`：四个独立外围分区、共享模型、遮挡隐藏与三种微动态。新布景不参与关卡碰撞与交互。
- `data/levels/`、`screen_manifest.json`、`screen_links.json`：关卡内容、身份映射与出生点连接。
- `assets/pixel/`：实际 PNG 图集、背景和待机画面。作者工具 `tools/build_pixel_assets.py` 可用 Pillow 复现图集；运行游戏不需要 Python/Pillow。
- `docs/M0_AUDIT.md`、`docs/IMPLEMENTATION_PROGRESS.md`、`docs/ASSET_CREDITS.md`：迁移边界、真实验证与素材来源。

外围实际采用 [Kenney](https://kenney.nl/assets) 四套 CC0 资源，16 种 GLB / 26 个实例，保留原始模型和许可。Mini Arcade 同时致谢 Fleur Keijsers、Guus Vermeulen。尺寸、材质、色板与部分用途经过修改；[逐项来源](docs/ASSET_CREDITS.md) / [改动记录](docs/ENVIRONMENT_CHANGELOG.md) / [画面与性能证据](docs/ENVIRONMENT_QA.md)。策划书 SF-01～04 因官方下载需要登录而受阻，没有冒称已导入。

## 验证

使用 Godot 控制台程序：

```text
--headless --editor --path . --quit
--headless --path . --fixed-fps 60 -- --qa
--path . --fixed-fps 60 -- --qa
--path . -- --perf
--headless --path . --fixed-fps 60 -- --qa --environment-qa
--path . --fixed-fps 60 -- --qa --environment-qa
```

第一条检查导入；第二条验证实际物理与流程；第三条用真实 GPU 渲染同一流程并输出屏幕/阵列/转场/竖窗口截图；第四条独立做墙钟性能采样。QA 的固定时间步 FPS 不视为性能基准。结果在 `artifacts/sideview-qa-*.json`、`performance.json`。

QA 不访问正式存档，只使用按进程号命名、测试后移除的独立文件。两屏主线走跳、推拉、攀梯、机关、开箱和往返均通过正常游戏输入测试；战斗与重量阈值另有独立定位场景，没有直接修改宝箱或解锁旗标来伪造通关。

`--environment-qa` 追加模型/预算、72 方位环绕、真实跨屏镜头、遮挡恢复、微动态菜单与素材署名检查，并输出五视图、三组同机位前后对照、三个分区近景。`--no-surroundings` 可与 `--perf` 合用作环境关闭对照，不是玩家功能。

## 当前边界

这是 M1/M2 两屏切片和 M3 样板美术，不是完整六关。POP-UP / RECYCLE / SIGNAL / ERROR、章节 Boss、更多能力、键位重映射、完整画质档位、移动端触控与平台导出尚未完成。其余十台是明确的待机/映射/故障图，不冒充已实现关卡。素材均有来源说明，未假称下载了第三方 CRT 模型。

背景音乐现使用用户指定的 NO SIGNAL 完整版（3:29），循环播放。Esc 中的音乐开关、音量与音效开关独立，重启保留；不影响冒险存档。用户提供的少量贴纸/招贴已布置在外围设施，来源见素材表。
