#!/usr/bin/env bash
#主启动脚本 - 自动管理虚拟内存并提供脚本选择

# 颜色定义
Green="\033[32m"
Font="\033[0m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[34m"

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}错误：此脚本必须以 root 权限运行！${Font}"
        exit 1
    fi
}

# 检查OpenVZ
check_ovz() {
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}错误：您的VPS基于OpenVZ，不支持创建swap！${Font}"
        exit 1
    fi
}

# 获取内存大小（MB）
get_memory_size() {
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_mb=$((mem_kb / 1024))
    echo $mem_mb
}

# 自动创建swap
auto_create_swap() {
    echo -e "${Blue}正在检查系统内存和swap状态...${Font}"
    
    local memory_mb=$(get_memory_size)
    echo -e "${Green}当前系统内存：${memory_mb}MB${Font}"
    
    # 检查是否已存在swap
    if grep -q "swapfile" /etc/fstab; then
        echo -e "${Yellow}检测到已存在swap文件，跳过创建。${Font}"
        return 0
    fi
    
    # 根据内存大小决定推荐的swap大小
    local recommended_swap_size
    if [[ $memory_mb -lt 1024 ]]; then
        recommended_swap_size=2048  # 2GB
        echo -e "${Yellow}建议：内存小于1GB，推荐创建2GB的swap${Font}"
    else
        recommended_swap_size=1024  # 1GB
        echo -e "${Yellow}建议：内存大于等于1GB，推荐创建1GB的swap${Font}"
    fi
    
    echo
    echo -e "${Green}Swap创建选项：${Font}"
    echo -e "${Yellow}1.${Font} 自动创建推荐大小的swap (${recommended_swap_size}MB)"
    echo -e "${Yellow}2.${Font} 手动指定swap大小"
    echo -e "${Yellow}3.${Font} 跳过swap创建"
    echo
    
    local choice
    while true; do
        read -p "请选择 [1-3]: " choice
        case $choice in
            1)
                # 自动创建推荐大小
                create_swap_file $recommended_swap_size
                break
                ;;
            2)
                # 手动指定大小
                manual_create_swap
                break
                ;;
            3)
                echo -e "${Yellow}跳过swap创建。${Font}"
                return 0
                ;;
            *)
                echo -e "${Red}无效选择，请输入 1-3${Font}"
                ;;
        esac
    done
}

# 手动创建swap
manual_create_swap() {
    local swap_size
    while true; do
        echo -e "${Green}请输入需要创建的swap大小（单位：MB，建议为内存的1-2倍）：${Font}"
        read -p "请输入swap大小: " swap_size
        
        # 验证输入是否为数字
        if [[ $swap_size =~ ^[0-9]+$ ]] && [[ $swap_size -gt 0 ]]; then
            echo -e "${Green}将创建${swap_size}MB的swap文件${Font}"
            read -p "确认创建吗？[y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                create_swap_file $swap_size
                break
            fi
        else
            echo -e "${Red}请输入有效的数字（大于0）${Font}"
        fi
    done
}

# 创建swap文件的通用函数
create_swap_file() {
    local swap_size=$1
    echo -e "${Green}正在创建${swap_size}MB的swap文件...${Font}"
    
    # 创建swap文件
    if fallocate -l ${swap_size}M /swapfile; then
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
        echo -e "${Green}Swap创建成功！${Font}"
        echo -e "${Green}Swap信息：${Font}"
        cat /proc/swaps
        echo
    else
        echo -e "${Red}Swap创建失败！${Font}"
        exit 1
    fi
}

# 显示脚本选择菜单
show_script_menu() {
    clear
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}      Hysteria 2 脚本管理工具${Font}"
    echo -e "${Blue}============================================${Font}"
    echo
    echo -e "${Green}请选择要运行的脚本：${Font}"
    echo
    echo -e "${Yellow}1.${Font} V2Ray 一键安装脚本"
    echo -e "${Yellow}2.${Font} 完整安装脚本 (install.sh)"
    echo -e "${Yellow}3.${Font} Swap 管理脚本"
    echo -e "${Yellow}4.${Font} 更新 main.sh 脚本"
    echo -e "${Yellow}5.${Font} 退出"
    echo
    echo -e "${Blue}============================================${Font}"
}

