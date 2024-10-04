#!/bin/bash

LOG_FILE="/var/log/grub_script_unsetup.log"
MOUNT_INFO_FILE="/etc/grub_shared_mount.info"
GRUB_CFG_PATH="/boot/grub/grub.cfg"
GRUB_DEFAULT_PATH="/etc/default/grub"
GRUB_HEADER_FILE="/etc/grub.d/00_header"
NTFS_DIR_PATH=""
MOUNT_POINT=""

# 检查挂载信息文件是否存在
if [ ! -f "$MOUNT_INFO_FILE" ]; then
  echo "Mount information file $MOUNT_INFO_FILE does not exist. Aborting." | tee -a $LOG_FILE
  exit 1
fi

# 读取挂载点信息
MOUNT_POINT=$(cat $MOUNT_INFO_FILE)
if [ -z "$MOUNT_POINT" ]; then
  echo "Mount point information is empty in $MOUNT_INFO_FILE. Aborting." | tee -a $LOG_FILE
  exit 1
fi

# 删除挂载信息文件
echo "Removing mount information file $MOUNT_INFO_FILE..." | tee -a $LOG_FILE
sudo rm -f "$MOUNT_INFO_FILE"

# 获取 NTFS 分区路径
NTFS_DIR_PATH="$MOUNT_POINT/.grub_shared"
if [ ! -d "$NTFS_DIR_PATH" ]; then
  echo "Directory $NTFS_DIR_PATH does not exist. Aborting." | tee -a $LOG_FILE
  exit 1
fi

# 恢复备份文件到原位置
echo "Restoring backup files from $NTFS_DIR_PATH..." | tee -a $LOG_FILE

if [ -f "$NTFS_DIR_PATH/grub.cfg" ]; then
  sudo cp "$NTFS_DIR_PATH/grub.cfg" $GRUB_CFG_PATH
  echo "Restored grub.cfg to $GRUB_CFG_PATH" | tee -a $LOG_FILE
fi

if [ -f "$NTFS_DIR_PATH/grub" ]; then
  sudo cp "$NTFS_DIR_PATH/grub" $GRUB_DEFAULT_PATH
  echo "Restored grub to $GRUB_DEFAULT_PATH" | tee -a $LOG_FILE
fi

if [ -f "$NTFS_DIR_PATH/00_header" ]; then
  sudo cp "$NTFS_DIR_PATH/00_header" $GRUB_HEADER_FILE
  echo "Restored 00_header to $GRUB_HEADER_FILE" | tee -a $LOG_FILE
fi

echo "Backup files restored." | tee -a $LOG_FILE

# 删除备份文件
echo "Deleting backup files from $NTFS_DIR_PATH..." | tee -a $LOG_FILE
sudo rm -f "$NTFS_DIR_PATH/grub.cfg"
sudo rm -f "$NTFS_DIR_PATH/grub"
sudo rm -f "$NTFS_DIR_PATH/00_header"
sudo rm -f "00_heaper_config_content.txt"
echo "Backup files deleted." | tee -a $LOG_FILE

# 删除 Windows 脚本和系统名称文本文件
echo "Deleting OsSwitcher.bat and system name text files..." | tee -a $LOG_FILE
sudo rm -f "$NTFS_DIR_PATH/OsSwitcher.bat"
sudo rm -f "$NTFS_DIR_PATH/os*.txt"
echo "Windows script and system name files deleted." | tee -a $LOG_FILE

# 删除 GRUB 共享目录
echo "Removing GRUB shared directory $NTFS_DIR_PATH..." | tee -a $LOG_FILE
sudo rm -rf "$NTFS_DIR_PATH"
echo "GRUB shared directory removed." | tee -a $LOG_FILE

# 提示用户操作完成
echo "Uninstallation and cleanup complete." | tee -a $LOG_FILE

