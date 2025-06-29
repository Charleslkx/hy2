# Hysteria 2 多协议一键安装脚本

基于 V2Ray-Agent 的八合一共存脚本，专门用于安装和管理 Hysteria 2 等多种代理协议。支持多操作系统，提供完整的安装、配置、管理功能。

**本仓库仅供自用，不会回复任何问题，更新频率完全随机。**

## 🚀 统一管理 - main.sh

全新的统一管理脚本，提供智能环境初始化和脚本选择：

### 核心特性
- **🧠 智能 Swap 管理**: 根据内存自动推荐合适配置
- **🎯 脚本选择**: 统一管理所有脚本的启动和切换
- **🔧 环境检查**: 自动检查 root 权限和虚拟化环境
- **🔄 自动更新**: 内置脚本自动更新功能
- **⏰ 定时重启**: V2Ray 安装后自动配置系统定时重启
- **💻 简易命令**: 支持安装 `hy2` 命令快速启动脚本

### 增强功能
- **自动端口跳跃**: Hysteria 2 专属，范围 30000-40000
- **防火墙持久化**: 自动安装 iptables-persistent，规则重启后自动恢复
- **系统维护**: 每日凌晨 5:00 自动重启，保持最佳性能
- **多路径命令**: 支持 /usr/bin、/usr/sbin、/usr/local/bin

## 一键安装

```bash
bash <(wget -qO- https://raw.githubusercontent.com/charleslkx/hy2/master/main.sh)
```

### 安装简易命令（可选）
```bash
# 通过脚本菜单安装，或使用参数直接安装
bash main.sh --install-command
# 安装后可直接使用
sudo hy2
```

## 文件说明

- **`main.sh`** - 统一管理脚本，智能 swap + 脚本选择 + 自动更新 + 命令管理
- **`hy2.sh`** - 主安装脚本，八合一共存 + 增强功能
- **`v2ray.sh`** - V2Ray 专用安装脚本 + 定时重启配置
- **`swap.sh`** - 专用 swap 管理脚本

## 主要功能

### 协议支持
- **Hysteria 2**: 端口跳跃、速度配置、用户管理
- **REALITY**: 密钥生成、流量伪装
- **Tuic**: 配置优化、连接管理
- **V2Ray/Xray**: 多协议共存

### 管理工具
- **用户管理**: 添加、删除、修改用户配置
- **证书管理**: 自动申请、更新 SSL/TLS 证书
- **CDN 节点**: 优化全球访问速度
- **系统维护**: 自动配置定时重启任务

## 使用说明

### main.sh 统一管理（推荐）

```bash
# 1. 下载运行统一管理脚本
wget -O main.sh https://raw.githubusercontent.com/charleslkx/hy2/master/main.sh
chmod +x main.sh
sudo ./main.sh

# 2. 按提示进行环境初始化
# - Root 权限验证
# - OpenVZ 兼容性检查  
# - 智能 Swap 配置

# 3. 选择要运行的脚本
# - V2Ray 安装 (推荐新用户)
# - Hysteria2 安装 (八合一版本)
# - Swap 管理
# - 脚本更新

# 4. 安装简易命令（可选）
# 选择 "5. 命令管理" -> "1. 安装简易命令"
# 安装后可直接使用：sudo hy2
```

### 传统安装

```bash
# 直接运行 Hysteria2 安装脚本
bash <(wget -qO- https://raw.githubusercontent.com/charleslkx/hy2/master/hy2.sh)
```

## 命令行参数

main.sh 支持以下参数：

```bash
./main.sh --help              # 显示帮助信息
./main.sh --version           # 显示版本信息
./main.sh --install-command   # 直接安装简易命令
./main.sh --uninstall-command # 卸载简易命令
```

## 注意事项

1. **系统要求**: 建议使用纯净系统环境
2. **域名准备**: 需要准备域名并正确解析
3. **权限**: 需要 root 权限运行
4. **SELinux**: CentOS 用户需要关闭 SELinux
5. **虚拟化**: OpenVZ 不支持 swap 创建

## 故障排除

### Swap 相关
```bash
df -h  # 检查磁盘空间
fallocate -l 1G /test_swapfile && rm /test_swapfile  # 测试创建
```

### 脚本问题
```bash
# 脚本文件不存在
wget -O hy2.sh https://raw.githubusercontent.com/charleslkx/hy2/master/hy2.sh

# 权限问题
sudo ./main.sh
chmod +x *.sh
```

### 定时重启任务
```bash
crontab -l  # 查看定时任务
crontab -e  # 编辑定时任务
```

### 端口跳跃检查
```bash
iptables -t nat -L | grep hysteria2  # 检查规则
netstat -ulnp | grep :30000  # 检查端口状态
```

### 简易命令问题
```bash
# 检查 hy2 命令安装状态
which hy2
ls -la /usr/bin/hy2 /usr/sbin/hy2 /usr/local/bin/hy2

# 重新安装命令
bash main.sh --install-command
```

## 鸣谢

感谢以下项目的支持：
- [v2ray-agent](https://github.com/mack-a/v2ray-agent) by mack-a
- [v2ray](https://github.com/233boy/v2ray) by 233boy

## 免责声明

本脚本仅供学习和研究使用，请遵守当地法律法规。使用本脚本产生的任何问题，作者不承担责任。
