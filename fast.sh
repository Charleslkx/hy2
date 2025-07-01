#!/usr/bin/env bash
# Hysteria 2 Fast Installation Script
# 简易版本 - 自动化安装Hysteria2
# 支持远程运行模式

# 远程运行示例：
# bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh)
# bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh) --auto --domain example.com
# wget -O- https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh | bash
# wget -O- https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh | bash -s --help
#

# 颜色定义
Green="\033[32m"
Font="\033[0m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[34m"

# 远程仓库配置
REPO_URL="https://raw.githubusercontent.com/charleslkx/hy2/master"
SCRIPT_VERSION="1.0"

# 检测区
export LANG=en_US.UTF-8

echoContent() {
    case $1 in
    "red")
        echo -e "\033[31m${2}\033[0m"
        ;;
    "green")
        echo -e "\033[32m${2}\033[0m"
        ;;
    "yellow")
        echo -e "\033[33m${2}\033[0m"
        ;;
    "blue")
        echo -e "\033[34m${2}\033[0m"
        ;;
    "purple")
        echo -e "\033[35m${2}\033[0m"
        ;;
    "skyBlue")
        echo -e "\033[36m${2}\033[0m"
        ;;
    "white")
        echo -e "\033[37m${2}\033[0m"
        ;;
    esac
}

# 检查root权限
checkRoot() {
    if [[ $EUID -ne 0 ]]; then
        echoContent red "错误：此脚本必须以 root 权限运行！"
        exit 1
    fi
}

# 检查OpenVZ
checkOVZ() {
    if [[ -d "/proc/vz" ]]; then
        echoContent red "错误：您的VPS基于OpenVZ，不支持创建swap！"
        exit 1
    fi
}

# 检查系统
checkSystem() {
    if [[ -n $(find /etc -name "redhat-release") ]] || grep </proc/version -q -i "centos"; then
        centosVersion=$(rpm -q centos-release | awk -F "[-]" '{print $3}' | awk -F "[.]" '{print $1}')
        release="centos"
        installType='yum -y install'
        removeType='yum -y remove'
        upgrade="yum update -y --skip-broken"
    elif grep </etc/issue -q -i "debian" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "debian" && [[ -f "/proc/version" ]]; then
        release="debian"
        installType='apt -y install'
        upgrade="apt update"
        updateReleaseInfoChange='apt-get --allow-releaseinfo-change update'
        removeType='apt -y autoremove'
    elif grep </etc/issue -q -i "ubuntu" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "ubuntu" && [[ -f "/proc/version" ]]; then
        release="ubuntu"
        installType='apt -y install'
        upgrade="apt update"
        updateReleaseInfoChange='apt-get --allow-releaseinfo-change update'
        removeType='apt -y autoremove'
    fi

    if [[ -z ${release} ]]; then
        echoContent red "不支持此系统，请手动安装"
        exit 1
    fi
}

# 获取内存大小（MB）
getMemorySize() {
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_mb=$((mem_kb / 1024))
    echo $mem_mb
}

# 创建1G swap
createSwap() {
    if [[ "${SKIP_SWAP}" == "true" ]]; then
        echoContent yellow "跳过创建swap（通过 --skip-swap 参数）"
        return 0
    fi
    
    echoContent blue "正在检查系统内存和swap状态..."
    
    local memory_mb=$(getMemorySize)
    echoContent green "当前系统内存：${memory_mb}MB"
    
    # 检查是否已存在swap
    if grep -q "swapfile" /etc/fstab; then
        echoContent yellow "检测到已存在swap文件，跳过创建。"
        return 0
    fi
    
    echoContent green "正在创建1GB的swap文件..."
    
    # 创建1GB swap文件
    if fallocate -l 1G /swapfile; then
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
        echoContent green "1GB swap创建成功！"
        cat /proc/swaps
    else
        echoContent red "Swap创建失败，请检查磁盘空间"
        exit 1
    fi
}

