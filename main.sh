#!/usr/bin/env bash
#主启动脚本 - 自动管理虚拟内存并提供脚本选择

# 颜色定义
Green="\033[32m"
Font="\033[0m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[34m"

# 安装简易命令
install_quick_command() {
    echo -e "${Blue}正在安装简易命令...${Font}"
    
    local script_path="$(readlink -f "$0")"
    local command_name="hy2"
    local vasmaType=false
    
    # 显示当前环境信息
    echo -e "${Green}当前脚本路径：${script_path}${Font}"
    echo -e "${Green}当前用户：$(whoami)${Font}"
    echo
    
    # 尝试在 /usr/bin 中创建符号链接
    if [[ -d "/usr/bin/" ]]; then
        local bin_path="/usr/bin/${command_name}"
        echo -e "${Green}目标安装路径：${bin_path}${Font}"
        
        if [[ ! -f "$bin_path" ]]; then
            if ln -s "$script_path" "$bin_path" 2>/dev/null; then
                chmod 700 "$bin_path"
                vasmaType=true
                echo -e "${Green}在 /usr/bin 中创建快捷方式成功${Font}"
            else
                echo -e "${Yellow}在 /usr/bin 中创建快捷方式失败${Font}"
            fi
        else
            echo -e "${Yellow}检测到 ${bin_path} 已存在${Font}"
            echo -e "${Yellow}是否要重新安装？[y/N]:${Font}"
            read -p "" reinstall_choice
            if [[ $reinstall_choice =~ ^[Yy]$ ]]; then
                rm -f "$bin_path"
                if ln -s "$script_path" "$bin_path" 2>/dev/null; then
                    chmod 700 "$bin_path"
                    vasmaType=true
                    echo -e "${Green}重新安装快捷方式成功${Font}"
                fi
            fi
        fi
    fi
    
    # 如果 /usr/bin 失败，尝试 /usr/sbin
    if [[ "$vasmaType" == "false" && -d "/usr/sbin/" ]]; then
        local sbin_path="/usr/sbin/${command_name}"
        echo -e "${Green}尝试在 /usr/sbin 中安装：${sbin_path}${Font}"
        
        if [[ ! -f "$sbin_path" ]]; then
            if ln -s "$script_path" "$sbin_path" 2>/dev/null; then
                chmod 700 "$sbin_path"
                vasmaType=true
                echo -e "${Green}在 /usr/sbin 中创建快捷方式成功${Font}"
            else
                echo -e "${Yellow}在 /usr/sbin 中创建快捷方式失败${Font}"
            fi
        fi
    fi
    
    # 如果以上都失败，尝试 /usr/local/bin
    if [[ "$vasmaType" == "false" ]]; then
        local local_bin_path="/usr/local/bin/${command_name}"
        echo -e "${Green}尝试在 /usr/local/bin 中安装：${local_bin_path}${Font}"
        
        # 确保目录存在
        if [[ ! -d "/usr/local/bin" ]]; then
            echo -e "${Yellow}/usr/local/bin 目录不存在，正在创建...${Font}"
            mkdir -p /usr/local/bin
        fi
        
        if [[ ! -f "$local_bin_path" ]]; then
            if ln -s "$script_path" "$local_bin_path" 2>/dev/null; then
                chmod 700 "$local_bin_path"
                vasmaType=true
                echo -e "${Green}在 /usr/local/bin 中创建快捷方式成功${Font}"
            else
                echo -e "${Red}在 /usr/local/bin 中创建快捷方式失败${Font}"
            fi
        fi
    fi
    
    # 显示安装结果
    if [[ "$vasmaType" == "true" ]]; then
        echo
        echo -e "${Green}快捷方式创建成功，可执行[${command_name}]重新打开脚本${Font}"
        echo -e "${Yellow}使用方法：${Font}"
        echo -e "${Blue}  ${command_name}${Font}                # 启动脚本"
        echo -e "${Blue}  sudo ${command_name}${Font}           # 以root权限启动脚本"
        echo -e "${Blue}  ${command_name} --help${Font}         # 查看帮助信息"
        echo -e "${Blue}  ${command_name} --version${Font}      # 查看版本信息"
        echo
        echo -e "${Yellow}如果命令不被识别，请：${Font}"
        echo -e "${Yellow}1. 打开新的终端会话${Font}"
        echo -e "${Yellow}2. 检查 PATH：echo \$PATH${Font}"
        echo -e "${Yellow}3. 手动添加路径到 PATH 环境变量${Font}"
    else
        echo -e "${Red}快捷方式创建失败！${Font}"
        echo -e "${Yellow}请检查权限或手动创建符号链接${Font}"
        echo -e "${Yellow}手动命令：sudo ln -s ${script_path} /usr/local/bin/${command_name}${Font}"
    fi
}

