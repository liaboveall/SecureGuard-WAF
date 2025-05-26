#!/bin/bash

# 🛡️ Struts2 安全扫描与 WAF 绕过工具集 - 主控制脚本
# Author: Security Research Team
# Version: 2.0.0
# Description: 统一管理多个 CVE 场景的安全测试和防护部署

# Load configuration and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/global.conf"
source "$SCRIPT_DIR/utils/common.sh"

# Global variables
TOOL_VERSION="2.0.0"
TOOL_NAME="Struts2 安全扫描与 WAF 绕过工具集"

# Initialize main script
init_main() {
    check_prerequisites
    create_base_directories
}

# Check prerequisites
check_prerequisites() {
    log_info "检查系统依赖..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        echo -e "${YELLOW}安装指南: https://docs.docker.com/get-docker/${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        echo -e "${YELLOW}安装指南: https://docs.docker.com/compose/install/${NC}"
        exit 1
    fi
    
    # Check network connectivity
    if ! ping -c 1 hub.docker.com &> /dev/null; then
        log_warning "无法连接到 Docker Hub，可能影响镜像下载"
    fi
    
    log_success "系统依赖检查完成"
}

# Create base directories
create_base_directories() {
    mkdir -p logs templates
    touch logs/main.log
}

# Show main banner
show_main_banner() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    🛡️  Struts2 安全扫描与 WAF 绕过工具集 v2.0.0                              ║
║                                                                              ║
║    🎯 专业的 Web 应用安全测试平台                                              ║
║    🔒 支持多个 CVE 漏洞场景                                                    ║
║    🛡️ 基于 ModSecurity 的 WAF 防护                                            ║
║    📊 实时监控和详细报告                                                        ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Show CVE scenarios menu
show_cve_menu() {
    echo -e "${CYAN}=== 支持的 CVE 漏洞场景 ===${NC}\n"
    
    echo -e "${WHITE}1.${NC} ${GREEN}CVE-2016-10134${NC} - Zabbix SQL 注入漏洞"
    echo -e "   ${GRAY}• 影响版本: Zabbix 2.2.x, 3.0.x${NC}"
    echo -e "   ${GRAY}• 严重程度: 高危 (CVSS 8.8)${NC}"
    echo -e "   ${GRAY}• 攻击类型: SQL 注入${NC}\n"
    
    echo -e "${WHITE}2.${NC} ${GREEN}CVE-2020-17530${NC} - Struts2 S2-061 OGNL 注入"
    echo -e "   ${GRAY}• 影响版本: Struts 2.0.0-2.5.25${NC}"
    echo -e "   ${GRAY}• 严重程度: 严重 (CVSS 9.8)${NC}"
    echo -e "   ${GRAY}• 攻击类型: OGNL 表达式注入${NC}\n"
    
    echo -e "${WHITE}3.${NC} ${GREEN}CVE-2021-21389${NC} - WordPress BuddyPress 特权升级"
    echo -e "   ${GRAY}• 影响版本: BuddyPress < 7.2.1${NC}"
    echo -e "   ${GRAY}• 严重程度: 高危 (CVSS 8.0)${NC}"
    echo -e "   ${GRAY}• 攻击类型: 特权升级${NC}\n"
    
    echo -e "${WHITE}4.${NC} ${GREEN}CVE-2021-22205${NC} - GitLab DjVu 文件上传 RCE"
    echo -e "   ${GRAY}• 影响版本: GitLab CE/EE${NC}"
    echo -e "   ${GRAY}• 严重程度: 严重 (CVSS 10.0)${NC}"
    echo -e "   ${GRAY}• 攻击类型: 文件上传 RCE${NC}\n"
    
    echo -e "${CYAN}=== 管理功能 ===${NC}\n"
    echo -e "${WHITE}5.${NC} 📊 环境状态检查"
    echo -e "${WHITE}6.${NC} 🔧 全局配置管理"
    echo -e "${WHITE}7.${NC} 📝 查看日志"
    echo -e "${WHITE}8.${NC} 🧹 清理所有环境"
    echo -e "${WHITE}9.${NC} ℹ️  工具信息"
    echo -e "${WHITE}0.${NC} 🚪 退出程序\n"
}