# 获取公网IP
getPublicIP() {
    local currentIP=
    currentIP=$(curl -s -4 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "[=]" '{print $2}')
    
    if [[ -z "${currentIP}" ]]; then
        currentIP=$(curl -s -6 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "[=]" '{print $2}')
    fi
    
    if [[ -z "${currentIP}" ]]; then
        currentIP=$(curl -s https://api.ipify.org)
    fi
    
    echo "${currentIP}"
}

# 安装工具包
installTools() {
    echoContent skyBlue "进度 1/8 : 安装工具"
    
    # 修复ubuntu个别系统问题
    if [[ "${release}" == "ubuntu" ]]; then
        dpkg --configure -a
    fi

    if [[ -n $(pgrep -f "apt") ]]; then
        pgrep -f apt | xargs kill -9
    fi

    echoContent green " ---> 检查、安装更新【新机器会很慢，如长时间无反应，请手动停止后重新执行】"

    ${upgrade} >/dev/null 2>&1
    if [[ "${release}" == "ubuntu" ]] || [[ "${release}" == "debian" ]]; then
        ${updateReleaseInfoChange} >/dev/null 2>&1
    fi

    if [[ "${release}" == "centos" ]]; then
        if [[ "${centosVersion}" == "6" ]]; then
            echoContent red " ---> 不支持CentOS6"
            exit 1
        fi
        rm -rf /var/run/yum.pid
        ${installType} epel-release >/dev/null 2>&1
    fi

    # 安装基础工具
    if ! find /usr/bin /usr/sbin | grep -q -w wget; then
        echoContent green " ---> 安装wget"
        ${installType} wget >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w curl; then
        echoContent green " ---> 安装curl"
        ${installType} curl >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w unzip; then
        echoContent green " ---> 安装unzip"
        ${installType} unzip >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w socat; then
        echoContent green " ---> 安装socat"
        ${installType} socat >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w tar; then
        echoContent green " ---> 安装tar"
        ${installType} tar >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w cron; then
        echoContent green " ---> 安装crontabs"
        if [[ "${release}" == "ubuntu" ]] || [[ "${release}" == "debian" ]]; then
            ${installType} cron >/dev/null 2>&1
        else
            ${installType} crontabs >/dev/null 2>&1
        fi
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w jq; then
        echoContent green " ---> 安装jq"
        ${installType} jq >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w openssl; then
        echoContent green " ---> 安装openssl"
        ${installType} openssl >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w lsof; then
        echoContent green " ---> 安装lsof"
        ${installType} lsof >/dev/null 2>&1
    fi

    # 安装iptables-persistent（仅适用于基于Debian的系统）
    if [[ "${release}" == "debian" ]] || [[ "${release}" == "ubuntu" ]]; then
        if ! dpkg -l | grep -q iptables-persistent; then
            echoContent green " ---> 安装iptables-persistent"
            # 预设置答案以避免交互式提示
            echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
            echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
            ${installType} iptables-persistent >/dev/null 2>&1
        fi
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w dig; then
        echoContent green " ---> 安装dig"
        if echo "${installType}" | grep -qw "apt"; then
            ${installType} dnsutils >/dev/null 2>&1
        elif echo "${installType}" | grep -qw "yum"; then
            ${installType} bind-utils >/dev/null 2>&1
        fi
    fi

    # 检查systemd支持
    if ! command -v systemctl >/dev/null 2>&1; then
        echoContent red "错误：系统不支持systemd，无法继续安装"
        exit 1
    fi

    # 安装 uuid 生成工具
    if ! find /usr/bin /usr/sbin | grep -q -w uuidgen; then
        if [[ "${release}" == "ubuntu" ]] || [[ "${release}" == "debian" ]]; then
            echoContent green " ---> 安装uuid-runtime"
            ${installType} uuid-runtime >/dev/null 2>&1
        elif [[ "${release}" == "centos" ]]; then
            echoContent green " ---> 安装util-linux"
            ${installType} util-linux >/dev/null 2>&1
        fi
    fi

    # 安装 nslookup 工具
    if ! find /usr/bin /usr/sbin | grep -q -w nslookup; then
        if echo "${installType}" | grep -qw "apt"; then
            ${installType} dnsutils >/dev/null 2>&1
        elif echo "${installType}" | grep -qw "yum"; then
            ${installType} bind-utils >/dev/null 2>&1
        fi
    fi
}

# 安装 sing-box
installSingBox() {
    echoContent skyBlue "进度 2/8 : 安装sing-box"
    
    local version=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name)
    local downloadUrl="https://github.com/SagerNet/sing-box/releases/download/${version}/sing-box-${version#v}-linux-amd64.tar.gz"
    
    if ! curl -L -o /tmp/sing-box.tar.gz "${downloadUrl}"; then
        echoContent red "下载sing-box失败"
        exit 1
    fi
    
    mkdir -p /etc/v2ray-agent/sing-box/
    cd /tmp && tar -xzf sing-box.tar.gz
    
    local extractedDir=$(find /tmp -maxdepth 1 -type d -name "sing-box-*" | head -1)
    if [[ -n "${extractedDir}" ]]; then
        cp "${extractedDir}/sing-box" /etc/v2ray-agent/sing-box/
        chmod 755 /etc/v2ray-agent/sing-box/sing-box
    else
        echoContent red "提取sing-box失败"
        exit 1
    fi
    
    rm -rf /tmp/sing-box*
}

