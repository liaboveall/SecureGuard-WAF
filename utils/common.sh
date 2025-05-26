#!/bin/bash

# =============================================================================
# Struts2-scan-and-WAF 通用工具函数库
# 包含颜色定义、日志函数、Docker 操作、网络配置等通用功能
# =============================================================================

# 加载配置文件
load_config() {
    local config_file="${1:-./config/global.conf}"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_info "配置文件已加载: $config_file"
    else
        log_error "配置文件不存在: $config_file"
        exit 1
    fi
}

# =============================================================================
# 颜色定义
# =============================================================================

# 基础颜色
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'

# 增强样式
export BOLD='\033[1m'
export DIM='\033[2m'
export UNDERLINE='\033[4m'
export BLINK='\033[5m'
export REVERSE='\033[7m'

# 重置颜色
export NC='\033[0m'

# 检查终端颜色支持
check_color_support() {
    if ! tput setaf 1 >&/dev/null; then
        RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE=''
        BOLD='' DIM='' UNDERLINE='' BLINK='' REVERSE='' NC=''
        log_warning "终端不支持颜色，使用纯文本输出"
    fi
}

# =============================================================================
# 日志和输出函数
# =============================================================================

# 获取时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 日志输出到文件
log_to_file() {
    local message="$1"
    local log_file="${LOG_DIR:-./logs}/$(date '+%Y%m%d').log"
    
    # 确保日志目录存在
    mkdir -p "$(dirname "$log_file")"
    
    echo "[$(get_timestamp)] $message" >> "$log_file"
}

# 成功信息
log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    log_to_file "SUCCESS: $message"
}

# 信息输出
log_info() {
    local message="$1"
    echo -e "${CYAN}[INFO]${NC} $message"
    log_to_file "INFO: $message"
}

# 警告信息
log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    log_to_file "WARNING: $message"
}

# 错误信息
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2
    log_to_file "ERROR: $message"
}

# 调试信息
log_debug() {
    local message="$1"
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        echo -e "${DIM}[DEBUG]${NC} $message"
        log_to_file "DEBUG: $message"
    fi
}

# 显示标题横幅
print_header() {
    local title="$1"
    local length=${#title}
    local line=$(printf '%*s' $((length + 20)) | tr ' ' '=')
    
    echo -e "\n${BLUE}$line${NC}"
    echo -e "${BLUE}          $title          ${NC}"
    echo -e "${BLUE}$line${NC}\n"
}

# 显示子标题
print_subheader() {
    local subtitle="$1"
    echo -e "\n${YELLOW}>>> $subtitle${NC}\n"
}

# 显示进度条
show_progress() {
    local current=$1
    local total=$2
    local title="$3"
    local width=50
    local percent=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${BOLD}[%3d%%]${NC} ${CYAN}%s${NC} [" "$percent" "$title"
    printf "${GREEN}%*s${NC}" "$completed" | tr ' ' '▓'
    printf "${DIM}%*s${NC}" "$remaining" | tr ' ' '░'
    printf "]"
    
    if [[ $current -eq $total ]]; then
        echo # 换行
    fi
}

# =============================================================================
# 用户交互函数
# =============================================================================

# 确认操作
ask_confirmation() {
    local prompt_message="$1"
    local default="${2:-n}"
    local choice
    
    while true; do
        if [[ "$default" == "y" ]]; then
            echo -en "${YELLOW}[PROMPT]${NC} $prompt_message (Y/n): "
        else
            echo -en "${YELLOW}[PROMPT]${NC} $prompt_message (y/N): "
        fi
        
        read -r choice
        choice=${choice:-$default}
        
        case "$choice" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) log_error "无效输入，请输入 y 或 n" ;;
        esac
    done
}

# 选择菜单
select_option() {
    local title="$1"
    shift
    local options=("$@")
    local choice
    
    echo -e "\n${CYAN}$title${NC}"
    for i in "${!options[@]}"; do
        echo "  $((i + 1)). ${options[i]}"
    done
    
    while true; do
        echo -en "\n${YELLOW}请选择 (1-${#options[@]}): ${NC}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
            return $((choice - 1))
        else
            log_error "无效选择，请输入 1-${#options[@]} 之间的数字"
        fi
    done
}

# =============================================================================
# 系统检查函数
# =============================================================================

# 检查命令是否存在
check_command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "命令 '$cmd' 未找到，请安装 $package"
        return 1
    fi
    return 0
}