# 卸载简易命令
uninstall_quick_command() {
    local command_name="hy2"
    local removed=false
    
    echo -e "${Yellow}正在卸载简易命令...${Font}"
    
    # 检查并删除 /usr/bin 中的命令
    if [[ -f "/usr/bin/${command_name}" ]]; then
        if rm -f "/usr/bin/${command_name}"; then
            echo -e "${Green}已从 /usr/bin 中移除 '${command_name}'${Font}"
            removed=true
        else
            echo -e "${Red}从 /usr/bin 中移除 '${command_name}' 失败${Font}"
        fi
    fi
    
    # 检查并删除 /usr/sbin 中的命令
    if [[ -f "/usr/sbin/${command_name}" ]]; then
        if rm -f "/usr/sbin/${command_name}"; then
            echo -e "${Green}已从 /usr/sbin 中移除 '${command_name}'${Font}"
            removed=true
        else
            echo -e "${Red}从 /usr/sbin 中移除 '${command_name}' 失败${Font}"
        fi
    fi
    
    # 检查并删除 /usr/local/bin 中的命令
    if [[ -f "/usr/local/bin/${command_name}" ]]; then
        if rm -f "/usr/local/bin/${command_name}"; then
            echo -e "${Green}已从 /usr/local/bin 中移除 '${command_name}'${Font}"
            removed=true
        else
            echo -e "${Red}从 /usr/local/bin 中移除 '${command_name}' 失败${Font}"
        fi
    fi
    
    if [[ "$removed" == "true" ]]; then
        echo -e "${Green}简易命令 '${command_name}' 卸载成功！${Font}"
    else
        echo -e "${Yellow}简易命令 '${command_name}' 未安装或已被移除${Font}"
    fi
}

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
    echo -e "${Yellow}1.${Font} V2Ray 安装脚本"
    echo -e "${Yellow}2.${Font} hysteria2 安装脚本 "
    echo -e "${Yellow}3.${Font} Swap 管理脚本"
    echo -e "${Yellow}4.${Font} 更新 main.sh 脚本"
    echo -e "${Yellow}5.${Font} 命令管理"
    echo -e "${Yellow}6.${Font} 退出"
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
            
            # 先尝试下载脚本到临时文件
            local temp_script="/tmp/v2ray_temp.sh"
            local download_success=false
            
            if wget -qO "$temp_script" "${base_url}/v2ray.sh" 2>/dev/null; then
                download_success=true
                echo -e "${Green}使用 wget 下载成功${Font}"
            elif curl -fsSL "${base_url}/v2ray.sh" -o "$temp_script" 2>/dev/null; then
                download_success=true
                echo -e "${Green}使用 curl 下载成功${Font}"
            fi
            
            if [[ "$download_success" == "true" && -s "$temp_script" ]]; then
                echo -e "${Green}开始执行 V2Ray 安装脚本...${Font}"
                # 执行脚本，不管退出状态码
                bash "$temp_script"
                echo -e "${Green}V2Ray 脚本执行完成${Font}"
                rm -f "$temp_script"
                # 添加定时重启任务
                add_crontab_reboot
            else
                echo -e "${Red}错误：无法从远程仓库获取 v2ray.sh 脚本！${Font}"
                echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
                rm -f "$temp_script"
            fi
            ;;
        2)
            echo -e "${Green}正在启动 Hysteria2 安装脚本...${Font}"
            echo -e "${Yellow}正在从远程仓库获取 hy2.sh...${Font}"
            
            # 先尝试下载脚本到临时文件
            local temp_script="/tmp/hy2_temp.sh"
            local download_success=false
            
            if wget -qO "$temp_script" "${base_url}/hy2.sh" 2>/dev/null; then
                download_success=true
                echo -e "${Green}使用 wget 下载成功${Font}"
            elif curl -fsSL "${base_url}/hy2.sh" -o "$temp_script" 2>/dev/null; then
                download_success=true
                echo -e "${Green}使用 curl 下载成功${Font}"
            fi
            
            if [[ "$download_success" == "true" && -s "$temp_script" ]]; then
                echo -e "${Green}开始执行 Hysteria2 安装脚本...${Font}"
                # 执行脚本，不管退出状态码
                bash "$temp_script"
                echo -e "${Green}Hysteria2 脚本执行完成${Font}"
                rm -f "$temp_script"
            else
                echo -e "${Red}错误：无法从远程仓库获取 hy2.sh 脚本！${Font}"
                echo -e "${Yellow}请检查网络连接或稍后重试${Font}"
                rm -f "$temp_script"
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
            echo -e "${Green}进入命令管理...${Font}"
            command_management
            ;;
        6)
            echo -e "${Green}感谢使用，再见！${Font}"
            exit 0
            ;;
        *)
            echo -e "${Red}无效选择，请输入 1-6${Font}"
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
        read -p "请输入您的选择 [1-6]: " choice
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
    # 处理命令行参数
    case "${1:-}" in
        "--install-command")
            check_root
            install_quick_command
            exit 0
            ;;
        "--uninstall-command")
            check_root
            uninstall_quick_command
            exit 0
            ;;
        "--help"|"-h")
            show_help
            exit 0
            ;;
        "--version"|"-v")
            show_version_info
            exit 0
            ;;
    esac
    
    # 初始化环境
    initialize
    
    # 进入主菜单
    main_menu
}

