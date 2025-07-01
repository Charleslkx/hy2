# Hysteria2 Fast Installation Script - 远程运行指南

## 概述

`fast.sh` 是基于 `hy2.sh` 的简易版本，专为快速部署 Hysteria2 而设计。该脚本支持远程运行模式，无需本地下载即可直接执行。

## 功能特性

- ✅ 自动创建 1GB Swap 虚拟内存
- ✅ 安装和配置 Hysteria2 (基于 sing-box)
- ✅ 自动申请 SSL 证书 (Let's Encrypt)
- ✅ 配置端口跳跃
- ✅ 添加每日定时重启 (每天凌晨5点)
- ✅ 自动生成客户端配置
- ✅ 远程运行支持
- ✅ 参数化配置

## 远程运行方式

### 方式一：使用 curl (推荐)

```bash
# 交互式安装
bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh)

# 自动模式安装 (适合脚本化部署)
bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh) --auto --domain example.com

# 查看帮助
bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh) --help
```

### 方式二：使用 wget

```bash
# 交互式安装
wget -O- https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh | bash

# 自动模式安装
wget -O- https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh | bash -s --auto --domain example.com

# 查看帮助
wget -O- https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh | bash -s --help
```

## 命令行选项

| 选项 | 说明 | 示例 |
|------|------|------|
| `--help`, `-h` | 显示帮助信息 | `--help` |
| `--version`, `-v` | 显示版本信息 | `--version` |
| `--auto` | 自动模式，跳过交互确认 | `--auto` |
| `--domain DOMAIN` | 指定域名 | `--domain example.com` |
| `--skip-swap` | 跳过创建 swap | `--skip-swap` |

## 使用示例

### 1. 基础交互式安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh)
```

这是最简单的使用方式，脚本会引导您完成所有配置。

### 2. 自动化部署

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh) --auto --domain yourdomain.com
```

适合批量部署或自动化脚本，无需人工干预。

### 3. 跳过 Swap 创建

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/charleslkx/hy2/master/fast.sh) --skip-swap --domain yourdomain.com
```

如果您的服务器已有足够内存或已配置 swap，可以跳过此步骤。

## 系统要求

- **操作系统**: CentOS 7+, Ubuntu 16.04+, Debian 9+
- **权限**: Root 权限
- **网络**: 能够访问 GitHub 和相关下载源
- **域名**: 已解析到服务器的域名（用于 SSL 证书）

## 预设配置

根据 Simple_version.md 的要求，脚本使用以下预设：

- **Swap 大小**: 1GB
- **协议**: Hysteria2 (不包含其他协议)
- **UUID**: 随机生成
- **端口**: 随机生成 (20000-30000)
- **端口跳跃**: 自动配置 (端口+100)
- **SSL 证书**: Let's Encrypt (不使用 DNS API)
- **带宽限制**: 
  - 下行: 1000 Mbps
  - 上行: 500 Mbps
- **定时重启**: 每天凌晨5点

## 安装后管理

安装完成后，您可以使用以下命令管理服务：

```bash
# 启动服务
systemctl start sing-box

# 停止服务
systemctl stop sing-box

# 重启服务
systemctl restart sing-box

# 查看状态
systemctl status sing-box

# 查看日志
journalctl -u sing-box -f

# 查看配置文件
cat /etc/v2ray-agent/sing-box/conf/config.json
```

## 客户端配置

安装完成后，脚本会自动生成客户端配置：

1. **分享链接**: 直接复制使用
2. **YAML 配置**: 适用于 Hysteria2 客户端
3. **自动模式**: 配置保存在 `/etc/v2ray-agent/sing-box/client-config.txt`

## 故障排除

### 1. 网络连接问题

```bash
# 检查是否能访问 GitHub
ping raw.githubusercontent.com
```

### 2. 域名解析问题

```bash
# 检查域名解析
nslookup yourdomain.com

# 检查服务器公网IP
curl -4 http://www.cloudflare.com/cdn-cgi/trace
```

### 3. 证书申请失败

- 确保域名已正确解析到服务器
- 检查 80 端口是否被占用
- 确保服务器防火墙允许 80 和 443 端口

### 4. 服务启动失败

```bash
# 检查配置文件语法
/etc/v2ray-agent/sing-box/sing-box check -c /etc/v2ray-agent/sing-box/conf/config.json

# 查看详细错误日志
journalctl -u sing-box -n 50
```