# 执行选择的脚本
execute_script() {
    local choice=$1
    local base_url="https://raw.githubusercontent.com/charleslkx/hy2/master"
    
    case $choice in
        1)
            echo -e "${Green}正在启动 V2Ray 安装脚本...${Font}"
            echo -e "${Yellow}正在从远程仓库获取 v2ray.sh...${Font}"
            if bash <(wget -qO- "${base_url}/v2ray.sh" 2>/dev/null || curl -fsSL "${base_url}/v2ray.sh" 2>/dev/null); then
                echo -e "${Green}脚本执行完成${Font}"
                # 添加定时重启任务
                add_crontab_reboot
            else
                echo -e "${Red}错误：无法从远程仓库获取 v2ray.sh 脚本！${Font}"
                echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
            fi
            ;;
        2)
            echo -e "${Green}正在启动完整安装脚本...${Font}"
            echo -e "${Yellow}正在从远程仓库获取 install.sh...${Font}"
            if bash <(wget -qO- "${base_url}/install.sh" 2>/dev/null || curl -fsSL "${base_url}/install.sh" 2>/dev/null); then
                echo -e "${Green}脚本执行完成${Font}"
            else
                echo -e "${Red}错误：无法从远程仓库获取 install.sh 脚本！${Font}"
                echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
            fi
            ;;
        3)
            echo -e "${Green}正在启动 Swap 管理脚本...${Font}"
            echo -e "${Yellow}正在从远程仓库获取 swap.sh...${Font}"
            if bash <(wget -qO- "${base_url}/swap.sh" 2>/dev/null || curl -fsSL "${base_url}/swap.sh" 2>/dev/null); then
                echo -e "${Green}脚本执行完成${Font}"
            else
                echo -e "${Red}错误：无法从远程仓库获取 swap.sh 脚本！${Font}"
                echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
            fi
            ;;
        4)
            echo -e "${Green}正在更新 main.sh 脚本...${Font}"
            update_main_script
            ;;
        5)
            echo -e "${Green}感谢使用，再见！${Font}"
            exit 0
            ;;
        *)
            echo -e "${Red}无效选择，请输入 1-5${Font}"
            sleep 2
            main_menu
            ;;
    esac
}

# 添加定时重启任务
add_crontab_reboot() {
    echo -e "${Blue}正在配置系统定时重启任务...${Font}"
    
    # 检查是否已存在重启任务
    if crontab -l 2>/dev/null | grep -q "0 5 \* \* \* /sbin/reboot"; then
        echo -e "${Yellow}检测到已存在定时重启任务，跳过添加。${Font}"
        return 0
    fi
    
    # 备份当前的crontab
    crontab -l 2>/dev/null > /tmp/current_crontab || touch /tmp/current_crontab
    
    # 添加新的重启任务
    echo "0 5 * * * /sbin/reboot" >> /tmp/current_crontab
    
    # 应用新的crontab
    if crontab /tmp/current_crontab; then
        echo -e "${Green}定时重启任务添加成功！${Font}"
        echo -e "${Green}系统将在每日凌晨5:00自动重启${Font}"
        rm -f /tmp/current_crontab
    else
        echo -e "${Red}定时重启任务添加失败！${Font}"
        rm -f /tmp/current_crontab
    fi
    
    echo -e "${Blue}当前定时任务：${Font}"
    crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" || echo -e "${Yellow}暂无定时任务${Font}"
    echo
}

# 主菜单
main_menu() {
    while true; do
        show_script_menu
        read -p "请输入您的选择 [1-5]: " choice
        execute_script "$choice"
        echo
        read -p "脚本执行完毕，按回车键返回主菜单..."
    done
}

# 初始化函数
initialize() {
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}      Hysteria 2 环境初始化${Font}"
    echo -e "${Blue}============================================${Font}"
    echo
    
    # 检查权限和环境
    check_root
    check_ovz
    
    # 自动创建swap
    auto_create_swap
    
    echo -e "${Green}环境初始化完成！${Font}"
    sleep 2
}

# 主函数
main() {
    # 初始化环境
    initialize
    
    # 进入主菜单
    main_menu
}

# 更新 main.sh 脚本
update_main_script() {
    echo -e "${Blue}正在检查 main.sh 脚本更新...${Font}"
    
    local base_url="https://raw.githubusercontent.com/charleslkx/hy2/master"
    local script_path="$0"
    local backup_path="${script_path}.backup.$(date +%Y%m%d_%H%M%S)"
    local temp_script="/tmp/main_new.sh"
    
    # 获取当前脚本版本信息
    echo -e "${Green}当前脚本路径：${script_path}${Font}"
    echo
    
    # 显示更新选项
    echo -e "${Green}更新选项：${Font}"
    echo -e "${Yellow}1.${Font} 检查并更新到最新版本"
    echo -e "${Yellow}2.${Font} 强制重新下载脚本"
    echo -e "${Yellow}3.${Font} 查看当前版本信息"
    echo -e "${Yellow}4.${Font} 返回主菜单"
    echo
    
    local choice
    while true; do
        read -p "请选择更新选项 [1-4]: " choice
        case $choice in
            1)
                check_and_update
                break
                ;;
            2)
                force_update
                break
                ;;
            3)
                show_version_info
                break
                ;;
            4)
                echo -e "${Yellow}返回主菜单${Font}"
                return 0
                ;;
            *)
                echo -e "${Red}无效选择，请输入 1-4${Font}"
                ;;
        esac
    done
}