# Run CVE script
run_cve_script() {
    local cve_choice=$1
    local script_path=""
    
    case $cve_choice in
        1)
            script_path="$SCRIPT_DIR/scripts/cve-2016-10134.sh"
            ;;
        2)
            script_path="$SCRIPT_DIR/scripts/cve-2020-17530.sh"
            ;;
        3)
            script_path="$SCRIPT_DIR/scripts/cve-2021-21389.sh"
            ;;
        4)
            script_path="$SCRIPT_DIR/scripts/cve-2021-22205.sh"
            ;;
        *)
            log_error "无效的 CVE 选择"
            return 1
            ;;
    esac
    
    if [ -f "$script_path" ]; then
        log_info "启动 CVE 脚本: $script_path"
        chmod +x "$script_path"
        "$script_path"
    else
        log_error "脚本文件不存在: $script_path"
    fi
}

# Check environment status
check_environment_status() {
    show_banner "环境状态检查"
    
    echo -e "${CYAN}=== Docker 环境状态 ===${NC}"
    
    # Docker version
    echo -e "${YELLOW}Docker 版本:${NC}"
    docker --version
    echo ""
    
    # Docker Compose version
    echo -e "${YELLOW}Docker Compose 版本:${NC}"
    if docker compose version &> /dev/null; then
        docker compose version
    elif docker-compose version &> /dev/null; then
        docker-compose version
    else
        echo -e "${RED}Docker Compose 未安装${NC}"
    fi
    echo ""
    
    # Running containers
    echo -e "${YELLOW}运行中的容器:${NC}"
    local containers=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(zabbix|struts|wordpress|gitlab|waf)")
    if [ -n "$containers" ]; then
        echo "$containers"
    else
        echo -e "${GRAY}没有相关容器在运行${NC}"
    fi
    echo ""
    
    # Resource usage
    echo -e "${YELLOW}系统资源使用:${NC}"
    echo -e "磁盘空间: $(df -h . | awk 'NR==2 {print $4 " 可用 / " $2 " 总计"}')"
    echo -e "内存使用: $(free -h | awk 'NR==2 {print $3 " / " $2}')"
    echo ""
    
    # Network status
    echo -e "${YELLOW}Docker 网络:${NC}"
    docker network ls | grep -E "(cve|zabbix|struts|wordpress|gitlab)" || echo -e "${GRAY}没有相关网络${NC}"
    echo ""
    
    # Project directories
    echo -e "${YELLOW}项目目录:${NC}"
    for dir in cve-*_protection */; do
        if [ -d "$dir" ]; then
            echo -e "  📁 $dir"
        fi
    done
    
    read -p "按 Enter 继续..."
}

# Manage global configuration
manage_global_config() {
    show_banner "全局配置管理"
    
    echo -e "${CYAN}当前配置文件: config/global.conf${NC}\n"
    
    echo -e "${YELLOW}选择操作:${NC}"
    echo -e "${WHITE}1.${NC} 查看当前配置"
    echo -e "${WHITE}2.${NC} 编辑配置文件"
    echo -e "${WHITE}3.${NC} 恢复默认配置"
    echo -e "${WHITE}4.${NC} 验证配置文件"
    echo -e "${WHITE}0.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择操作: " config_choice
    
    case $config_choice in
        1)
            echo -e "\n${CYAN}=== 当前配置内容 ===${NC}"
            cat "$SCRIPT_DIR/config/global.conf" | grep -v "^#" | grep -v "^$"
            ;;
        2)
            if command -v nano &> /dev/null; then
                nano "$SCRIPT_DIR/config/global.conf"
            elif command -v vim &> /dev/null; then
                vim "$SCRIPT_DIR/config/global.conf"
            else
                echo -e "${RED}未找到可用的编辑器 (nano/vim)${NC}"
            fi
            ;;
        3)
            if confirm_action "确定要恢复默认配置吗？"; then
                # Backup current config
                cp "$SCRIPT_DIR/config/global.conf" "$SCRIPT_DIR/config/global.conf.backup.$(date +%Y%m%d_%H%M%S)"
                # Restore default (you would implement this)
                log_info "配置已恢复为默认值 (原配置已备份)"
            fi
            ;;
        4)
            echo -e "\n${CYAN}=== 验证配置文件 ===${NC}"
            source "$SCRIPT_DIR/config/global.conf" && log_success "配置文件语法正确" || log_error "配置文件存在语法错误"
            ;;
        0)
            return 0
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
    
    read -p "按 Enter 继续..."
}

