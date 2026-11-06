@echo off
setlocal
cd /d "%~dp0"
if exist ".tools\godot\Godot_v4.7.2-stable_win64.exe" (
  ".tools\godot\Godot_v4.7.2-stable_win64.exe" --path . res://scenes/pets/preview.tscn
) else (
  godot --path . res://scenes/pets/preview.tscn
)
if errorlevel 1 pause
