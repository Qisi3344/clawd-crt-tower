# 六关拓扑对照（布局 v2）

旧：BOOT/ARCHIVE 横向一层；后四关通过 E 端口逐间切换。
新：每关一个连续物理空间；下列每条边均为可步行或攀爬的双向连接。跨 CRT 端口另行保留。

## BOOT · 1024 × 640

```mermaid
flowchart TD
  upper["维护灯带 / 上层"]
  main["中央电源大厅 / 中层"]
  lower["回访线路井 / 下层"]
  main <-->|"↑ 维护灯带"| upper
  upper <-->|"↓ 中央大厅 · boot_gate_open"| main
  main <-->|"↓ 回访线路井"| lower
  lower <-->|"↑ 返回大厅 · recycle_route_repaired"| main
```

## ARCHIVE · 1024 × 640

```mermaid
flowchart TD
  upper["上层检索桥 / 上层"]
  main["重压归档大厅 / 中层"]
  lower["破损记录仓 / 下层"]
  main <-->|"↑ 上层检索桥"| upper
  upper <-->|"↓ 中央大厅 · signal_archive_gate"| main
  main <-->|"↓ 破损记录仓"| lower
  lower <-->|"↑ 返回大厅 · signal_archive_gate"| main
```

## POPUP · 1024 × 768

```mermaid
flowchart TD
  hall["故障广告大厅 / 中层"]
  east["供电竖井 / 中层"]
  loft["封存缓存夹层 / 上层"]
  shaft["重叠窗口保险室 / 上层"]
  drain["底层缓存回路 / 下层"]
  hall <-->|"↑ 缓存夹层"| loft
  hall <-->|"→ 第二保险室 · popup_fuse_a"| east
  east <-->|"↑ 供电竖井"| shaft
  shaft <-->|"← 大厅捷径 · popup_power_restored"| loft
  hall <-->|"↓ 缓存回路"| drain
  drain <-->|"↑ 返回保险室 · popup_fuse_a"| shaft
```

## RECYCLE · 1024 × 768

```mermaid
flowchart TD
  upper_left["吊装观察台 / 上层"]
  cache["数据重构吊台 / 上层"]
  sorter["中央分拣大厅 / 中层"]
  maintenance["侧面维护竖井 / 竖井"]
  scrap["地下废料坑 / 下层"]
  well["磁吸拆解井 / 下层"]
  tunnel["回访磁吸暗道 / 下层"]
  sorter <-->|"↑ 吊装观察台"| upper_left
  sorter <-->|"↓ 废料坑 / 磁吸井"| scrap
  scrap <-->|"→ 磁吸井"| well
  well <-->|"→ 维修井 · recycle_heavy_supported"| maintenance
  maintenance <-->|"↑ 重构吊台"| cache
  cache <-->|"← 分拣大厅捷径 · recycle_route_repaired"| upper_left
  scrap <-->|"← 回访暗道 · recycle_route_repaired"| tunnel
```

## SIGNAL · 1024 × 768

```mermaid
flowchart TD
  hub["三路中央诊断台 / 中层"]
  a["A 真实源信号塔 / 上层"]
  relay["B 继电蜂桥 / 中层"]
  fiber["C 光纤汇流井 / 上层"]
  return["侧面光纤干道 / 竖井"]
  water["绝缘水道旁路 / 下层"]
  hub <-->|"↑ A 真实源"| a
  hub <-->|"→ B 继电蜂桥"| relay
  return <-->|"↑ C 光纤汇流"| fiber
  fiber <-->|"← 诊断台捷径 · signal_core_ready"| a
  hub <-->|"↓ 绝缘水道"| water
  water <-->|"→ 保存旁路 · signal_shortcut"| return
```

## ERROR · 1024 × 768

```mermaid
flowchart TD
  foyer["蓝屏前厅 / 中层"]
  piston["活塞故障线 / 中层"]
  observation["核心观察环 / 上层"]
  diagnostic["核心诊断站 / 上层"]
  west["A 返回维护道 / 下层"]
  boss["蓝屏核心室 / 下层"]
  east["核心安全入口 / 下层"]
  foyer <-->|"→ 活塞故障线 · error_foyer_open"| piston
  piston <-->|"↑ 核心诊断站"| diagnostic
  east <-->|"← 核心 A → B → C · error_diagnostic_cleared"| boss
  boss <-->|"← A 返回前厅 · error_node_a"| west
  foyer <-->|"↑ 核心观察环"| observation
  observation <-->|"→ B 上层回环 · error_node_b"| diagnostic
```
