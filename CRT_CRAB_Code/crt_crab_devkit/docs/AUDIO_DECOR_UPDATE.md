# 音乐与用户装饰接入

2026-11-05。使用用户指定的 NO SIGNAL 完整版原始 MP3，209 秒，循环播放；没有使用短版。音乐开关与音量独立于音效，默认 35% 并另衰减 12dB，让交互音效更清晰。音乐不中断于普通切屏或暂停，关闭音乐使用暂停播放，重新开启接着播放。重启保留音乐开关/音量及音效开关，单独保存 user://audio.cfg。

从用户装饰包实际布置七张原图：维修背板 NO SIGNAL，街机下部 CRT CRAB / BOOT OK，后侧板 ARCHIVE LINK / CRT 海报 / 404 / 爪痕。避开活动玻璃，保留原图透明度；来源与散列见 assets/environment/decals/user/source_manifest.json。

85 项 headless、87 项 GPU 回归通过，渲染 stderr 为空。新增检查涵盖完整时长/循环、音乐暂停开关、静音音量和独立临时文件落盘。QA 和性能模式不自动播放 BGM，不访问正式音频设置；音频用例显式播放并使用 qa-audio-进程号.cfg，随后移除。未修改玩家正式存档。本次未重测性能，不沿用旧数据宣称新增音乐的性能。

[headless 结果](audio_decor_evidence/sideview-qa-headless.json) / [GPU 结果](audio_decor_evidence/sideview-qa-visual.json) / [暂停设置](audio_decor_evidence/m2-pause.png) / [场景](audio_decor_evidence/environment-front.png) / [维修背板](audio_decor_evidence/environment-detail-repair.png) / [电玩及后板](audio_decor_evidence/environment-detail-arcade.png)。

复现：Godot --headless --path . --fixed-fps 60 -- --qa --environment-qa；去掉 --headless 为 GPU 验证。正常启动 PLAY.cmd 后 Esc 可调音乐。
