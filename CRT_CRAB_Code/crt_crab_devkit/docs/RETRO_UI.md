# 像素 UI 与双向爬梯修复

单向平台原先允许向上穿越，却阻挡从梯顶向下进入。现在只在小蟹攀梯时忽略单向平台，退出攀梯后恢复；地面、墙、门和箱子仍正常碰撞。实机检查覆盖下梯落地、再次上梯、开箱、推箱与跨屏往返。

暂停菜单移除重置谜题、扭蛋入口、素材署名按钮和底部调试/操作说明；谜题复位快捷键 R、主菜单扭蛋入口和现有署名文件保留。

UI 使用十色暖紫/奶白/橘黄色板。全局统一 Fusion Pixel 12px 简体中文等宽字体，正文 24px、标题 36px 并加粗；细硬边框与偏移硬阴影、按钮按下文字下沉、焦点轻摆，减少动态开启时停用轻摆和提示光标闪烁。HUD、主菜单与衣橱使用相同 32×32 像素网格图标，钥匙单独绘制；开箱与拾取晶体有 0.4 秒像素散粒。

全画面 CRT 层无鼠标拦截：扫描线最大暗化 1.8%，边缘暗角最大 7.5%，仅对高亮邻域增加轻微发光，没有大面积 Bloom。场景模型与像素玩法原色保留，十色约束用于 UI。

字体来源：[TakWolf/fusion-pixel-font 2026.10.25](https://github.com/TakWolf/fusion-pixel-font/releases/tag/2026.10.25)，SIL OFL 1.1；简体中文 WOFF2 解包为 OTF，不修改字形。原许可及上游组件许可保存在 `assets/fonts/`。无运行时下载依赖。

## 实机证据

- [主菜单](retro_ui_evidence/title.png)
- [精简暂停菜单](retro_ui_evidence/pause.png)
- [梯子下行到地面](retro_ui_evidence/ladder-down.png)
- [开箱与像素反馈](retro_ui_evidence/treasure.png)
- [竖屏扭蛋 UI](retro_ui_evidence/gacha-mobile.png)

Godot 4.7.2 Windows 实机渲染，冒险流程 76、菜单/存档 49、扭蛋 47 项全部通过，最终三轮错误日志为空。报告见本目录 `retro_ui_evidence/`。测试含 1280×800 横屏及桌面竖屏、合成触摸事件；未使用手机硬件验证，不将固定时间步测试中的 FPS 当作性能基准。
