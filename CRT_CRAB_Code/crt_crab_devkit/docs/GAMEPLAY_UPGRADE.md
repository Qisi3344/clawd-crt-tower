# 六屏玩法升级：可读目标与操作反馈

本轮基于 GitHub main `56a9ae6` 开发，保留真实多层 3D CRT 阵列、单一屏幕内螃蟹、连续多层地图和原有存档格式。现有服装与宠物内容继续使用仓库最新版。未推送远程。

## 已落地

六章常驻任务卡直接读取实际机关状态，展示当前目标、下一步、阶段进度和未完成条件。暂停页提供完整任务清单，阵列页显示六章状态。任务层只读取存档，不给旗标、奖励或权限。档案压板失去重量时，信号和核心任务会提示真实输入中断。

BOOT 以推箱供压、爬梯取密钥为两步；ARCHIVE 以重石持续供压、取档案密钥为两步；POP-UP 明确两枚保险丝与最终修复的区别；RECYCLE 支持三片数据乱序取得并要求最终装配；SIGNAL 分 A 校准、蜜蜂充电、B 旁路、C 光纤、总线确认；ERROR 用实时 boss 检查点解释当前护罩，避免历史旗标误报。

Shift 闪避已实装到实际使用的 SideCrab：短冲 0.14 秒，速度 230，防御窗口 0.18 秒，冷却 0.85 秒。保留实体碰撞，不在爬梯或推拉时启动，暂停时不可启动。HUD 显示就绪、冷却和禁用原因。

靠近压板显示实际重量、需求和接通状态。读数来自同一套实体重量计算，轻箱、重石、螃蟹和机械动物均参与实际判定。

六关增加现场检查终端。镜片交互提示与绘制使用一致的三态方向；输送带、磁吸爪、安全停机、绝缘开关显示当前状态，修复台显示前置完成数。两组保险丝和 Boss B 校验对应镜片，避免无关反射弹误解题。Boss C 反接后重新给出预警，需要站在安全区才能推进；站在危险区挨打不能换阶段。ERROR 增加可选猫头鹰装甲靶，原前厅仍保留螯击解法。飞蛾受击硬直暂停发射计时，非碾压螯击会重新开始完整瞄准预警，预瞄线对齐实际弹道。

## 后续复测

第一轮已保存为本地提交 `2a64de6`。此前机械动物测试在加速执行下出现时序失败；按正常时间倍率运行 `--qa --ecology-qa` 后，现场记录全部通过，包含飞蛾反射、备用发射器防软锁、跳蚤跳跃、蜗牛压板、蜘蛛断线、压机仓鼠、河狸、电鳗与模拟手柄移动。此为正常速度复测结果，未删去测试断言。新增飞蛾打断后重新预警的两项行为测试也已先失败后通过。

## 运行

双击项目根目录 PLAY.cmd。若需要命令行，使用项目内 `.tools/godot/Godot_v4.7.2-stable_win64.exe --path .`。此目录已准备本机引擎与导入缓存，默认打开正常游戏主菜单。

移动 A/D，Space 跳跃，W/S 爬梯，J 或鼠标左键螯击，Shift 闪避，E 互动，按住 E 加方向推拉，R 复位当前区域，M 局部地图，Tab 电脑阵列，Esc 暂停。

## 验证命令

在项目根目录运行以下命令（Windows 的 bash）：

```bash
./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/dash_qa.gd
./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/pressure_feedback_qa.gd
./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/mission_director_qa.gd
./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --qa --gameplay-upgrade-qa
./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . -- --qa --gameplay-upgrade-qa
./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --qa --chapter-qa
```

最后一项为完整连续关卡输入回归，需要数分钟。测试模式不访问正常玩家存档。报告位于 artifacts，渲染截图以 upgrade- 开头；每章包含窗口截图和真实 320×240 屏幕内部图。

## 范围与下一轮验收

此次保留现有原创像素素材，以战术信息与街机操作反馈推进二游气质。未复制《绝区零》《明日方舟》的角色、商标、音效或界面资源；不宣称已完成商业游戏级美术重制。开源源码参考和逐章设计依据见 GAMEPLAY_REFERENCES.md。

自动化通关能证明流程可达、状态和存档有效，不能替代真人对趣味和节奏的评价。首轮试玩应记录：玩家何时第一次不懂下一步、是否能解释压板和反射机制、受伤是否知道原因、每章是否有记得住的操作。2026-11-17 接续收尾已直接打开真实 OpenGL 截图，检查 BOOT、ERROR 与竖屏的任务卡和场景；本次验证及正确启动入口见 HANDOFF_2026-11-17.md。
