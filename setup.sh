#!/bin/bash

LOG_FILE="/var/log/grub_script.log"
MOUNT_INFO_FILE="/etc/grub_shared_mount.info"
GRUB_CFG_PATH="/boot/grub/grub.cfg"
GRUB_DEFAULT_PATH="/etc/default/grub"
GRUB_HEADER_FILE="/etc/grub.d/00_header"
GRUB_DIR_NAME=".grub_shared"
BACKUP_DIR="/var/backups/grub"
ROLLBACK_DIR="/var/backups/grub_rollback"
NTFS_DIR_PATH=""

# 检查 ntfs-3g 是否安装
check_ntfs3g() {
  if ! command -v ntfs-3g &> /dev/null; then
    echo "ntfs-3g not installed. Installing it now..." | tee -a $LOG_FILE
    sudo apt update
    sudo apt install -y ntfs-3g
    if [ $? -ne 0 ]; then
      echo "Failed to install ntfs-3g. Aborting." | tee -a $LOG_FILE
      exit 1
    fi
  else
    echo "ntfs-3g is installed." | tee -a $LOG_FILE
  fi
}

# 使用写测试检查挂载点是否可写
check_write_permissions() {
  local mount_point=$1
  local test_file="$mount_point/test_write_permissions"

  sudo touch "$test_file" &>/dev/null
  if [ $? -eq 0 ]; then
    echo "The NTFS partition mounted at $mount_point is writable." | tee -a $LOG_FILE
    sudo rm -f "$test_file" 
    return 0
  else
    echo "The NTFS partition mounted at $mount_point is read-only or lacks write permissions." | tee -a $LOG_FILE
    return 1
  fi
}

# 尝试挂载 NTFS 分区
mount_ntfs_partition() {
  local partition=$1
  local mount_point="/mnt/ntfs_$partition"

  echo "Attempting to mount /dev/$partition at $mount_point using ntfs-3g..." | tee -a $LOG_FILE
  sudo mkdir -p "$mount_point"
  sudo mount -t ntfs-3g /dev/$partition "$mount_point"
  
  if mountpoint -q "$mount_point"; then
    echo "/dev/$partition is mounted at $mount_point." | tee -a $LOG_FILE
    if check_write_permissions "$mount_point"; then
      MOUNT_POINT=$mount_point
      return 0
    else
      sudo umount "$mount_point"
      return 1
    fi
  else
    echo "Failed to mount /dev/$partition." | tee -a $LOG_FILE
    return 1
  fi
}

# 查找并检测可写的 NTFS 分区
find_writable_ntfs_partition() {
  NTFS_PARTITIONS=$(lsblk -rno NAME,FSTYPE | awk '$2 == "ntfs" {print $1}')
  
  if [ -z "$NTFS_PARTITIONS" ]; then
    echo "No NTFS partitions found." | tee -a $LOG_FILE
    exit 1
  fi

  for partition in $NTFS_PARTITIONS; do
    echo "Checking /dev/$partition..." | tee -a $LOG_FILE
    mount_point=$(findmnt -nr -o TARGET /dev/$partition)

    # 检查分区是否已挂载
    if [ -n "$mount_point" ]; then
      echo "/dev/$partition is already mounted at $mount_point." | tee -a $LOG_FILE
      if check_write_permissions "$mount_point"; then
        MOUNT_POINT=$mount_point
        return 0
      fi
    fi
  done

  echo "No writable NTFS partitions found." | tee -a $LOG_FILE
  exit 1
}

# 检查 ntfs-3g 是否已安装
check_ntfs3g

# 查找并检测可写的 NTFS 分区
find_writable_ntfs_partition

# 保存挂载信息到文件
echo "Saving mount information to $MOUNT_INFO_FILE..." | tee -a $LOG_FILE
echo "$MOUNT_POINT" | sudo tee $MOUNT_INFO_FILE > /dev/null

# 获取分区名，用于更具描述性的文件夹名
PARTITION_NAME=$(basename $MOUNT_POINT)

# 创建目标路径和分区名称
NTFS_DIR_PATH="$MOUNT_POINT/.grub_shared"
sudo mkdir -p $NTFS_DIR_PATH/

# 备份重要文件
echo "Backing up important files..." | tee -a $LOG_FILE
sudo cp $GRUB_CFG_PATH $NTFS_DIR_PATH/grub.cfg
sudo cp $GRUB_DEFAULT_PATH $NTFS_DIR_PATH/grub
sudo cp $GRUB_HEADER_FILE $NTFS_DIR_PATH/00_header
echo "Backup completed." | tee -a $LOG_FILE

# 打印复制路径和文件信息
echo "GRUB file copied to: $NTFS_DIR_PATH" | tee -a $LOG_FILE

# 基于grub.cfg文件内容创建txt文本
GRUB_CFG="$NTFS_DIR_PATH/grub.cfg"
if [[ ! -f "$GRUB_CFG" ]]; then
    echo "Error: $GRUB_CFG does not exist."
    exit 1
