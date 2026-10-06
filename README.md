# Nova OS

从 BIOS 引导扇区启动、使用 Dev-C++ MinGW 构建 C++ 内核的 x86 操作系统实验项目。

## 构建

在 `os` 目录执行：

```powershell
.\build.bat
```

构建会使用 Dev-C++ 自带的 MinGW 将 `kernel.cpp` 编译为 32 位 freestanding 内核，再与 NASM BIOS 引导程序一起生成磁盘镜像。stage2 查询 VBE 线性帧缓冲并将 QEMU VBE 扩展切换到 1920x1080x32，再从 LBA 9 读取内核、切换到 32 位保护模式并跳转到 C++ 入口。内核和汇编界面以逻辑坐标绘制，并映射到 1920x1080 帧缓冲；启动时先显示 loading，再进入登录界面和桌面。启动阶段信息同时写到 COM1。内核镜像超过 stage2 可读取的 64 个扇区时，构建会报错退出。

默认检测 `D:\Program\Dev-Cpp`、Program Files 下的 Dev-C++ 或 PATH 中的 `g++.exe`。自定义安装位置时设置 `DEVCPP_HOME` 为 Dev-C++ 安装目录。

内核源文件是 `kernel.cpp`，可直接在 Dev-C++ 中打开和编辑；构建任务 `Build Nova OS` 会调用同一套 Dev-C++ MinGW 编译器完成内核与镜像构建。

## QEMU 启动

```powershell
.\run.bat
```

关闭 QEMU 窗口即可停止模拟。成功启动时依次显示 loading、登录页和桌面；在登录页将鼠标移到“登录”按钮并单击，或按 Enter 进入桌面。桌面按 800x600 显示并居中放置在 1920x1080 画面中。QEMU 需使用支持 VBE/Bochs 扩展的标准 VGA 设备和至少 8 MiB 显存。

桌面采用 Windows 10 风格的蓝色几何壁纸、左侧快捷图标和底部深色任务栏。桌面支持鼠标操作：单击 MY PC 或 FILES 图标打开示例窗口，单击窗口右上角的 X 关闭；单击开始按钮打开菜单，可从菜单打开这些窗口。按 Esc 可关闭当前窗口和菜单。
