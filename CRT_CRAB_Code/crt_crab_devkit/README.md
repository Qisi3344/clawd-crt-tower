# 屏幕群岛 / CRT CRAB

Godot 原生 3D 可玩原型。螃蟹只在电脑屏幕显示的世界里；Tab 可以拉远观察包围自己的三层电视阵列。

## 运行

Windows 双击 **PLAY.cmd**。本机已准备便携 Godot 后无需联网、无需 npm 或账号。

另一台电脑：先安装 Godot 4.x（建议 4.7.2），导入 `project.godot` 并按 F5 运行；也可以运行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/setup.ps1` 下载官方便携引擎，然后打开 PLAY.cmd。源码不依赖本机绝对路径。

## 操作与路线

- WASD / 方向键移动，空格跳跃，J / 鼠标左键螯击，Shift 短冲，E 交互。
- 右键拖动微调关卡视角；Tab 观察电脑阵列，左键拖动环绕、滚轮调高低；再次 Tab 回到当前屏幕。
- Esc 暂停，菜单中有音效和减少转场动态；F3 查看实时性能信息。
- 开局去左后方的信号终端按 E；再去右后方接口按 E，转移到上层另一侧的 ARCHIVE。
- J 或左键攻击两种病毒，每只需两击。清除后到右后方拾取记录，可以从入口传回 BOOT。
- 自动保存信号、记录、击败敌人、当前屏幕、位置和生命。死亡在当前屏幕入口重生。退出用菜单或窗口关闭按钮。

## 结构

`main.gd` 管理唯一活跃世界；`screen_world.gd` 处理微关卡；`crab_player.gd` 与 `crab_avatar.gd` 处理真实物理和分件动画；`monitor_device.gd` 构造 CRT；`shell_director.gd` 管理外层镜头；`hud.gd`、`audio.gd`、`save_store.gd` 分别处理界面、合成声音和原子存档。设备位置、关卡描述和传输连接位于 `data/`。

美术以用户提供的《绝区零》电视堆叠参考为主：深灰 CRT、实体旋钮和扬声器、错层设备、屏幕亮色。橙色螃蟹沿用指定 clawd-motion 的形体比例。见 `docs/ASSET_CREDITS.md`。

## 验证

用 Godot 执行 `--headless --editor --path . --quit` 导入检查，然后 `--headless --path . -- --qa` 运行物理与流程测试；去掉 `--headless` 会运行同一路线并生成真实渲染截图。结果写到 `artifacts/qa-headless.json`、`artifacts/qa-visual.json`。

QA 不读取或改写玩家正式存档。磁盘存档验证只使用独立的 `user://qa-roundtrip-<进程号>.json`，测试后移除该测试文件。

这是 **P0 + P1 原型**，目前有两个可玩屏幕，其他十台为独立待机画面；不是手册中六关、三谜题和 Boss 的完整版本。PC 键鼠为本轮目标，尚未提供手机触控操作或移动平台包。具体测试证据与限制见 `docs/IMPLEMENTATION_PROGRESS.md`。