fi

system_names=()
while IFS= read -r line; do
    if [[ "$line" =~ menuentry\ \'([^\']*)\' ]]; then
        system_name="${BASH_REMATCH[1]}"
        system_names+=("$system_name")
    fi
done < <(grep "menuentry '" "$GRUB_CFG")

if [[ ${#system_names[@]} -eq 0 ]]; then
    echo "No system names found in grub.cfg."
    exit 1
fi

file_name="${NTFS_DIR_PATH}/os0.txt"

for name in "${system_names[@]}"; do
    echo "$name" >> "$file_name"
done


# 生成00_heaper需要添加的内容
INPUT_FILE="${NTFS_DIR_PATH}/os0.txt"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE does not exist."
    exit 1
fi

OUTPUT_FILE="00_heaper_config_content.txt"

# 初始化输出内容
echo "insmod ntfs" > "$OUTPUT_FILE"
echo "insmod part_gpt" >> "$OUTPUT_FILE"
echo "insmod part_msdos" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "for disk_number in 0 1 2 3 4 5 6 7 8 9; do" >> "$OUTPUT_FILE"
echo "    set disk=\"hd\\\${disk_number}\"" >> "$OUTPUT_FILE"
echo "    for parttype in gpt msdos; do" >> "$OUTPUT_FILE"
echo "        for partition in 1 2 3 4 5 6 7 8 9 10 11 12; do" >> "$OUTPUT_FILE"
echo "            set current_partition=\"(\\\$disk,\\\${parttype}\\\${partition})\"" >> "$OUTPUT_FILE"
echo "            if [ -e \"\\\${current_partition}/.grub_shared\" ]; then" >> "$OUTPUT_FILE"

# 读取 txt 文件内容并生成00_heaper补充内容
index=0
while IFS= read -r line; do
    # 生成每个条件判断和设置 default 的内容
    if [[ $index -eq 0 ]]; then
        echo "                if test -e \"\\\${current_partition}/.grub_shared/os${index}.txt\"; then" >> "$OUTPUT_FILE"
    else
        echo "                elif test -e \"\\\${current_partition}/.grub_shared/os${index}.txt\"; then" >> "$OUTPUT_FILE"
    fi
    echo "                    set default=\"$line\"" >> "$OUTPUT_FILE"
    ((index++))
done < "$INPUT_FILE"

# 添加 else 条件和结束内容
echo "                else" >> "$OUTPUT_FILE"
echo "                    echo \"nothing\"" >> "$OUTPUT_FILE"
echo "                fi" >> "$OUTPUT_FILE"
echo "                break 3" >> "$OUTPUT_FILE"
echo "            fi" >> "$OUTPUT_FILE"
echo "        done" >> "$OUTPUT_FILE"
echo "    done" >> "$OUTPUT_FILE"
echo "done" >> "$OUTPUT_FILE"

echo "00_heaper configuration content has been generated and saved to $OUTPUT_FILE."

# 创建win可以直接使用的脚本：
output_file="${NTFS_DIR_PATH}/temp.txt"

# 创建或覆盖文件，并将内容写入
cat > "$output_file" << 'EOF'
@echo off
setlocal enabledelayedexpansion

:: 切换到脚本所在目录
cd /d %~dp0

:: 打印当前操作路径
echo Current working directory: %cd%

:: 查找 osX.txt 文件（X 为 0-9 的数字）
set "INPUT_FILE="
for %%f in (os?.txt) do (
    set "INPUT_FILE=%%f"
)

:: 检查是否找到符合条件的文件
if not defined INPUT_FILE (
    echo Error: No osX.txt file found in the current directory.
    pause
    exit /b 1
)

:: 打印找到的文件名
echo Found input file: !INPUT_FILE!

:: 打印文件内容逐行，并添加行号
echo Below are the available systems you can choose to switch to:

set index=0
for /f "delims=" %%a in (!INPUT_FILE!) do (
    echo !index!: %%a
    set /a index+=1
)

:: 获取用户输入
set /a max_choice=index-1
set /p "choice=Please enter the system number you want to switch to (0-%max_choice%):"

:: 验证用户输入
set /a is_valid=0
for /l %%i in (0,1,%max_choice%) do (
    if !choice! equ %%i set /a is_valid=1
)

if !is_valid! equ 0 (
    echo Invalid choice, please enter a valid number.
    pause
    exit /b 1
)

:: 重命名文件
set "new_filename=os%choice%.txt"
rename "!INPUT_FILE!" "!new_filename!"

echo File has been renamed to !new_filename!.

:: 自动重启
shutdown /r /t 0

EOF


# 提示用户操作完成
echo "All system names have been saved to $file_name."

# 提醒用户保存好这个文件夹名路径
echo "ATTENTION: Please ensure to keep a record of the directory path: $NTFS_DIR_PATH" | tee -a $LOG_FILE

# 打印安装成功的消息
echo "Installation successful! " | tee -a $LOG_FILE