# 输入域名
inputDomain() {
    echoContent skyBlue "进度 3/8 : 配置域名"
    
    # 如果通过参数指定了域名，直接使用
    if [[ -n "${SPECIFIED_DOMAIN}" ]]; then
        domain="${SPECIFIED_DOMAIN}"
        echoContent green "使用指定的域名：${domain}"
        currentHost="${domain}"
        return 0
    fi
    
    # 自动模式下需要域名参数
    if [[ "${AUTO_MODE}" == "true" ]]; then
        echoContent red "自动模式下必须通过 --domain 参数指定域名"
        echoContent yellow "示例: --domain example.com"
        exit 1
    fi
    
    while true; do
        read -r -p "请输入您的域名（如：example.com）: " domain
        
        if [[ -z "${domain}" ]]; then
            echoContent red "域名不能为空，请重新输入"
            continue
        fi
        
        # 简单的域名格式验证
        if [[ ! "${domain}" =~ ^[a-zA-Z0-9][a-zA-Z0-9\.-]*[a-zA-Z0-9]$ ]]; then
            echoContent red "域名格式不正确，请重新输入"
            continue
        fi
        
        # 检查域名解析
        local domainIP=$(nslookup "${domain}" | grep -A 1 "Name:" | tail -n 1 | awk '{print $2}')
        local currentIP=$(getPublicIP)
        
        if [[ "${domainIP}" == "${currentIP}" ]]; then
            echoContent green "域名解析正确"
            currentHost="${domain}"
            break
        else
            echoContent yellow "域名解析IP：${domainIP}"
            echoContent yellow "当前服务器IP：${currentIP}"
            echoContent yellow "域名解析不匹配，但继续安装..."
            currentHost="${domain}"
            break
        fi
    done
}

# 生成随机UUID
generateUUID() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

# 生成随机端口
generateRandomPort() {
    echo $((RANDOM % 10000 + 20000))
}

# 申请SSL证书
installSSL() {
    echoContent skyBlue "进度 4/8 : 申请SSL证书"
    
    # 安装 acme.sh
    if [[ ! -f "/root/.acme.sh/acme.sh" ]]; then
        curl https://get.acme.sh | sh
        echo 'alias acme.sh=~/.acme.sh/acme.sh' >> ~/.bashrc
        source ~/.bashrc
    fi
    
    # 创建证书目录
    mkdir -p /etc/v2ray-agent/tls/
    
    # 申请证书
    if /root/.acme.sh/acme.sh --issue -d "${currentHost}" --standalone --keylength ec-256; then
        echoContent green "证书申请成功"
        
        # 安装证书
        /root/.acme.sh/acme.sh --install-cert -d "${currentHost}" \
            --ecc \
            --key-file /etc/v2ray-agent/tls/"${currentHost}".key \
            --fullchain-file /etc/v2ray-agent/tls/"${currentHost}".crt
        
        chmod 644 /etc/v2ray-agent/tls/"${currentHost}".crt
        chmod 600 /etc/v2ray-agent/tls/"${currentHost}".key
    else
        echoContent red "证书申请失败，请检查域名解析"
        exit 1
    fi
}

