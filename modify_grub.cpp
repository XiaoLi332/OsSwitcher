#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <sys/stat.h>
#include <unistd.h>
#include <limits>

// 文件路径常量
const std::string grubCfgPath = "/boot/grub/grub.cfg";
const std::string mountInfoFilePath = "/etc/grub_shared_mount.info";  // 挂载信息文件

// 检查文件是否具有写权限
bool checkWritePermission(const std::string& filePath) {
    struct stat buffer;
    if (stat(filePath.c_str(), &buffer) != 0) {
        std::cerr << "File does not exist: " << filePath << std::endl;
        return false;
    }
    return (access(filePath.c_str(), W_OK) == 0);
}

// 获取 GRUB 顶级菜单项
std::vector<std::string> getTopLevelMenuEntries() {
    std::ifstream grubFile(grubCfgPath);
    std::vector<std::string> menuEntries;
    std::string line;
    bool inSubMenu = false;

    if (!grubFile.is_open()) {
        std::cerr << "Failed to open file: " << grubCfgPath << std::endl;
        return menuEntries;
    }

    while (getline(grubFile, line)) {
        if (line.find("submenu") != std::string::npos) {
            size_t start = line.find("'") + 1;
            size_t end = line.find("'", start);
            if (start != std::string::npos && end != std::string::npos) {
                menuEntries.push_back(line.substr(start, end - start));
            }
            inSubMenu = true;
        } else if (line.find("}") != std::string::npos && inSubMenu) {
            inSubMenu = false;
        } else if (line.find("menuentry") != std::string::npos && !inSubMenu) {
            size_t start = line.find("'") + 1;
            size_t end = line.find("'", start);
            if (start != std::string::npos && end != std::string::npos) {
                menuEntries.push_back(line.substr(start, end - start));
            }
        }
    }

    return menuEntries;
}

// 从挂载信息文件中获取共享目录路径
std::string getGrubSharedDir() {
    std::ifstream mountInfoFile(mountInfoFilePath);
    std::string mountPoint;

    if (!mountInfoFile.is_open()) {
        std::cerr << "Failed to open file: " << mountInfoFilePath << std::endl;
        return "";
    }

    getline(mountInfoFile, mountPoint);
    if (mountPoint.empty()) {
        std::cerr << "Mount point information is empty in " << mountInfoFilePath << std::endl;
        return "";
    }

    return mountPoint + "/.grub_shared";
}

// 查找共享目录下的 osX.txt 文件
std::string findOsFile(const std::string& grubSharedDir) {
    for (int i = 0; i <= 9; ++i) {
        std::string filePath = grubSharedDir + "/os" + std::to_string(i) + ".txt";
        std::ifstream file(filePath);
        if (file.is_open()) {
            return filePath;
        }
    }
    return "";
}

// 权限申请函数
bool requestPermissions() {
    std::cout << "Attempting to modify system files. Please enter the appropriate credentials or run with elevated privileges (sudo)." << std::endl;
    if (system("sudo -v") == 0) {
        return true;
    } else {
        std::cerr << "Permission denied. Exiting." << std::endl;
        return false;
    }
}

int main() {
    // 检查权限，必要时请求权限
    if (!requestPermissions()) {
        return 1;
    }

    // 获取共享目录路径
    std::string grubSharedDir = getGrubSharedDir();
    if (grubSharedDir.empty()) {
        return 1;
    }

    // 获取 GRUB 的顶级菜单项
    std::vector<std::string> menuEntries = getTopLevelMenuEntries();

    if (menuEntries.empty()) {
        std::cerr << "No menu entries found in GRUB configuration." << std::endl;
        return 1;
    }

    // 打印可用的 GRUB 菜单项
    std::cout << "Below are the available systems you can choose to switch to::" << std::endl;
    for (size_t i = 0; i < menuEntries.size(); ++i) {
        std::cout << i << ": " << menuEntries[i] << std::endl;
    }

    // 询问用户选择哪个菜单项作为默认值
    int index;
    int attempts = 0;
    const int maxAttempts = 5;

    while (attempts < maxAttempts) {
        std::cout << "Enter the index of the available systems you want to switch to: ";
        std::cin >> index;

        if (std::cin.fail() || index < 0 || index >= static_cast<int>(menuEntries.size())) {
            std::cin.clear();
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            std::cerr << "Invalid entry index. Please enter a valid number." << std::endl;
            ++attempts;
        } else {
            break;
        }
    }

    if (attempts >= maxAttempts) {
        std::cerr << "Too many invalid attempts. Exiting." << std::endl;
        return 1;
    }

    // 查找共享目录下的 osX.txt 文件
    std::string osFilePath = findOsFile(grubSharedDir);
    if (osFilePath.empty()) {
        std::cerr << "No osX.txt file found in the shared directory " + grubSharedDir + "."<< std::endl;
        return 1;
    }
    
    // 重命名 osX.txt 文件为新的选择
    std::string newFilePath = grubSharedDir + "/os" + std::to_string(index) + ".txt";
    if (rename(osFilePath.c_str(), newFilePath.c_str()) != 0) {
        std::cerr << "Failed to rename file: " << osFilePath << " to " << newFilePath << std::endl;
        return 1;
    }

    std::cout << "File renamed successfully to: " << newFilePath << std::endl;
    return 0;
}

