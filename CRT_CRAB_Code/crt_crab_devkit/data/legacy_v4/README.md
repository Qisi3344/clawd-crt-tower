# 布局 v1 / 存档 v4 基线

这里保存重构前六关与跨 CRT 链接的原始 JSON。`tools/rebuild_exploration.py` 从这里生成布局 v2；不可用新地图覆盖这些基线。

存档版本和空间布局版本独立。正式迁移由 `LayoutMigration` 按新定义的 `legacy_offsets` 合并旧房间状态，物件和奖励沿用原 ID。源文件保留在自动备份中，不能通过设置通关标志来弥补位置迁移。
