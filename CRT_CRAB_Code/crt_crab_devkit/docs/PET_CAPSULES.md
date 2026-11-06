# 六款宠物扭蛋与扭蛋机

六款均为 Godot 原生 Mesh / SurfaceTool 构造，没有第三方模型或抽奖逻辑。上半透明罩、彩色下半球、接缝圈及动物头部是独立网格；球体和材质复用缓存。模型原点位于底端，正面朝 +Z，基础球壳直径 2 单位。

| 独立场景（`scenes/pets/`） | 外观与稀有度 |
| --- | --- |
| `cat.tscn` | 米白、灰斑、尖耳、胡须；普通 |
| `dog.tscn` | 奶茶、垂耳、奶白口鼻、吐舌；普通 |
| `hamster.tscn` | 浅棕、圆耳、胡须、门牙、青绿下壳；稀有 |
| `rabbit.tscn` | 粉色长耳、粉色下壳；稀有 |
| `bear.tscn` | 棕色圆耳、奶白口鼻、青绿下壳；稀有 |
| `hidden_cat.tscn` | 深紫、柔金发光尖耳、像素眼、金色下壳；隐藏 |

调用方式：`load("res://scenes/pets/cat.tscn").instantiate()`，加入任意 Node3D 后调整位置与缩放。共享脚本为 `scripts/pet_capsule.gd`，没有碰撞体、奖励、随机概率、存档写入或额外灯光。

双击 **PET_PREVIEW.cmd** 可在现有游戏厅内查看六款并排模型；按住鼠标左键拖动统一旋转，Esc 退出。也可直接运行 `scenes/pets/preview.tscn`。桌子仅用于预览，不加入正常游戏厅。

## 场景放置

根据用户标注，用原生扭蛋机替换电玩区靠电脑塔、位于右前方的那台街机。电玩区局部位置 (-2,0,0.7)，朝向 -8°；另一台街机、贩卖机、票机、电脑塔和其他区域保留。

`scripts/pet_gashapon_machine.gd` 制作米白/奶茶与青绿机身、猫耳、透明仓、粉色旋钮、价格牌、实体出蛋凹槽、侧面爪印、背面检修盖与通风槽。仓内展示六款缩小模型，当前是静态陈列，旋钮不可抽奖。前面板价格沿用参考图，仅作模型装饰。

机台整组注册到已有观察遮挡系统，屏幕聚焦与传送时整体显隐，避免单独隐藏部分零件。局部光和原街机屏幕引用自动指向保留下来的街机。

## 实机图

![六款并排](pet_capsule_evidence/front.png)

![右前方机台](pet_capsule_evidence/machine.png)

![游戏厅位置](pet_capsule_evidence/hall.png)

[侧面](pet_capsule_evidence/side.png) · [背面](pet_capsule_evidence/back.png)

## 可复现检查

使用本机 Godot 4.7.2 OpenGL Compatibility 渲染。运行 `godot --path . res://scenes/pets/preview.tscn -- --pet-check`，自动检查六款实例及半球、透明材质结构，保存正侧背截图和 JSON 至 `artifacts/pet-capsules-*`。正常流程回归使用既有 `--qa --environment-qa`；全场聚焦与环绕使用 `tests/arcade_hall_qa.gd`。

验收 JSON 见本目录 `pet_capsule_evidence`。原屏幕玩法、传送、关卡映射、存档代码均未修改。

- 六款结构检查 12/12 通过，保存正侧背真实渲染截图。
- 玩法与环境回归 90/90 通过；359 左右的实际传送镜头采样无环境穿模（具体采样数见 JSON）。
- 环境几何总量 56,819 三角面，低于原 60,000 预算；移除一台 GLB 街机后仍有 25 个原素材实例。
- 全场艺术检查 37/37，包含十二屏聚焦与 72 步环绕。