# 检查必需的依赖
check_dependencies() {
    local deps=("docker" "docker-compose" "curl" "jq")
    local missing=()
    
    log_info "检查依赖项..."
    
    for dep in "${deps[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "缺少以下依赖项: ${missing[*]}"
        log_info "请安装缺失的依赖项后重新运行脚本"
        return 1
    fi
    
    log_success "所有依赖项检查通过"
    return 0
}

# 检查 Docker 服务状态
check_docker_status() {
    if ! docker info &> /dev/null; then
        log_error "Docker 服务未运行，请启动 Docker 服务"
        return 1
    fi
    log_success "Docker 服务运行正常"
    return 0
}

# 检查端口是否被占用
check_port() {
    local port="$1"
    local service_name="${2:-服务}"
    
    if lsof -Pi :$port -sTCP:LISTEN -t &> /dev/null; then
        log_warning "端口 $port 已被占用"
        return 1
    fi
    log_debug "端口 $port 可用"
    return 0
}

# =============================================================================
# Docker 操作函数
# =============================================================================

# 检查容器是否存在
container_exists() {
    local container_name="$1"
    docker ps -a --format "table {{.Names}}" | grep -q "^$container_name$"
}

# 检查容器是否运行
container_running() {
    local container_name="$1"
    docker ps --format "table {{.Names}}" | grep -q "^$container_name$"
}

# 停止并删除容器
remove_container() {
    local container_name="$1"
    
    if container_running "$container_name"; then
        log_info "停止容器: $container_name"
        docker stop "$container_name" || true
    fi
    
    if container_exists "$container_name"; then
        log_info "删除容器: $container_name"
        docker rm "$container_name" || true
    fi
}

# 等待容器启动
wait_for_container() {
    local container_name="$1"
    local timeout="${2:-60}"
    local interval="${3:-5}"
    local elapsed=0
    
    log_info "等待容器 $container_name 启动..."
    
    while [[ $elapsed -lt $timeout ]]; do
        if container_running "$container_name"; then
            log_success "容器 $container_name 已启动"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -n "."
    done
    
    echo
    log_error "容器 $container_name 启动超时"
    return 1
}

# 检查容器健康状态
check_container_health() {
    local container_name="$1"
    local health_status
    
    if ! container_running "$container_name"; then
        log_error "容器 $container_name 未运行"
        return 1
    fi
    
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    
    case "$health_status" in
        "healthy")
            log_success "容器 $container_name 健康状态正常"
            return 0
            ;;
        "unhealthy")
            log_error "容器 $container_name 健康状态异常"
            return 1
            ;;
        "starting")
            log_info "容器 $container_name 正在启动中..."
            return 2
            ;;
        *)
            log_warning "容器 $container_name 无健康检查配置"
            return 0
            ;;
    esac
}

# =============================================================================
# 网络配置函数
# =============================================================================

# 创建 Docker 网络
create_docker_network() {
    local network_name="${1:-$DOCKER_NETWORK}"
    
    if ! docker network ls | grep -q "$network_name"; then
        log_info "创建 Docker 网络: $network_name"
        docker network create "$network_name" || {
            log_error "创建网络失败"
            return 1
        }
        log_success "网络 $network_name 创建成功"
    else
        log_info "网络 $network_name 已存在"
    fi
}

# 删除 Docker 网络
remove_docker_network() {
    local network_name="${1:-$DOCKER_NETWORK}"
    
    if docker network ls | grep -q "$network_name"; then
        log_info "删除 Docker 网络: $network_name"
        docker network rm "$network_name" 2>/dev/null || true
    fi
}