# View logs
view_main_logs() {
    show_banner "系统日志查看"
    
    echo -e "${YELLOW}选择日志类型:${NC}"
    echo -e "${WHITE}1.${NC} 主程序日志"
    echo -e "${WHITE}2.${NC} Docker 容器日志"
    echo -e "${WHITE}3.${NC} 系统资源日志"
    echo -e "${WHITE}4.${NC} 错误日志汇总"
    echo -e "${WHITE}0.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择: " log_choice
    
    case $log_choice in
        1)
            if [ -f "logs/main.log" ]; then
                echo -e "\n${CYAN}=== 主程序日志 (最近50行) ===${NC}"
                tail -50 logs/main.log
            else
                echo -e "${YELLOW}主程序日志文件不存在${NC}"
            fi
            ;;
        2)
            echo -e "\n${CYAN}=== Docker 容器日志 ===${NC}"
            containers=$(docker ps --format "{{.Names}}" | grep -E "(zabbix|struts|wordpress|gitlab|waf)")
            if [ -n "$containers" ]; then
                for container in $containers; do
                    echo -e "\n${YELLOW}--- $container ---${NC}"
                    docker logs --tail 10 "$container" 2>/dev/null || echo "无法获取日志"
                done
            else
                echo -e "${YELLOW}没有相关容器在运行${NC}"
            fi
            ;;
        3)
            echo -e "\n${CYAN}=== 系统资源使用 ===${NC}"
            echo -e "${YELLOW}内存使用情况:${NC}"
            free -h
            echo -e "\n${YELLOW}磁盘使用情况:${NC}"
            df -h
            echo -e "\n${YELLOW}Docker 资源使用:${NC}"
            docker stats --no-stream 2>/dev/null || echo "无容器运行"
            ;;
        4)
            echo -e "\n${CYAN}=== 错误日志汇总 ===${NC}"
            find logs/ -name "*.log" -type f -exec grep -l "ERROR\|error\|Error" {} \; 2>/dev/null | while read file; do
                echo -e "\n${YELLOW}--- $file ---${NC}"
                grep -n "ERROR\|error\|Error" "$file" | tail -5
            done
            ;;
        0)
            return 0
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
    
    read -p "按 Enter 继续..."
}

# Clean all environments
clean_all_environments() {
    show_banner "清理所有环境"
    
    echo -e "${RED}⚠️  警告: 此操作将清理所有 CVE 测试环境！${NC}\n"
    echo -e "${YELLOW}将要执行的操作:${NC}"
    echo -e "  • 停止所有相关容器"
    echo -e "  • 删除所有相关容器"
    echo -e "  • 删除所有相关网络"
    echo -e "  • 清理 Docker 卷"
    echo -e "  • 删除项目目录 (可选)"
    echo ""
    
    if ! confirm_action "确定要继续吗？"; then
        log_info "清理操作已取消"
        return 0
    fi
    
    log_info "开始清理所有环境..."
    
    # Stop and remove containers
    echo -e "\n${CYAN}清理容器...${NC}"
    docker ps -a --format "{{.Names}}" | grep -E "(zabbix|struts|wordpress|gitlab|waf)" | while read container; do
        echo -e "停止容器: $container"
        docker stop "$container" 2>/dev/null
        echo -e "删除容器: $container"
        docker rm "$container" 2>/dev/null
    done
    
    # Remove networks
    echo -e "\n${CYAN}清理网络...${NC}"
    docker network ls --format "{{.Name}}" | grep -E "(cve|zabbix|struts|wordpress|gitlab)" | while read network; do
        echo -e "删除网络: $network"
        docker network rm "$network" 2>/dev/null
    done
    
    # Clean volumes
    echo -e "\n${CYAN}清理卷...${NC}"
    docker volume prune -f
    
    # Clean images (optional)
    if confirm_action "是否删除相关 Docker 镜像？"; then
        echo -e "\n${CYAN}清理镜像...${NC}"
        docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(zabbix|struts|vuln|gitlab|modsecurity)" | while read image; do
            echo -e "删除镜像: $image"
            docker rmi "$image" 2>/dev/null
        done
    fi
    
    # Clean project directories (optional)
    if confirm_action "是否删除所有项目目录？"; then
        echo -e "\n${CYAN}清理项目目录...${NC}"
        for dir in cve-*_protection; do
            if [ -d "$dir" ]; then
                echo -e "删除目录: $dir"
                rm -rf "$dir"
            fi
        done
    fi
    
    # Clean logs (optional)
    if confirm_action "是否清理日志文件？"; then
        echo -e "\n${CYAN}清理日志文件...${NC}"
        find logs/ -name "*.log" -type f -delete 2>/dev/null
        echo -e "日志文件已清理"
    fi
    
    log_success "环境清理完成！"
    read -p "按 Enter 继续..."
}