# 显示帮助信息
show_help() {
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}      Hysteria 2 脚本帮助信息${Font}"
    echo -e "${Blue}============================================${Font}"
    echo
    echo -e "${Green}用法：${Font}"
    echo -e "  $(basename "$0") [选项]"
    echo
    echo -e "${Green}选项：${Font}"
    echo -e "  ${Yellow}--help, -h${Font}              显示此帮助信息"
    echo -e "  ${Yellow}--version, -v${Font}           显示版本信息"
    echo -e "  ${Yellow}--install-command${Font}       安装简易命令 (hy2)"
    echo -e "  ${Yellow}--uninstall-command${Font}     卸载简易命令"
    echo
    echo -e "${Green}简易命令：${Font}"
    echo -e "  安装后可通过 '${Yellow}hy2${Font}' 命令启动脚本"
    echo -e "  使用方法：${Yellow}sudo hy2${Font}"
    echo
    echo -e "${Green}功能特性：${Font}"
    echo -e "  • 智能 Swap 内存管理"
    echo -e "  • 远程脚本获取执行"
    echo -e "  • V2Ray 定时重启配置"
    echo -e "  • 脚本自动更新功能"
    echo -e "  • 简易命令安装管理"
    echo
    echo -e "${Green}GitHub仓库：${Font}https://github.com/charleslkx/hy2"
    echo -e "${Blue}============================================${Font}"
}

# 更新 main.sh 脚本
update_main_script() {
    echo -e "${Blue}正在检查 main.sh 脚本更新...${Font}"
    
    local base_url="https://raw.githubusercontent.com/charleslkx/hy2/master"
    local script_path="$0"
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
    local temp_script="/tmp/main_new.sh"
    
    # 下载最新版本
    if wget -qO "$temp_script" "${base_url}/main.sh" 2>/dev/null || curl -fsSL "${base_url}/main.sh" -o "$temp_script" 2>/dev/null; then
        echo -e "${Green}最新版本下载成功${Font}"
        
        # 比较文件
        if ! diff -q "$script_path" "$temp_script" >/dev/null 2>&1; then
            echo -e "${Yellow}检测到新版本，准备更新...${Font}"
            perform_update "$script_path" "$temp_script"
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
    local temp_script="/tmp/main_new.sh"
    
    # 下载最新版本
    if wget -qO "$temp_script" "${base_url}/main.sh" 2>/dev/null || curl -fsSL "${base_url}/main.sh" -o "$temp_script" 2>/dev/null; then
        echo -e "${Green}最新版本下载成功${Font}"
        perform_update "$script_path" "$temp_script"
    else
        echo -e "${Red}无法下载最新版本，请检查网络连接${Font}"
    fi
}

# 执行更新操作
perform_update() {
    local script_path="$1"
    local temp_script="$2"
    
    # 直接更新脚本
    echo -e "${Blue}正在更新脚本...${Font}"
    if cp "$temp_script" "$script_path" && chmod +x "$script_path"; then
        echo -e "${Green}脚本更新成功！${Font}"
        rm -f "$temp_script"
        
        echo -e "${Yellow}更新完成，建议重新启动脚本以使用新版本${Font}"
        echo -e "${Blue}是否现在重新启动脚本？[y/N]:${Font}"
        read -p "" restart_choice
        if [[ $restart_choice =~ ^[Yy]$ ]]; then
            echo -e "${Green}正在重新启动脚本...${Font}"
            exec "$script_path"
        fi
    else
        echo -e "${Red}脚本更新失败！${Font}"
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
    echo -e "  • 简易命令安装管理"
    echo -e "${Blue}============================================${Font}"
    echo
}

