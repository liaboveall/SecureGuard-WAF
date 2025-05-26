# 🛡️ Struts2 安全扫描与 WAF 绕过工具集

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security](https://img.shields.io/badge/Security-Testing-red.svg)]()
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)]()

专业的Web应用安全测试工具集，支持多种CVE漏洞的复现、检测和WAF防护测试。

## 🚀 快速开始

### 环境要求
- Linux系统 (Ubuntu 18.04+/CentOS 7+)
- Docker & Docker Compose
- Bash 4.0+

### 安装与运行
```bash
git clone https://github.com/your-username/Struts2-scan-and-WAF.git
cd Struts2-scan-and-WAF

# 使用主控制脚本
./main.sh

# 或直接运行特定CVE脚本
./scripts/cve-2020-17530.sh
```

## 🔍 支持的 CVE

| CVE | 描述 | 组件 | 危险等级 |
|-----|------|------|----------|
| CVE-2016-10134 | Zabbix SQL注入 | Zabbix 2.2.x/3.0.x | 🔴 高危 |
| CVE-2020-17530 | Struts2 S2-061 OGNL注入 | Struts 2.0.0-2.5.25 | 🟠 严重 |
| CVE-2021-21389 | WordPress BuddyPress权限提升 | BuddyPress < 7.2.1 | 🔴 高危 |
| CVE-2021-22205 | GitLab DjVu文件上传RCE | GitLab CE/EE | 🟠 严重 |

## 📁 项目结构

```
├── config/           # 全局配置
├── scripts/          # CVE脚本
├── utils/            # 工具库  
├── templates/        # 模板文件
└── logs/            # 日志目录
```

## ⚙️ 配置说明

编辑 `config/global.conf` 修改端口、容器名等参数：

```bash
# Struts2 相关配置
STRUTS2_PORT=8080
STRUTS2_CONTAINER_NAME="struts2-s2-061"

# WAF 相关配置  
WAF_PORT=8090
WAF_CONTAINER_NAME="waf-protection"
```

## 🔧 使用说明

每个脚本会自动生成：
- 🚀 `deploy.sh` - 部署环境
- 🧪 `test_*.sh` - 漏洞测试 
- 🧹 `cleanup.sh` - 清理环境
- 📊 监控面板 - 实时状态

## ⚠️ 安全警告

⚠️ **仅限授权测试环境使用**
- 请勿在生产环境运行
- 确保网络隔离
- 遵守当地法律法规

## 📝 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件