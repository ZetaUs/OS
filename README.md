# Nova OS

支持 BIOS 与 x64 UEFI 启动、使用 Dev-C++ MinGW 构建 32 位 C++ 内核的 x86 操作系统实验项目。

## 构建

在 `os` 目录执行：

```powershell
.\build.bat
```

构建会使用 Dev-C++ 自带的 MinGW 将 `kernel.cpp` 编译为 32 位 freestanding 内核，再生成 BIOS 磁盘镜像和独立 UEFI 启动文件。BIOS stage2 从 LBA 9 读取内核，将它复制到 2 MiB 后进入 32 位保护模式；UEFI 启动程序通过 GOP 取得帧缓冲，退出 UEFI Boot Services，再切换到 32 位保护模式并启动同一内核。内核和汇编界面以逻辑坐标绘制，并映射到 1920x1080 帧缓冲；启动时先显示 loading，再进入登录界面和桌面。启动阶段信息同时写到 COM1。内核镜像超过 BIOS stage2 可读取的 64 个扇区时，构建会报错退出。

默认检测 `D:\Program\Dev-Cpp`、Program Files 下的 Dev-C++ 或 PATH 中的 `g++.exe`。自定义安装位置时设置 `DEVCPP_HOME` 为 Dev-C++ 安装目录。

内核源文件是 `kernel.cpp`，可直接在 Dev-C++ 中打开和编辑；构建任务 `Build Nova OS` 会调用同一套 Dev-C++ MinGW 编译器完成内核与镜像构建。

## QEMU 启动

```powershell
.\run.bat
```

关闭 QEMU 窗口即可停止模拟。成功启动时依次显示 loading、登录页和桌面；在登录页将鼠标移到“登录”按钮并单击，或按 Enter 进入桌面。桌面铺满 1920x1080 画面，图标靠左排列，任务栏贴在底部。QEMU 需使用支持 VBE/Bochs 扩展的标准 VGA 设备和至少 8 MiB 显存。

桌面采用 Windows 10 风格的蓝色几何壁纸、左侧 Computer.png 与 Explorer 快捷图标和贴底的矮任务栏。桌面支持鼠标操作：单击 Computer 或 Explorer 图标打开示例窗口，单击窗口右上角的 X 关闭；单击任务栏左下角的 Nova 标志打开菜单，可从菜单打开这些窗口或选择 Restart、Shutdown。按 Esc 可关闭当前窗口和菜单。

## UEFI U 盘启动

UEFI 启动文件构建到 `build\uefi\EFI\BOOT\BOOTX64.EFI`，内核已嵌入该文件。它面向 x64 UEFI 电脑；目前要求固件 GOP 提供 1920x1080、BGRX、每行 1920 像素且帧缓冲位于 4 GiB 以下的模式，并且需要关闭 Secure Boot（启动文件未签名）。

不要把 BIOS 用的 `nova-os.img` 作为 Windows To Go 镜像写入。使用 Rufus 将 U 盘格式化为 FAT32（选择“非启动”方式），然后把 `build\uefi\EFI` 文件夹复制到 U 盘根目录，确保路径为 `\EFI\BOOT\BOOTX64.EFI`。备份 U 盘数据后再格式化；开机时从固件启动菜单选择以 `UEFI:` 开头的 U 盘启动项。