# 检查并更新脚本
check_and_update() {
    echo -e "${Blue}正在检查远程版本...${Font}"
    
    local base_url="https://raw.githubusercontent.com/charleslkx/hy2/master"
    local script_path="$0"
    local backup_path="${script_path}.backup.$(date +%Y%m%d_%H%M%S)"
    local temp_script="/tmp/main_new.sh"
    
    # 下载最新版本
    if wget -qO "$temp_script" "${base_url}/main.sh" 2>/dev/null || curl -fsSL "${base_url}/main.sh" -o "$temp_script" 2>/dev/null; then
        echo -e "${Green}最新版本下载成功${Font}"
        
        # 比较文件
        if ! diff -q "$script_path" "$temp_script" >/dev/null 2>&1; then
            echo -e "${Yellow}检测到新版本，准备更新...${Font}"
            perform_update "$script_path" "$backup_path" "$temp_script"
        else
            echo -e "${Green}当前已是最新版本，无需更新${Font}"
            rm -f "$temp_script"
        fi
    else
        echo -e "${Red}无法下载最新版本，请检查网络连接${Font}"
    fi
}

# 强制更新脚本
force_update() {
    echo -e "${Yellow}正在强制更新脚本...${Font}"
    
    local base_url="https://raw.githubusercontent.com/charleslkx/hy2/master"
    local script_path="$0"
    local backup_path="${script_path}.backup.$(date +%Y%m%d_%H%M%S)"
    local temp_script="/tmp/main_new.sh"
    
    # 下载最新版本
    if wget -qO "$temp_script" "${base_url}/main.sh" 2>/dev/null || curl -fsSL "${base_url}/main.sh" -o "$temp_script" 2>/dev/null; then
        echo -e "${Green}最新版本下载成功${Font}"
        perform_update "$script_path" "$backup_path" "$temp_script"
    else
        echo -e "${Red}无法下载最新版本，请检查网络连接${Font}"
    fi
}

# 执行更新操作
perform_update() {
    local script_path="$1"
    local backup_path="$2"
    local temp_script="$3"
    
    echo -e "${Blue}正在备份当前脚本...${Font}"
    
    # 备份当前脚本
    if cp "$script_path" "$backup_path"; then
        echo -e "${Green}备份完成：${backup_path}${Font}"
    else
        echo -e "${Red}备份失败，更新中止${Font}"
        rm -f "$temp_script"
        return 1
    fi
    
    # 更新脚本
    echo -e "${Blue}正在更新脚本...${Font}"
    if cp "$temp_script" "$script_path" && chmod +x "$script_path"; then
        echo -e "${Green}脚本更新成功！${Font}"
        echo -e "${Green}备份文件保存在：${backup_path}${Font}"
        rm -f "$temp_script"
        
        echo -e "${Yellow}更新完成，建议重新启动脚本以使用新版本${Font}"
        echo -e "${Blue}是否现在重新启动脚本？[y/N]:${Font}"
        read -p "" restart_choice
        if [[ $restart_choice =~ ^[Yy]$ ]]; then
            echo -e "${Green}正在重新启动脚本...${Font}"
            exec "$script_path"
        fi
    else
        echo -e "${Red}脚本更新失败，正在恢复备份...${Font}"
        cp "$backup_path" "$script_path"
        echo -e "${Yellow}已恢复到原版本${Font}"
        rm -f "$temp_script"
    fi
}

# 显示版本信息
show_version_info() {
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}       main.sh 脚本信息${Font}"
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}脚本名称：${Font}Hysteria 2 统一管理脚本"
    echo -e "${Green}脚本路径：${Font}$0"
    echo -e "${Green}修改时间：${Font}$(stat -c %y "$0" 2>/dev/null || echo "未知")"
    echo -e "${Green}文件大小：${Font}$(stat -c %s "$0" 2>/dev/null || echo "未知") 字节"
    echo -e "${Green}GitHub仓库：${Font}https://github.com/charleslkx/hy2"
    echo
    echo -e "${Green}功能特性：${Font}"
    echo -e "  • 智能 Swap 内存管理"
    echo -e "  • 远程脚本获取执行"  
    echo -e "  • V2Ray 定时重启配置"
    echo -e "  • 脚本自动更新功能"
    echo -e "${Blue}============================================${Font}"
    echo
}

# 启动脚本
main "$@"