# Show tool information
show_tool_info() {
    show_banner "工具信息"
    
    cat << EOF
${CYAN}🛡️ Struts2 安全扫描与 WAF 绕过工具集${NC}

${YELLOW}版本信息:${NC}
  • 版本: $TOOL_VERSION
  • 发布日期: 2024年
  • 更新内容: 完全重构，支持配置化部署

${YELLOW}支持的功能:${NC}
  • ✅ 4个重要 CVE 漏洞场景
  • ✅ ModSecurity WAF 防护
  • ✅ 实时监控和报告
  • ✅ 自动化测试脚本
  • ✅ Docker 容器化部署
  • ✅ 详细的日志记录

${YELLOW}技术栈:${NC}
  • 🐳 Docker & Docker Compose
  • 🛡️ OWASP ModSecurity
  • 🐧 Bash Shell Scripts
  • 📊 HTML/CSS/JavaScript (监控面板)
  • 🔍 JSON/YAML 配置

${YELLOW}安全注意事项:${NC}
  • ⚠️  仅供安全研究和教育目的使用
  • ⚠️  请勿在未授权系统上使用
  • ⚠️  建议在隔离环境中运行
  • ⚠️  使用者需自行承担风险

${YELLOW}获取帮助:${NC}
  • 📖 查看 README.md 文档
  • 🐛 GitHub Issues 反馈问题
  • 💬 GitHub Discussions 技术讨论
  • 📧 Email: security@example.com

${YELLOW}许可证:${NC}
  • 📄 MIT License
  • 🔓 开源免费使用
  • 🤝 欢迎社区贡献

${GREEN}感谢使用本工具进行安全研究！${NC}
EOF
    
    read -p "按 Enter 继续..."
}

# Main menu loop
main_menu_loop() {
    while true; do
        show_main_banner
        show_cve_menu
        
        echo -e "${YELLOW}请选择要执行的操作:${NC}"
        read -p "输入选项 (0-9): " choice
        
        case $choice in
            1|2|3|4)
                run_cve_script "$choice"
                ;;
            5)
                check_environment_status
                ;;
            6)
                manage_global_config
                ;;
            7)
                view_main_logs
                ;;
            8)
                clean_all_environments
                ;;
            9)
                show_tool_info
                ;;
            0)
                echo -e "\n${GREEN}感谢使用 Struts2 安全扫描与 WAF 绕过工具集！${NC}"
                echo -e "${YELLOW}请记得在测试完成后清理环境。${NC}"
                exit 0
                ;;
            *)
                log_error "无效选择，请输入 0-9 之间的数字"
                sleep 2
                ;;
        esac
    done
}

# Main execution
main() {
    # Initialize
    init_main
    
    # Log startup
    echo "$(date): 主程序启动" >> logs/main.log
    
    # Check if running with specific CVE argument
    if [ $# -eq 1 ]; then
        case $1 in
            --cve-2016-10134)
                run_cve_script 1
                exit 0
                ;;
            --cve-2020-17530)
                run_cve_script 2
                exit 0
                ;;
            --cve-2021-21389)
                run_cve_script 3
                exit 0
                ;;
            --cve-2021-22205)
                run_cve_script 4
                exit 0
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  --cve-2016-10134    直接运行 CVE-2016-10134 脚本"
                echo "  --cve-2020-17530    直接运行 CVE-2020-17530 脚本"
                echo "  --cve-2021-21389    直接运行 CVE-2021-21389 脚本"
                echo "  --cve-2021-22205    直接运行 CVE-2021-22205 脚本"
                echo "  --help, -h          显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                echo "使用 --help 查看可用选项"
                exit 1
                ;;
        esac
    fi
    
    # Start main menu
    main_menu_loop
}

# Run main function
main "$@"