# 配置 iptables 重定向
setup_iptables_redirect() {
    local source_port="$1"
    local target_port="$2"
    
    if [[ "${ENABLE_IPTABLES_REDIRECT:-false}" == "true" ]]; then
        log_info "配置 iptables 重定向: $source_port -> $target_port"
        sudo iptables -t nat -A PREROUTING -p tcp --dport "$source_port" -j REDIRECT --to-port "$target_port" || {
            log_error "iptables 配置失败"
            return 1
        }
        log_success "iptables 重定向配置成功"
    fi
}

# 清理 iptables 规则
cleanup_iptables() {
    local source_port="$1"
    local target_port="$2"
    
    if [[ "${ENABLE_IPTABLES_REDIRECT:-false}" == "true" ]]; then
        log_info "清理 iptables 规则"
        sudo iptables -t nat -D PREROUTING -p tcp --dport "$source_port" -j REDIRECT --to-port "$target_port" 2>/dev/null || true
    fi
}

# =============================================================================
# 文件操作函数
# =============================================================================

# 备份文件
backup_file() {
    local file_path="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [[ -f "$file_path" ]]; then
        cp "$file_path" "${file_path}${backup_suffix}"
        log_info "文件已备份: ${file_path}${backup_suffix}"
    fi
}

# 创建目录（如果不存在）
ensure_directory() {
    local dir_path="$1"
    
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
        log_debug "创建目录: $dir_path"
    fi
}

# 生成随机字符串
generate_random_string() {
    local length="${1:-8}"
    tr -dc A-Za-z0-9 </dev/urandom | head -c "$length"
}

# =============================================================================
# 清理和错误处理函数
# =============================================================================

# 设置错误处理陷阱
setup_error_handling() {
    set -eE  # 启用错误时退出和错误继承
    trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "%s " ${FUNCNAME[@]})' ERR
}

# 错误处理器
error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_stack=($5)
    
    log_error "脚本执行失败!"
    log_error "退出码: $exit_code"
    log_error "行号: $line_no"
    log_error "命令: $last_command"
    
    if [[ ${#func_stack[@]} -gt 1 ]]; then
        log_error "函数调用栈: ${func_stack[*]}"
    fi
    
    # 执行清理操作
    cleanup
}

# 通用清理函数
cleanup() {
    log_info "执行清理操作..."
    
    # 这里可以添加具体的清理逻辑
    # 例如：停止容器、删除临时文件、恢复系统设置等
    
    log_info "清理完成"
}

# 设置退出陷阱
setup_exit_trap() {
    trap cleanup EXIT
}

# =============================================================================
# 报告生成函数
# =============================================================================

# 生成 HTML 报告
generate_html_report() {
    local report_title="$1"
    local report_file="${2:-./logs/report_$(date +%Y%m%d_%H%M%S).html}"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$report_title - 安全扫描报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #007cba; }
        .success { border-left-color: #28a745; }
        .warning { border-left-color: #ffc107; }
        .error { border-left-color: #dc3545; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>$report_title</h1>
        <p>生成时间: $(date)</p>
    </div>
EOF
    
    log_success "HTML 报告已生成: $report_file"
}

# =============================================================================
# 初始化函数
# =============================================================================

# 初始化环境
init_environment() {
    # 检查颜色支持
    check_color_support
    
    # 设置错误处理
    setup_error_handling
    setup_exit_trap
    
    # 创建必要的目录
    ensure_directory "${LOG_DIR:-./logs}"
    ensure_directory "${CONFIG_DIR:-./config}"
    ensure_directory "${TEMPLATE_DIR:-./templates}"
    
    log_info "环境初始化完成"
}

# 验证配置
validate_config() {
    local required_vars=("PROJECT_NAME" "LOG_DIR" "WAF_HOST_PORT")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "缺少必需的配置变量: ${missing_vars[*]}"
        return 1
    fi
    
    log_success "配置验证通过"
    return 0
}

# =============================================================================
# 导出函数供其他脚本使用
# =============================================================================

# 如果脚本被 source，则不执行主逻辑
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    log_debug "工具函数库已加载"
else
    log_info "这是一个函数库文件，请在其他脚本中 source 使用"
fi
