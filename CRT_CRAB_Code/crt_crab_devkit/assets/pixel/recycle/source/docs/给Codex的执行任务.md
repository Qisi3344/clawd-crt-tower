# 给 Codex 的执行任务 · RECYCLE 回收站美术接入（仅此一关）

仓库：`https://github.com/Qisi3344/clawd-crt-tower`。工程目录：`CRT_CRAB_Code/crt_crab_devkit/`。

任务：请实际将本素材包接入 **RECYCLE（回收站）**，不只是阅读或给建议。先完整阅读包内 `README_先看.md`、`docs/RECYCLE_素材位置与Godot接入说明.md`、`manifest.json`，再核对仓库当前 `data/levels/recycle_01.json` 与最新 ARCHIVE v2 的制作方式。

## 必须做到

1. 仅改 RECYCLE 视觉分支；BOOT、ARCHIVE、POP-UP、SIGNAL、ERROR 保留现状。
2. 以 `game/far.png` 和 `game/mid-continuous.png` 为地图尺寸匹配的远中景起点，结合 `source/` 里的高完成度场景风格细化；**绝对禁止把带标题/样板文字的概念海报直接贴进游戏**。
3. 背景使用连续 1024×768 世界坐标绘制，不能再从源图裁三块几十像素宽的矩形等间距循环。
4. 中景所有可见建筑、管线、回收机械的衔接需连续自然；不得新画没有实际碰撞的可走横桥、攀梯或可互动设备。
5. 12 类独立透明道具按 `upper_left/cache/sorter/maintenance/scrap/well/tunnel` 的区别摆放；不要乱撒，也不能遮住真机关。
6. 游戏原有真实地形视觉可换成工业金属材质，并与背景统一；但碰撞/关卡 JSON/箱石/输送带/压机/磁吸/宝箱/数据片/存档/传送/操作逻辑必须完全保留。
7. 小范围增加必要动态效果，例如发光状态、灯光微闪，主角和机关永远更醒目；注意低端硬件性能。
8. 完整 Godot 实机运行，输出上层、中层、下层、竖井 4 区以及视角左右边缘的屏幕截图；至少一次正常行走与机关互动录像。截图必须是真实 Godot 画面，**不得把包内 `preview/` 冒充实机结果**。
9. 检查单个 320×240 SubViewport，任何改动不影响其他五关；报告仍存在的视觉问题。

建议修改入口：`scripts/world_backdrop.gd`、`scripts/side_world.gd`、可新增 `scripts/recycle_dressing.gd` / `data/recycle_dressing.json`，资源放 `assets/pixel/recycle/`，不要将整张大图散放进多个系统。

**此次范围仅为美术接入与验证，不拓展地图尺寸、关卡玩法或任务系统，不顺手优化其他五关。**