# 命令管理菜单
command_management() {
    clear
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}           命令管理${Font}"
    echo -e "${Blue}============================================${Font}"
    echo
    
    local command_name="hy2"
    local found=false
    
    # 检查命令状态
    echo -e "${Green}简易命令状态检查：${Font}"
    
    if [[ -f "/usr/bin/${command_name}" ]]; then
        echo -e "${Green}  /usr/bin/${command_name} ✓${Font}"
        found=true
    fi
    
    if [[ -f "/usr/sbin/${command_name}" ]]; then
        echo -e "${Green}  /usr/sbin/${command_name} ✓${Font}"
        found=true
    fi
    
    if [[ -f "/usr/local/bin/${command_name}" ]]; then
        echo -e "${Green}  /usr/local/bin/${command_name} ✓${Font}"
        found=true
    fi
    
    if [[ "$found" == "true" ]]; then
        echo -e "${Green}总体状态：${Font}已安装"
        echo -e "${Green}使用方法：${Font}${command_name} 或 sudo ${command_name}"
    else
        echo -e "${Yellow}总体状态：${Font}未安装"
    fi
    
    echo
    echo -e "${Green}命令管理选项：${Font}"
    echo -e "${Yellow}1.${Font} 安装简易命令 (${command_name})"
    echo -e "${Yellow}2.${Font} 卸载简易命令"
    echo -e "${Yellow}3.${Font} 查看详细状态"
    echo -e "${Yellow}4.${Font} 返回主菜单"
    echo
    echo -e "${Blue}============================================${Font}"
    
    local choice
    while true; do
        read -p "请选择操作 [1-4]: " choice
        case $choice in
            1)
                install_quick_command
                break
                ;;
            2)
                uninstall_quick_command
                break
                ;;
            3)
                show_command_status
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

# 显示命令状态
show_command_status() {
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}         简易命令状态信息${Font}"
    echo -e "${Blue}============================================${Font}"
    
    local command_name="hy2"
    local script_path="$(readlink -f "$0")"
    local found=false
    
    echo -e "${Green}当前脚本路径：${Font}${script_path}"
    echo -e "${Green}简易命令名称：${Font}${command_name}"
    echo
    
    # 检查各个位置的命令
    echo -e "${Green}命令安装状态：${Font}"
    
    if [[ -f "/usr/bin/${command_name}" ]]; then
        echo -e "${Green}  /usr/bin/${command_name} ✓${Font}"
        echo -e "${Green}  链接目标：$(readlink "/usr/bin/${command_name}" 2>/dev/null || echo "无法读取")${Font}"
        found=true
    else
        echo -e "${Yellow}  /usr/bin/${command_name} ✗${Font}"
    fi
    
    if [[ -f "/usr/sbin/${command_name}" ]]; then
        echo -e "${Green}  /usr/sbin/${command_name} ✓${Font}"
        echo -e "${Green}  链接目标：$(readlink "/usr/sbin/${command_name}" 2>/dev/null || echo "无法读取")${Font}"
        found=true
    else
        echo -e "${Yellow}  /usr/sbin/${command_name} ✗${Font}"
    fi
    
    if [[ -f "/usr/local/bin/${command_name}" ]]; then
        echo -e "${Green}  /usr/local/bin/${command_name} ✓${Font}"
        echo -e "${Green}  链接目标：$(readlink "/usr/local/bin/${command_name}" 2>/dev/null || echo "无法读取")${Font}"
        found=true
    else
        echo -e "${Yellow}  /usr/local/bin/${command_name} ✗${Font}"
    fi
    
    echo
    if [[ "$found" == "true" ]]; then
        echo -e "${Green}总体状态：${Font}已安装 ✓"
        echo
        echo -e "${Green}使用方法：${Font}"
        echo -e "  ${Blue}${command_name}${Font}                # 启动脚本"
        echo -e "  ${Blue}sudo ${command_name}${Font}           # 以root权限启动脚本"
        echo -e "  ${Blue}${command_name} --help${Font}         # 查看帮助信息"
        echo -e "  ${Blue}${command_name} --version${Font}      # 查看版本信息"
    else
        echo -e "${Yellow}总体状态：${Font}未安装"
        echo
        echo -e "${Yellow}安装后可使用：${Font}"
        echo -e "  ${Blue}sudo ${command_name}${Font}           # 启动脚本"
    fi
    
    echo
    echo -e "${Yellow}PATH 环境变量：${Font}"
    echo -e "${Blue}$(echo $PATH | tr ':' '\n' | grep -E '(usr/bin|usr/sbin|usr/local/bin)' || echo "未找到相关路径")${Font}"
    
    echo -e "${Blue}============================================${Font}"
    echo
}

# 启动脚本
main "$@"