# 初始化Hysteria2配置
initHysteria2Config() {
    echoContent skyBlue "进度 5/8 : 初始化Hysteria2配置"
    
    # 生成随机值
    hysteriaUUID=$(generateUUID)
    hysteriaPort=$(generateRandomPort)
    
    # 创建配置目录
    mkdir -p /etc/v2ray-agent/sing-box/conf/config/
    
    # 创建Hysteria2配置
    cat <<EOF >/etc/v2ray-agent/sing-box/conf/config.json
{
  "log": {
    "level": "warn",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "cf",
        "address": "1.1.1.1"
      },
      {
        "tag": "local",
        "address": "223.5.5.5",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "geosite": "cn",
        "server": "local"
      }
    ]
  },
  "inbounds": [
    {
      "tag": "hysteria2-in",
      "type": "hysteria2",
      "listen": "::",
      "listen_port": ${hysteriaPort},
      "users": [
        {
          "name": "user",
          "password": "${hysteriaUUID}"
        }
      ],
      "masquerade": "https://www.bing.com",
      "tls": {
        "enabled": true,
        "server_name": "${currentHost}",
        "key_path": "/etc/v2ray-agent/tls/${currentHost}.key",
        "certificate_path": "/etc/v2ray-agent/tls/${currentHost}.crt",
        "alpn": ["h3"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "block",
      "type": "block"
    }
  ],
  "route": {
    "geoip": {
      "download_url": "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db",
      "download_detour": "direct"
    },
    "geosite": {
      "download_url": "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db", 
      "download_detour": "direct"
    },
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "geosite": "cn",
        "geoip": "cn",
        "outbound": "direct"
      }
    ],
    "final": "direct"
  }
}
EOF
}

# 创建系统服务
createSystemService() {
    echoContent skyBlue "进度 6/8 : 创建系统服务"
    
    cat <<EOF >/etc/systemd/system/sing-box.service
[Unit]
Description=Sing-Box Service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
ExecStart=/etc/v2ray-agent/sing-box/sing-box run -c /etc/v2ray-agent/sing-box/conf/config.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNPROC=infinity
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable sing-box
}

# 配置端口跳跃（简化版）
configurePortHopping() {
    echoContent skyBlue "进度 7/8 : 配置端口跳跃"
    
    # 生成随机端口范围
    local startPort=$((hysteriaPort))
    local endPort=$((hysteriaPort + 1000))
    
    # 添加iptables规则允许端口范围
    iptables -I INPUT -p udp --dport ${startPort}:${endPort} -j ACCEPT
    
    # 保存iptables规则
    if command -v iptables-save >/dev/null 2>&1; then
        iptables-save > /etc/iptables.rules
        
        # 创建开机自动加载规则的脚本
        cat <<EOF >/etc/network/if-pre-up.d/iptables
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOF
        chmod +x /etc/network/if-pre-up.d/iptables
    fi
    
    echoContent green "端口跳跃配置完成，端口范围：${startPort}-${endPort}"
}

# 添加定时重启任务
addRebootCron() {
    echoContent skyBlue "进度 8/8 : 添加每日定时重启"
    
    # 检查是否已存在重启任务
    if ! crontab -l 2>/dev/null | grep -q "0 5 \* \* \* /sbin/reboot"; then
        # 备份当前的crontab
        crontab -l 2>/dev/null > /tmp/current_crontab || touch /tmp/current_crontab
        
        # 添加新的重启任务（每天凌晨5点重启）
        echo "0 5 * * * /sbin/reboot" >> /tmp/current_crontab
        
        # 应用新的crontab
        if crontab /tmp/current_crontab; then
            echoContent green "每日5点定时重启任务添加成功"
        else
            echoContent yellow "定时重启任务添加失败"
        fi
        
        rm -f /tmp/current_crontab
    else
        echoContent yellow "定时重启任务已存在"
    fi
}

# 启动服务
startService() {
    echoContent green "正在启动Hysteria2服务..."
    
    if systemctl start sing-box && systemctl is-active --quiet sing-box; then
        echoContent green "Hysteria2服务启动成功！"
    else
        echoContent red "Hysteria2服务启动失败！"
        echoContent yellow "请检查配置文件和证书"
        exit 1
    fi
}

