# Os Switcher

**OsSwitcher** 是一款简洁、实用的系统切换工具，允许用户在操作系统正常运行时

无缝切换到其他操作系统，无需在启动阶段手动选择 GRUB 菜单。

<p align="left">
  <img src="https://github.com/user-attachments/assets/abd0a4e1-44e3-4c3a-9609-b32ef3b19970" alt="OsSwitcher" width="50%">
</p>

## 主要特点

- **无缝系统切换**：在当前操作系统运行时，轻松切换到其他操作系统。
- **无需手动选择 GRUB 菜单**：避免启动阶段的手动选择，提高切换效率。
- **适用于远程控制**：特别适合需要远程操作的场景，解决在 bootloader 阶段无法操作 GRUB 选项的问题。
- **多系统管理**：安装完成后，可以轻松管理同一设备上的 Windows 和 Linux 系统。

## 使用说明

**注意**：需要win关闭快速启动和休眠功能。

### 1. 安装

#### 1.1 运行 `setup.sh` 脚本，完成初步安装。

<img src="https://github.com/XiaoLi332/OsSwitcher/raw/main/assets/00_setup.gif" alt="OsSwitcher" width="80%">

#### 1.2 将生成的内容添加到 `00_heaper` 文件中，并更新 GRUB 的相关配置文件。

<img src="https://github.com/XiaoLi332/OsSwitcher/raw/main/assets/01_add_00heaper.gif" alt="OsSwitcher" width="80%">

然后运行：
   ```bash
   sudo update-grub
```

#### 1.3 （如果不需要在win创建入口可跳过）切换到 Windows 系统，找到 `.grub_shared` 文件夹，基于 `temp.txt` 的内容创建 .bat 入口。

<img src="https://github.com/XiaoLi332/OsSwitcher/raw/main/assets/04_create_win_entry.gif" alt="OsSwitcher" width="80%">

### 2. **Os Switcher使用方法**：
   
   #### Linux系统：
   
   <img src="https://github.com/XiaoLi332/OsSwitcher/raw/main/assets/OsSwitcher_Linux_Usage.gif" alt="OsSwitcher" width="80%">

   #### Win系统：
   
   <img src="https://github.com/XiaoLi332/OsSwitcher/raw/main/assets/OsSwitcher_Win_Usage.gif" alt="OsSwitcher" width="80%">

### 3. **卸载**：

<img src="https://github.com/XiaoLi332/OsSwitcher/raw/main/assets/05_unsetup.gif" alt="OsSwitcher" width="80%">

### 4. **如何关闭 Windows 的快速启动和休眠功能**：

#### 关闭快速启动

1. 打开 **控制面板**。
2. 依次点击 **硬件和声音** > **电源选项**。
3. 选择 **选择电源按钮的功能**。
4. 点击 **更改当前不可用的设置**。
5. 取消勾选 **启用快速启动**，然后保存更改。

#### 关闭休眠功能

1. 打开 **命令提示符**，以管理员身份运行。
2. 输入以下命令并按回车键：
   ```bash
   powercfg /h off

