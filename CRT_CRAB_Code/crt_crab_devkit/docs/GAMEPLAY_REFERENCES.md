# 六章玩法参考：源码核查与原创转化

调研日期：2026-11-17（UTC）。通过已认证 `gh api repos/{owner}/{repo}` 核验星数与许可证；通过 contents API 解码 README、许可证和下列源码。星数为该时点快照，只用于筛选关注度，不代表玩法适配或质量评分。本次为静态源码研究，未试玩三个参考项目，也未验证本项目运行时行为。

## 参考项目与实际阅读范围

| 项目 | API 实测 stars | 许可证 | 选择原因与已读文件 |
| --- | ---: | --- | --- |
| Shattered Pixel Dungeon | 6,813 | GPL-3.0 | 随机地牢、战术取舍；读 `README.md`、`LICENSE.txt`、`RegularLevel.java`、`Tengu.java`。[1][2][3] |
| Mindustry | 29,879 | GPL-3.0 | 自动化塔防 RTS；读 `README.md`、`LICENSE`、`PowerGraph.java`、`MapObjectives.java`。[6][7][8] |
| Godot 官方 2D Platformer 示例 | 9,802（**整个 demo 仓库**，并非单独平台游戏） | MIT | 像素横版操作参照；读根 `README.md`、`LICENSE.md`、`2d/platformer/README.md` 及 `player.gd`、`enemy.gd`、`level.gd`、`gun.gd`。[11][12][13] |

Godot 示例 README 明确说明它是单个封闭关卡、玩家无敌；不能据此声称它实现了完整死亡重试或六章进度系统。[14]

## 从源码提取的具体原则

1. **回环要节省已证明掌握的路程。** `RegularLevel.builder()` 在 `LoopBuilder` 与 `FigureEightBuilder` 间选择；`createMobs()` 排除入口的八格视野及八格开放步行范围。可转化为“先安全观察、再进入挑战、成功后打开回路”；不能把八格数值照搬成横版像素距离。[4]
2. **危险先可读，再升级组合。** `Tengu.damage()` 在半血推进阶段；`targetAbilityUses()` 随 arena jumps 增加技能次数；`BombAbility.act()` 先显示 3/2/1，再结算爆炸。可借鉴阶段分工和预告，让挑战来自判断与执行。[5]
3. **真实供能与曾经完成必须分开。** `PowerGraph.update()` 每次重新汇总需求、产出、电池并分配覆盖率；图拆分后也更新失电消费者。`MapObjective.done()` 则记录完成，`dependencyFinished()` 缓存父目标完成。这两类语义不同：不可把一次完成标志当作持续有效电路。[9][10]
4. **任务依赖要能在场景中读出来。** `MapObjective` 有 `parents`、`details`、`flagsAdded`、`markers`，只有依赖完成的目标参与更新；`FlagObjective.update()` 检查具体标志；`TextMarker` 将文本落在位置上。可将三路诊断变成近场节点状态，而非只堆任务说明。[10]
5. **移动与反馈分层。** Godot `Player._physics_process()` 使用加速度趋近目标速度，松开跳跃时削减向上速度，限制下落速度；`get_new_animation()` 区分站立、奔跑、上升、下降与射击。[15]

   `Gun.shoot()` 用冷却 Timer 决定是否成功发射，成功才播放音效、启动计时。[18]

   `Enemy` 用地面探测和墙体碰撞改变方向；`level.gd` 设置相机边界。[16][17]

## 对照本项目六关：每章一个可记住的操作

已读取 `data/levels/{boot,archive,popup,recycle,signal,error}_01.json` 六个完整 JSON，并提取实体、区域、连接、教程、条件与输出核对。以下“现有”仅指配置事实；“建议/验收”是本次原创设计提案，需要后续实现和试玩。

