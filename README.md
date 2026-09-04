# Nova OS

从 BIOS 引导扇区开始构建的 16 位 x86 操作系统实验项目。

## 构建

在 `os` 目录执行：

```powershell
.\build.bat
```

构建会把 `logo.png` 转为 160x160 RGB332 全彩像素，并按“启动扇区、第二阶段、logo 像素”的顺序生成镜像。启动器进入 VGA Mode 13h，在左上角显示 logo。

## QEMU 启动

```powershell
.\run.bat
```

关闭 QEMU 窗口即可停止模拟。当前版本只显示 logo，不加载 `load.gif`。