# 生成客户端配置
generateClientConfig() {
    echoContent green "============================================"
    echoContent blue "         Hysteria2 客户端配置"
    echoContent green "============================================"
    echo
    echoContent yellow "服务器地址: ${currentHost}"
    echoContent yellow "端口: ${hysteriaPort}"
    echoContent yellow "密码: ${hysteriaUUID}"
    echoContent yellow "下行速度: 1000 Mbps"
    echoContent yellow "上行速度: 500 Mbps"
    echo
    
    # 按照 hy2.sh 的格式生成链接
    local multiPort=""
    local portRange="${hysteriaPort}-$((hysteriaPort + 1000))"
    
    # 检查是否启用了端口跳跃（端口范围）
    if [[ -n "${portRange}" && "${portRange}" != "${hysteriaPort}-${hysteriaPort}" ]]; then
        multiPort="mport=${portRange}&"
    fi
    
    echoContent blue "Hysteria2 分享链接:"
    echo "hysteria2://${hysteriaUUID}@${currentHost}:${hysteriaPort}?${multiPort}peer=${currentHost}&insecure=0&sni=${currentHost}&alpn=h3#Hysteria2-Fast"
    echo
    
    echoContent green "客户端配置文件 (YAML格式):"
    cat <<EOF
server: ${currentHost}:${hysteriaPort}
auth: ${hysteriaUUID}

bandwidth:
  up: 500 mbps
  down: 1000 mbps

tls:
  sni: ${currentHost}
  insecure: false
  alpn:
    - h3

socks5:
  listen: 127.0.0.1:1080

http:
  listen: 127.0.0.1:8080
EOF
    echo
    
    echoContent green "ClashMeta 配置格式:"
    cat <<EOF
  - name: "Hysteria2-Fast"
    type: hysteria2
    server: ${currentHost}
    port: ${hysteriaPort}
    password: ${hysteriaUUID}
    alpn:
      - h3
    sni: ${currentHost}
    up: "500 Mbps"
    down: "1000 Mbps"
EOF
    echo
    
    echoContent green "Sing-Box 配置格式:"
    cat <<EOF
{
  "tag": "Hysteria2-Fast",
  "type": "hysteria2",
  "server": "${currentHost}",
  "server_port": ${hysteriaPort},
  "up_mbps": 500,
  "down_mbps": 1000,
  "password": "${hysteriaUUID}",
  "tls": {
    "enabled": true,
    "server_name": "${currentHost}",
    "alpn": ["h3"]
  }
}
EOF
    echo
    echoContent green "============================================"
    echoContent blue "快速管理命令:"
    echoContent yellow "启动服务: systemctl start sing-box"
    echoContent yellow "停止服务: systemctl stop sing-box"
    echoContent yellow "重启服务: systemctl restart sing-box"
    echoContent yellow "查看状态: systemctl status sing-box"
    echoContent yellow "查看日志: journalctl -u sing-box -f"
    echoContent green "============================================"
}

# 显示帮助信息
showHelp() {
    clear
    echo -e "${Blue}============================================${Font}"
    echo -e "${Green}    Hysteria2 Fast Installation Script${Font}"
    echo -e "${Blue}============================================${Font}"
    echo
    echo -e "${Green}用法：${Font}"
    echo -e "  bash <(curl -fsSL ${REPO_URL}/fast.sh) [选项]"
    echo -e "  或"
    echo -e "  wget -O- ${REPO_URL}/fast.sh | bash -s [选项]"
    echo
    echo -e "${Green}选项：${Font}"
    echo -e "  ${Yellow}--help, -h${Font}              显示此帮助信息"
    echo -e "  ${Yellow}--version, -v${Font}           显示版本信息"
    echo -e "  ${Yellow}--auto${Font}                  自动模式（跳过确认）"
    echo -e "  ${Yellow}--domain DOMAIN${Font}         指定域名"
    echo -e "  ${Yellow}--skip-swap${Font}             跳过创建swap"
    echo
    echo -e "${Green}功能特性：${Font}"
    echo -e "  • 自动创建1GB Swap虚拟内存"
    echo -e "  • 安装和配置 Hysteria2"
    echo -e "  • 自动申请 SSL 证书"
    echo -e "  • 配置端口跳跃"
    echo -e "  • 添加每日定时重启"
    echo -e "  • 自动生成客户端配置"
    echo
    echo -e "${Green}示例：${Font}"
    echo -e "  ${Yellow}# 交互式安装${Font}"
    echo -e "  bash <(curl -fsSL ${REPO_URL}/fast.sh)"
    echo
    echo -e "  ${Yellow}# 自动模式安装${Font}"
    echo -e "  bash <(curl -fsSL ${REPO_URL}/fast.sh) --auto --domain example.com"
    echo
    echo -e "${Green}GitHub仓库：${Font}https://github.com/charleslkx/hy2"
    echo -e "${Blue}============================================${Font}"
}