| 章节 / 现有配置锚点 | 建议转化与验收重点 |
| --- | --- |
| **BOOT：安全学会启动**。`boot_box → boot_plate → boot_door`；无敌人；已有 jump/push/ladder 教程；下层回路依赖 `recycle_route_repaired`。 | 按“跳过小台阶→推箱触发灯带→爬梯领奖”逐个呈现操作，每次触发给门和压板同帧可见反馈。把后期回访门先作为可识别地标，避免初见像误锁主路。验收：首次开门不依赖其他章节，回访奖励不阻断新手路径。原则 1、5。 |
| **ARCHIVE：重量是信号**。轻 `archive_box`、重 `heavy_boulder`、需求重量 2 的 `heavy_plate`；主/上/下门共用 `signal_archive_gate`；有 `data_bug_01` 和裂板。 | 用轻箱做低风险反例，重石做正例，灯条明确显示“当前重量/需求”。敌人与碎板只在玩家理解重量后增加操作取舍；上层快路、下层秘密各有独立奖励。验收：移开重石后显示真实失电；已拿宝箱不重复结算；不能用历史完成状态伪造持续压板信号。原则 1、3。 |
| **POPUP：把攻击变成工具**。两组导流镜/接收器，飞蛾与 `fallback_a/b` 备用脉冲，`popup_repair` 要求两保险丝，成功恢复供电。 | 第一组安全练习“看弹道→转镜→命中”；第二组加入弹窗开合节奏或高低位变化，避免重复同一道题。命中后用流动光线串起保险丝与危险关闭。保留备用脉冲，敌人死亡也可解题。验收：先击败两只飞蛾仍能完成两保险丝；反馈不靠颜色单独传达。原则 2、5。 |
| **RECYCLE：一条可操纵的小生产线**。`belt_a` 可反向、`press_a/safe_stop`、`roller`、磁吸爪、三片数据；`assembly` 输出重构包和回访线路。 | 三片分别突出输送方向、停机时机、磁吸落点；最终装配只检查已学结果。为压机加蓄力预告和安全站位；显示钢块去向及传感器是否真的压到。成功让吊台捷径成为明显缩短回程的奖励。验收：钢块失位可局部复位，保留已取得碎片；安全停止后操作不会被隐藏周期击中。原则 1、2、3。 |
| **SIGNAL：临时通电变成永久旁路**。蜂节点同时有 `signal_bee_live`、`signal_bee_charged`、`temporary`、`signal_shortcut`；A 依赖档案重量，C 依赖重构包。 | A/B/C 各给形状和短标签；清楚区分“蜂在场 LIVE”“曾充电 CHARGED”“旁路已保存”。先观察巡航窗口再穿桥，到岸立刻看到锁定旁路的收益。诊断台逐项显示当前失败来源并指向所在章节。验收：蜜蜂离开后临时桥按设计失效，保存旁路后返程安全；A 失去真实重量时不能仅凭历史校准放行。原则 3、4。 |
| **ERROR：三项能力的终场演出**。前厅破面板、错相双压机（`offset: 1.3`）、核心授权检查、重钢块和 `boss_reflector`；配置有 `error_node_a/b` 回路门，但机制实现须另查运行时代码。 | 提案分“重量稳定 A→借弹导流 B→线路确认 C”，每阶段只强化一种已学操作；成功打开现有 A/B 回路并短暂停顿，让角色反应、核心亮灯、环境音共同标记进展。验收：失败退回最近安全点；不重做已完成长路；所有伤害先预告且有可达安全位。不要仅因 JSON 出现节点名就宣称现有 Boss 已具备阶段战。原则 1、2、4。 |

## 落地优先级与原创表现

- **P0：可理解、可恢复。** 重量/通电读取真实状态；飞蛾死后保留解题途径；钢块失位提供局部复位；诊断显示具体缺哪一条依赖。先验证全部六章可通关，再调难度。
- **P1：章内节奏。** 每章安排安全观察、单机制练习、一次组合挑战、捷径回报；把普通移动路程压缩，把判断时间留给核心机关。测试记录“卡住位置、失败原因、回到挑战所需时间”。
- **P2：原创动漫战术街机感。** 设计自有螃蟹角色动作、章标题切入、短促命中停顿、技能姿态和机关响应音；导流成功用原创轨迹残影强调“利用敌方火力”，修复用环境逐级复苏表现成就。上述为原创演出提案，不是声称参考源码已有这些效果。

只抽象规则、状态机、反馈时序与关卡组织；美术、音效、角色、文本、UI 构图和关卡布局自行设计。

GPL 项目不直接搬运实现到许可证不兼容的代码；若未来复用任何代码，应单独核对授权和分发义务。[3][8]

MIT 复用须保留相应版权及许可文本；Godot 示例还标有音乐作者，资源权利需逐件检查。[13][14]

本次没有复制任何参考项目代码或资产。

## Sources

[1] https://api.github.com/repos/00-Evan/shattered-pixel-dungeon
[2] https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/README.md
[3] https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/LICENSE.txt
[4] https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/levels/RegularLevel.java
[5] https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/actors/mobs/Tengu.java
[6] https://api.github.com/repos/Anuken/Mindustry
[7] https://github.com/Anuken/Mindustry/blob/master/README.md
[8] https://github.com/Anuken/Mindustry/blob/master/LICENSE
[9] https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/world/blocks/power/PowerGraph.java
[10] https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/MapObjectives.java
[11] https://api.github.com/repos/godotengine/godot-demo-projects
[12] https://github.com/godotengine/godot-demo-projects/blob/master/README.md
[13] https://github.com/godotengine/godot-demo-projects/blob/master/LICENSE.md
[14] https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/README.md
[15] https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/player/player.gd
[16] https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/enemy/enemy.gd
[17] https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/level/level.gd
[18] https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/player/gun.gd
