# M0 审计与适配边界

- 审计日期：2026-11-05。引擎为 Godot 4.7.2 / GDScript / OpenGL Compatibility，主入口 `scenes/main.tscn`，Windows 启动 `PLAY.cmd`。
- 改造前：12 台 CRT、三层 360° 阵列，一个 480×360 的独立 3D SubViewport，两块可往返的 3D 微关卡，CharacterBody3D 螃蟹，外部镜头、HUD、合成音效与 version 1 JSON 存档。
- 本次依据：项目外层的 `CRT_CRAB_Code_B/00_README_先交给Codex.md`、场景执行单 v1.1、玩法开发书 v1.0。旧 DEVELOPMENT_MANUAL 的屏幕内 3D 规定已被新版侧视规范替代。
- 回退点：Git 分支 `codex/sideview-slice`，改造前提交 `b21fb21`。基线真实截图保存在 `artifacts/baseline/`，运行记录在 `artifacts/baseline-run.log`，当时无错误。
- 保留：外层阵列位置与三维结构、底层键盘/上层无键盘配置、ShellDirector、CRT 屏幕材质、传送的空间连续性、既有 HUD 和音效模块。
- 替换：当前入口使用 SideWorld / SideCrab / PuzzleBlock / DataBug / Camera2D；旧 ScreenWorld / CrabPlayer / CrabAvatar 代码仍留作原型参考，当前游戏不实例化它们。旧 tests/runtime_qa.gd 也是历史 3D 用例；当前 `--qa` 运行 tests/sideview_qa.gd。
- 新增：320×240 独立 2D World2D、像素图集、两张数据化关卡、重量机关、宝箱账本、跨屏持续信号、R 局部复位、version 2 存档，以及四类机壳的样板美术。
- 身份区分：实体 `computer_id` 位于设备布局；关卡 `level_id` 位于 manifest；连接有唯一 id 和目标电脑/出生点；BOOT / ARCHIVE 是界面与路由的可读名称。
- 迁移：v1 完整内容保留在 v2 的 legacy_progress；磁盘旧文件另保留 `.v1-backup`。旧 3D 坐标不投射成错误的 2D 位置，进入 BOOT 安全入口；旧生命保留，新的关卡机关与宝箱按新规则开始。
- 输入模式明确区分 PLAY_2D / TRANSITION_3D / ARRAY_VIEW / PAUSED。只有当前屏幕内的一只螃蟹接受操作。QA 与性能探针禁用正式存档的读取、写入与删除。
