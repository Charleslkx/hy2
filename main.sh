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
    echo -e "${Yellow}4.${Font} 退出"
    echo
    echo -e "${Blue}============================================${Font}"
}

# 执行选择的脚本
execute_script() {
    local choice=$1
    local script_dir=$(dirname "$0")
    local base_url="https://raw.githubusercontent.com/charleslkx/hy2/master"
    
    case $choice in
        1)
            echo -e "${Green}正在启动 V2Ray 安装脚本...${Font}"
            if [[ -f "${script_dir}/v2ray.sh" ]]; then
                echo -e "${Blue}使用本地文件: v2ray.sh${Font}"
                bash "${script_dir}/v2ray.sh"
            else
                echo -e "${Yellow}本地文件不存在，正在从远程仓库获取 v2ray.sh...${Font}"
                if bash <(wget -qO- "${base_url}/v2ray.sh" 2>/dev/null || curl -fsSL "${base_url}/v2ray.sh" 2>/dev/null); then
                    echo -e "${Green}脚本执行完成${Font}"
                else
                    echo -e "${Red}错误：无法从远程仓库获取 v2ray.sh 脚本！${Font}"
                    echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
                fi
            fi
            ;;
        2)
            echo -e "${Green}正在启动完整安装脚本...${Font}"
            if [[ -f "${script_dir}/install.sh" ]]; then
                echo -e "${Blue}使用本地文件: install.sh${Font}"
                bash "${script_dir}/install.sh"
            else
                echo -e "${Yellow}本地文件不存在，正在从远程仓库获取 install.sh...${Font}"
                if bash <(wget -qO- "${base_url}/install.sh" 2>/dev/null || curl -fsSL "${base_url}/install.sh" 2>/dev/null); then
                    echo -e "${Green}脚本执行完成${Font}"
                else
                    echo -e "${Red}错误：无法从远程仓库获取 install.sh 脚本！${Font}"
                    echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
                fi
            fi
            ;;
        3)
            echo -e "${Green}正在启动 Swap 管理脚本...${Font}"
            if [[ -f "${script_dir}/swap.sh" ]]; then
                echo -e "${Blue}使用本地文件: swap.sh${Font}"
                bash "${script_dir}/swap.sh"
            else
                echo -e "${Yellow}本地文件不存在，正在从远程仓库获取 swap.sh...${Font}"
                if bash <(wget -qO- "${base_url}/swap.sh" 2>/dev/null || curl -fsSL "${base_url}/swap.sh" 2>/dev/null); then
                    echo -e "${Green}脚本执行完成${Font}"
                else
                    echo -e "${Red}错误：无法从远程仓库获取 swap.sh 脚本！${Font}"
                    echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
                fi
            fi
            ;;
        4)
            echo -e "${Green}感谢使用，再见！${Font}"
            exit 0
            ;;
        *)
            echo -e "${Red}无效选择，请输入 1-4${Font}"
            sleep 2
            main_menu
            ;;
    esac
}

# 主菜单
main_menu() {
    while true; do
        show_script_menu
        read -p "请输入您的选择 [1-4]: " choice
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

# 启动脚本
main "$@"