# 显示版本信息
showVersion() {
    echo -e "${Green}Hysteria2 Fast Installation Script v${SCRIPT_VERSION}${Font}"
    echo -e "${Green}GitHub: https://github.com/charleslkx/hy2${Font}"
    echo -e "${Blue}远程运行模式 - 始终获取最新版本${Font}"
}

# 检查网络连接
checkNetwork() {
    echoContent blue "正在检查网络连接..."
    if ping -c 1 raw.githubusercontent.com >/dev/null 2>&1; then
        echoContent green "网络连接正常"
        return 0
    else
        echoContent red "无法连接到远程仓库，请检查网络连接"
        return 1
    fi
}

# 解析命令行参数
parseArgs() {
    AUTO_MODE=false
    SKIP_SWAP=false
    SPECIFIED_DOMAIN=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                showHelp
                exit 0
                ;;
            --version|-v)
                showVersion
                exit 0
                ;;
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --domain)
                SPECIFIED_DOMAIN="$2"
                shift 2
                ;;
            --skip-swap)
                SKIP_SWAP=true
                shift
                ;;
            *)
                echoContent red "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 解析命令行参数
    parseArgs "$@"
    
    # 检查网络连接
    if ! checkNetwork; then
        exit 1
    fi
    
    clear
    echoContent green "============================================"
    echoContent blue "    Hysteria2 Fast Installation Script"
    echoContent blue "           简易版本自动安装脚本"
    echoContent blue "              远程运行模式"
    echoContent green "============================================"
    echo
    
    # 检查权限和环境
    checkRoot
    checkOVZ
    checkSystem
    
    echoContent yellow "本脚本将自动完成以下操作："
    echoContent blue "1. 创建1GB Swap虚拟内存"
    echoContent blue "2. 安装和配置 Hysteria2"
    echoContent blue "3. 申请 SSL 证书"
    echoContent blue "4. 配置端口跳跃"
    echoContent blue "5. 添加每日定时重启"
    echoContent blue "6. 自动生成客户端配置"
    echo
    
    if [[ "${AUTO_MODE}" != "true" ]]; then
        read -p "按回车键开始安装，或按 Ctrl+C 取消..."
    else
        echoContent green "自动模式已启用，开始安装..."
        sleep 2
    fi
    
    # 执行安装步骤
    createSwap
    installTools
    installSingBox
    inputDomain
    installSSL
    initHysteria2Config
    createSystemService
    configurePortHopping
    addRebootCron
    startService
    generateClientConfig
    
    echoContent green "Hysteria2 安装完成！"
    
    if [[ "${AUTO_MODE}" == "true" ]]; then
        echoContent blue "配置信息已保存到 /etc/v2ray-agent/sing-box/client-config.txt"
        mkdir -p /etc/v2ray-agent/sing-box/
        
        # 计算端口跳跃范围
        local multiPort=""
        local portRange="${hysteriaPort}-$((hysteriaPort + 1000))"
        if [[ -n "${portRange}" && "${portRange}" != "${hysteriaPort}-${hysteriaPort}" ]]; then
            multiPort="mport=${portRange}&"
        fi
        
        cat <<EOF > /etc/v2ray-agent/sing-box/client-config.txt
服务器地址: ${currentHost}
端口: ${hysteriaPort}
密码: ${hysteriaUUID}
端口跳跃范围: ${portRange}
分享链接: hysteria2://${hysteriaUUID}@${currentHost}:${hysteriaPort}?${multiPort}peer=${currentHost}&insecure=0&sni=${currentHost}&alpn=h3#Hysteria2-Fast
EOF
    fi
}

# 启动脚本
main "$@"
