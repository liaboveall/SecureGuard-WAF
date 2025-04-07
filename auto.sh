#!/bin/bash
# 增加更严格的错误处理
set -eo pipefail

# 增强的颜色配置
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RED='\033[1;31m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m'

# 显示醒目的启动横幅
show_banner() {
  clear
  echo -e "${BLUE}"
  echo -e "╔══════════════════════════════════════════════════════════════╗"
  echo -e "║                                                              ║"
  echo -e "║  ${YELLOW}█▀ █▀▀ █▀▀ █ █ █▀█ █ ▀█▀ █▄█   █▀ █ █ █ █▀▀ █   █▀▄${BLUE}  ║"
  echo -e "║  ${YELLOW}▄█ ██▄ █▄▄ █▄█ █▀▄ █  █   █    ▄█ █▀█ █ ██▄ █▄▄ █▄▀${BLUE}  ║"
  echo -e "║                                                              ║"
  echo -e "║             ${GREEN}ModSecurity WAF 自动化防护部署工具${BLUE}             ║"
  echo -e "║                                                              ║"
  echo -e "║  ${CYAN}[ Struts2 漏洞防护 ]        [ CVE-2020-17530 ]${BLUE}            ║"
  echo -e "║                                                              ║"
  echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
  echo -e ""
  echo -e "${DIM}Version 2.1.0 - 持续安全防护${NC}"
  echo -e ""
}

# 添加进度显示函数
show_progress() {
  local step=$1
  local total=$2
  local title=$3
  local width=50
  local percent=$((step * 100 / total))
  local completed=$((width * step / total))
  local remaining=$((width - completed))
  
  printf "${BOLD}[%2d%%]${NC} ${CYAN}%s${NC}\n" $percent "$title"
  printf "[${GREEN}"
  for ((i=0; i<completed; i++)); do printf "▓"; done
  printf "${YELLOW}"
  for ((i=0; i<remaining; i++)); do printf "░"; done
  printf "${NC}] ${step}/${total}\n\n"
}

# 启动确认和交互
confirm_start() {
  echo -e "${YELLOW}此工具将自动检测并防护 Struts2 漏洞容器${NC}"
  echo -e "操作将包括:"
  echo -e " ${BLUE}•${NC} 检测运行中的漏洞容器"
  echo -e " ${BLUE}•${NC} 部署 ModSecurity WAF 防护层"
  echo -e " ${BLUE}•${NC} 配置网络流量重定向"
  echo -e " ${BLUE}•${NC} 生成防御规则和监控工具\n"
  
  read -p "是否继续? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}操作已取消${NC}"
    exit 0
  fi
  echo
}

# 错误处理和清理函数
cleanup() {
  echo -e "\n${YELLOW}执行清理操作...${NC}"
  # 移除可能的stale iptables规则
  if [ ! -z "$HOST_PORT" ] && [ ! -z "$MODSEC_HOST_PORT" ]; then
    sudo iptables -t nat -D PREROUTING -p tcp --dport "$HOST_PORT" -j REDIRECT --to-port "$MODSEC_HOST_PORT" 2>/dev/null || true
  fi
  echo -e "${GREEN}清理完成${NC}"
}

# 捕获错误，添加更友好的错误提示
trap 'echo -e "\n${RED}╔════════════════════════╗\n║ 错误: 脚本执行失败! ║\n╚════════════════════════╝${NC}\n详细位置: 第 $LINENO 行\n"; cleanup; exit 1' ERR

# 增强的终端通知功能
notify() {
  local type=$1
  local message=$2
  
  case $type in
    "info")
      echo -e "${BLUE}ℹ ${NC}${message}"
      ;;
    "success")
      echo -e "${GREEN}✓ ${NC}${message}"
      ;;
    "warning")
      echo -e "${YELLOW}⚠ ${NC}${message}"
      ;;
    "error")
      echo -e "${RED}✗ ${NC}${message}"
      ;;
    *)
      echo -e "${message}"
      ;;
  esac
}

# 确保依赖命令存在，增加视觉反馈
check_dependencies() {
  echo -e "${UNDERLINE}检查系统依赖${NC}"
  local missing=0
  
  for cmd in docker sudo grep iptables curl; do
    printf "  检查 %-10s ... " "$cmd"
    if command -v $cmd &> /dev/null; then
      echo -e "${GREEN}已安装${NC}"
    else
      echo -e "${RED}未安装${NC}"
      missing=1
    fi
  done
  
  if [ $missing -eq 1 ]; then
    echo -e "\n${RED}错误: 缺少必要命令，请安装缺失的依赖${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✓ 所有依赖检查通过${NC}\n"
}

# 端口检测函数
get_container_port() {
  local container_id=$1
  local port

  # 方法1: 从Docker直接获取端口映射
  port=$(docker ps --filter "id=$container_id" --format "{{.Ports}}" | grep -oE '[0-9]+->8080' | grep -oE '[0-9]+' | head -n 1)
  
  # 方法2: 使用inspect命令
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -eq 0 ]; then
    port=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{with index $conf 0}}{{if eq $p "8080/tcp"}}{{.HostPort}}{{end}}{{end}}{{end}}' $container_id)
  fi

  # 验证并返回
  if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ne 0 ]; then
    echo $port
  else
    echo ""
  fi
}

# 主执行流程
main() {
  # 显示欢迎横幅
  show_banner
  
  # 交互确认
  confirm_start
  
  # 检查依赖
  check_dependencies
  
  # 逐步执行任务并显示进度
  echo -e "${UNDERLINE}${BOLD}开始自动防护流程${NC}\n"
  
  # 步骤1: 扫描漏洞容器
  show_progress 1 6 "扫描 Struts2 漏洞容器"
  # 通过镜像名称查找容器
  VULN_CONTAINER_INFO=$(docker ps --filter "ancestor=vulfocus/struts2-cve_2020_17530:latest" --format "{{.ID}}:{{.Names}}:{{.Ports}}")

  if [ -z "$VULN_CONTAINER_INFO" ]; then
    notify "error" "未找到运行的Struts2漏洞容器"
    exit 1
  fi

  # 解析容器信息
  CONTAINER_ID=$(echo $VULN_CONTAINER_INFO | cut -d: -f1)
  CONTAINER_NAME=$(echo $VULN_CONTAINER_INFO | cut -d: -f2)

  # 使用优化后的端口检测函数
  HOST_PORT=$(get_container_port $CONTAINER_ID)

  # 最终验证
  if [ -z "$HOST_PORT" ]; then
    notify "warning" "无法自动检测端口，使用默认端口"
    HOST_PORT=28014
  fi

  echo -e "${CYAN}◉ 发现漏洞容器：${NC}"
  echo -e "  ${BLUE}├─ 容器ID${NC}: ${YELLOW}$CONTAINER_ID${NC}"
  echo -e "  ${BLUE}├─ 容器名称${NC}: ${YELLOW}$CONTAINER_NAME${NC}"
  echo -e "  ${BLUE}└─ 映射端口${NC}: ${YELLOW}$HOST_PORT${NC}\n"
  
  # 配置参数
  MODSEC_CONTAINER_NAME="modsec_guard_${CONTAINER_ID:0:6}"
  MODSEC_HOST_PORT=$((HOST_PORT + 10000))  # 生成唯一防护端口
  CONFIG_DIR="./shield_config_${CONTAINER_ID:0:6}"

  # 步骤2: 准备安全环境
  show_progress 2 6 "准备安全环境"
  # 清理旧配置
  docker rm -f $MODSEC_CONTAINER_NAME 2>/dev/null || true
  rm -rf $CONFIG_DIR
  notify "success" "环境准备完成"
  
  # 步骤3：生成防护规则
  show_progress 3 6 "生成防护规则"
  mkdir -p $CONFIG_DIR/{nginx,modsec}

  # 获取容器内部IP
  VULN_INTERNAL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_ID)
  notify "info" "漏洞容器内部IP: $VULN_INTERNAL_IP"
  
  # 生成Nginx配置
  cat > $CONFIG_DIR/nginx/app.conf <<EOF
server {
    listen 80;
    modsecurity on;
    modsecurity_rules_file /etc/modsecurity/main.conf;

    # 反向代理配置
    location / {
        proxy_pass http://$VULN_INTERNAL_IP:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # 连接优化
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffers 16 4k;
        proxy_buffer_size 2k;
    }

    # 自定义错误页面
    error_page 403 /blocked.html;
    location = /blocked.html {
        internal;
        add_header Content-Type application/json;
        return 403 '{"status":"blocked","reason":"Potential Attack Detected","code":"SEC-1000"}';
    }
    
    # 健康检查路径
    location /health {
        access_log off;
        return 200 'OK';
    }
}
EOF

  # 创建基础 ModSecurity 配置文件 - 修复注释格式问题
  cat > $CONFIG_DIR/modsec/modsecurity.conf <<EOF
# 基础 ModSecurity 配置
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml application/json
SecResponseBodyLimit 1024
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus "^(?:5|4(?!04))"
SecAuditLogParts ABIJDEFHZ
SecAuditLogType Serial
SecAuditLog /var/log/modsec_audit.log

# 避免影响Struts2特定规则
SecRuleRemoveById 942100-942999
EOF

  # 生成增强型ModSecurity规则
  cat > $CONFIG_DIR/modsec/main.conf <<EOF
# 包含自定义的基础配置
Include /etc/modsecurity/modsecurity.conf

SecRuleEngine On
SecRequestBodyAccess On

# === Struts2 OGNL注入防护规则 ===
# -----------------------------------------------------------------------
# 规则集说明：
# 这组规则专门用于防御Struts2框架中的OGNL表达式注入漏洞，特别是CVE-2020-17530
# OGNL (Object-Graph Navigation Language)是Struts2使用的表达式语言，
# 攻击者可利用OGNL注入执行任意代码或命令。
# -----------------------------------------------------------------------

# 规则ID: 1001 - 基本OGNL表达式检测
# 目的: 检测并阻止包含OGNL表达式基本特征的请求
# 工作原理: 识别包含${}这一OGNL表达式标志的参数
# 防护效果: 可拦截如\${123*456}、\${@java.lang.Runtime@getRuntime()}等表达式
# 攻击示例: name=\${7*7}、param=\${@java.lang.System@getProperty('user.dir')}
SecRule ARGS "@contains \${" \
    "id:1001,\
    phase:2,\
    deny,\
    status:403,\
    msg:'Basic OGNL Injection Attempt',\
    logdata:'Matched Data: %{MATCHED_VAR}'"

# 规则ID: 1002 - OGNL关键词检测
# 目的: 检测请求中包含"ognl"关键词，这通常表示攻击者在尝试OGNL注入
# 工作原理: 查找所有参数中是否出现"ognl"字符串
# 防护效果: 可拦截显式使用ognl命名空间或表达式的攻击
# 攻击示例: payload=%{#ognl.findValue}、data=ognl://@java.lang.Runtime
SecRule ARGS "@contains ognl" \
    "id:1002,\
    phase:2,\
    deny,\
    status:403,\
    msg:'OGNL Keyword Detected',\
    logdata:'Matched Data: %{MATCHED_VAR}'"
EOF


  # 创建空的 rules 目录，以便 Include 语句不会失败
  mkdir -p $CONFIG_DIR/modsec/rules
  notify "success" "已生成 ModSecurity 规则配置"
  
  # 优化后的测试脚本
  cat > $CONFIG_DIR/test.sh <<EOF
#!/bin/bash
# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}╔════════════════════════════════════╗"
echo -e "║     ModSecurity 安全测试工具     ║"
echo -e "╚════════════════════════════════════╝${NC}\n"

# 显示测试进度
progress() {
  local msg="\$1"
  echo -en "${BLUE}[测试]${NC} \$msg ... "
}

# 创建测试结果表格的顶部
echo -e "${BOLD}开始执行安全测试套件${NC}\n"

echo -e "${YELLOW}┌────────────────────────┬───────────┬─────────────────┐"
echo -e "│ 测试类型               │ 状态      │ 详细信息        │"
echo -e "├────────────────────────┼───────────┼─────────────────┤${NC}"

# 测试1: 检查服务可访问性
progress "检查服务可访问性"
RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$HOST_PORT" 2>/dev/null)
if [[ "\$RESPONSE" =~ ^[23] ]]; then
  echo -e "${GREEN}成功${NC}"
  echo -e "${YELLOW}│${NC} 基础可访问性测试       ${YELLOW}│${NC} ${GREEN}✓ 通过${NC}    ${YELLOW}│${NC} HTTP \$RESPONSE       ${YELLOW}│${NC}"
else
  echo -e "${RED}失败${NC}"
  echo -e "${YELLOW}│${NC} 基础可访问性测试       ${YELLOW}│${NC} ${RED}✗ 失败${NC}    ${YELLOW}│${NC} HTTP \$RESPONSE       ${YELLOW}│${NC}"
fi

# 测试2: OGNL表达式攻击
progress "测试OGNL表达式攻击防御"
RESPONSE=\$(curl -s -X POST "http://localhost:$HOST_PORT" -d 'name=\${233*233}' -w "%{http_code}" -o /dev/null 2>/dev/null)
if [ "\$RESPONSE" == "403" ]; then
  echo -e "${GREEN}拦截成功${NC}"
  echo -e "${YELLOW}│${NC} OGNL表达式攻击测试     ${YELLOW}│${NC} ${GREEN}✓ 拦截${NC}    ${YELLOW}│${NC} HTTP 403         ${YELLOW}│${NC}"
else
  echo -e "${RED}拦截失败${NC}"
  echo -e "${YELLOW}│${NC} OGNL表达式攻击测试     ${YELLOW}│${NC} ${RED}✗ 未拦截${NC}  ${YELLOW}│${NC} HTTP \$RESPONSE       ${YELLOW}│${NC}"
fi

# 测试3: 命令执行攻击
progress "测试命令执行攻击防御"
RESPONSE=\$(curl -s "http://localhost:$HOST_PORT/?cmd=\${%23a%3d(new%20java.lang.ProcessBuilder(new%20java.lang.String[]{'id'})).start()}" -w "%{http_code}" -o /dev/null 2>/dev/null)
if [ "\$RESPONSE" == "403" ]; then
  echo -e "${GREEN}拦截成功${NC}"
  echo -e "${YELLOW}│${NC} 命令执行攻击测试       ${YELLOW}│${NC} ${GREEN}✓ 拦截${NC}    ${YELLOW}│${NC} HTTP 403         ${YELLOW}│${NC}"
else
  echo -e "${RED}拦截失败${NC}"
  echo -e "${YELLOW}│${NC} 命令执行攻击测试       ${YELLOW}│${NC} ${RED}✗ 未拦截${NC}  ${YELLOW}│${NC} HTTP \$RESPONSE       ${YELLOW}│${NC}"
fi

# 测试4: 防护系统状态
progress "检查防护系统状态"
if docker ps | grep -q "$MODSEC_CONTAINER_NAME"; then
  echo -e "${GREEN}正常${NC}"
  echo -e "${YELLOW}│${NC} 防护系统状态检查       ${YELLOW}│${NC} ${GREEN}✓ 正常${NC}    ${YELLOW}│${NC} 容器运行中       ${YELLOW}│${NC}"
else
  echo -e "${RED}异常${NC}"
  echo -e "${YELLOW}│${NC} 防护系统状态检查       ${YELLOW}│${NC} ${RED}✗ 异常${NC}    ${YELLOW}│${NC} 容器未运行       ${YELLOW}│${NC}"
fi

echo -e "${YELLOW}└────────────────────────┴───────────┴─────────────────┘${NC}"

# 测试总结
echo -e "\n${BOLD}测试完成，请查看结果摘要:${NC}"
TOTAL_PASSED=\$(echo -e "\$RESULTS" | grep -c "通过\|拦截\|正常")
echo -e "  ${GREEN}● 通过测试: \$TOTAL_PASSED${NC}"
TOTAL_FAILED=\$(echo -e "\$RESULTS" | grep -c "失败\|未拦截\|异常")
echo -e "  ${RED}● 失败测试: \$TOTAL_FAILED${NC}"

# 提供后续操作建议
echo -e "\n${CYAN}推荐操作:${NC}"
echo -e "  1. 查看ModSecurity日志: docker logs $MODSEC_CONTAINER_NAME"
echo -e "  2. 检查防护状态: $CONFIG_DIR/monitor.sh"
echo -e "  3. 查看拦截规则: cat $CONFIG_DIR/modsec/main.conf"
EOF
  chmod +x $CONFIG_DIR/test.sh
  
  # 优化后的监控脚本
  cat > $CONFIG_DIR/monitor.sh <<EOF
#!/bin/bash
# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}╔════════════════════════════════════╗"
echo -e "║   ModSecurity 防护状态监控面板   ║"
echo -e "╚════════════════════════════════════╝${NC}\n"

# 容器状态监控
CONTAINER_STATUS=\$(docker inspect -f '{{.State.Status}}' $MODSEC_CONTAINER_NAME 2>/dev/null || echo "stopped")
UPTIME=\$(docker inspect -f '{{.State.StartedAt}}' $MODSEC_CONTAINER_NAME 2>/dev/null | xargs -I{} date -d {} +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知")
NOW=\$(date +"%Y-%m-%d %H:%M:%S")

echo -e "${BOLD}系统基本信息:${NC}"
echo -e "  ${BLUE}● 当前时间:${NC} \$NOW"
echo -e "  ${BLUE}● 启动时间:${NC} \$UPTIME"
echo -e "  ${BLUE}● 监控对象:${NC} $MODSEC_CONTAINER_NAME (防护 → $HOST_PORT 端口)"

echo -e "\n${BOLD}防护状态监控:${NC}"
if [ "\$CONTAINER_STATUS" == "running" ]; then
  echo -e "  ${GREEN}● 容器状态:${NC} 正常运行中 ${GREEN}■${NC}"
  
  # 收集性能指标
  CPU=\$(docker stats $MODSEC_CONTAINER_NAME --no-stream --format "{{.CPUPerc}}" 2>/dev/null || echo "N/A")
  MEM=\$(docker stats $MODSEC_CONTAINER_NAME --no-stream --format "{{.MemPerc}}" 2>/dev/null || echo "N/A")
  echo -e "  ${BLUE}● 资源使用:${NC} CPU: \$CPU | 内存: \$MEM"
  
  # 检查最近的拦截
  BLOCKS_1M=\$(docker logs --since=1m $MODSEC_CONTAINER_NAME 2>&1 | grep -c "id \"100")
  BLOCKS_5M=\$(docker logs --since=5m $MODSEC_CONTAINER_NAME 2>&1 | grep -c "id \"100")
  BLOCKS_1H=\$(docker logs --since=1h $MODSEC_CONTAINER_NAME 2>&1 | grep -c "id \"100")
  
  echo -e "  ${BLUE}● 攻击拦截统计:${NC}"
  echo -e "    - 最近1分钟: ${YELLOW}\$BLOCKS_1M${NC} 次拦截"
  echo -e "    - 最近5分钟: ${YELLOW}\$BLOCKS_5M${NC} 次拦截"
  echo -e "    - 最近1小时: ${YELLOW}\$BLOCKS_1H${NC} 次拦截"
  
  # 验证端口重定向是否有效
  echo -e "  ${BLUE}● 网络重定向状态:${NC}"
  if sudo iptables -t nat -C PREROUTING -p tcp --dport $HOST_PORT -j REDIRECT --to-port $MODSEC_HOST_PORT 2>/dev/null; then
    echo -e "    ${GREEN}✓ 网络重定向已正确配置${NC}"
    echo -e "    - 原端口 $HOST_PORT ${GREEN}→${NC} 防护端口 $MODSEC_HOST_PORT"
  else
    echo -e "    ${RED}✗ 网络重定向配置异常${NC}"
    echo -e "    ${YELLOW}● 建议操作:${NC} 执行以下命令重新配置重定向"
    echo -e "      sudo iptables -t nat -A PREROUTING -p tcp --dport $HOST_PORT -j REDIRECT --to-port $MODSEC_HOST_PORT"
  fi

  # 展示最近拦截的攻击详情
  if [ \$BLOCKS_5M -gt 0 ]; then
    echo -e "\n${BOLD}最近拦截的攻击样本:${NC}"
    docker logs --since=5m $MODSEC_CONTAINER_NAME 2>&1 | grep -B 2 -A 2 "id \"100" | head -n 15 | while read line; do
      echo -e "  ${YELLOW}|${NC} \$line"
    done
  fi
  
  # 健康检查
  echo -e "\n${BOLD}系统健康状态:${NC}"
  curl -s http://localhost:$MODSEC_HOST_PORT/health >/dev/null 2>&1
  if [ \$? -eq 0 ]; then
    echo -e "  ${GREEN}✓ 服务健康检查: 正常${NC}"
  else
    echo -e "  ${RED}✗ 服务健康检查: 异常${NC}"
  fi
  
else
  echo -e "  ${RED}✗ 容器状态:${NC} 未运行 ${RED}■${NC}"
  echo -e "  ${YELLOW}● 建议操作:${NC} 执行以下命令启动防护容器"
  echo -e "    docker start $MODSEC_CONTAINER_NAME"
fi

# 实用操作建议
echo -e "\n${CYAN}┌─ 可用操作 ────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC} 1. 查看详细日志: docker logs $MODSEC_CONTAINER_NAME ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} 2. 重启防护: docker restart $MODSEC_CONTAINER_NAME ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} 3. 运行测试: $CONFIG_DIR/test.sh       ${CYAN}│${NC}"
echo -e "${CYAN}└────────────────────────────────────────────┘${NC}"
EOF
  chmod +x $CONFIG_DIR/monitor.sh
  
  # 步骤4: 部署防护系统
  show_progress 4 6 "部署 ModSecurity 防护系统"
  docker run -d \
    --name $MODSEC_CONTAINER_NAME \
    --user root \
    -p $MODSEC_HOST_PORT:80 \
    -v $PWD/$CONFIG_DIR/nginx:/etc/nginx/conf.d \
    -v $PWD/$CONFIG_DIR/modsec:/etc/modsecurity \
    --restart unless-stopped \
    --network bridge \
    owasp/modsecurity:nginx
    
  notify "success" "防护容器已启动: $MODSEC_CONTAINER_NAME"
  
  # 步骤5: 配置网络防护
  show_progress 5 6 "配置网络防护与流量重定向"
  sleep 3  # 等待防护容器启动
  notify "info" "配置端口重定向: $HOST_PORT → $MODSEC_HOST_PORT"
  sudo iptables -t nat -A PREROUTING \
    -p tcp --dport "$HOST_PORT" \
    -j REDIRECT --to-port "$MODSEC_HOST_PORT"
  notify "success" "流量重定向规则已配置"
  
  # 步骤6: 验证防护系统
  show_progress 6 6 "验证防护系统状态"
  sleep 2

  # 检查ModSecurity容器状态
  if [ "$(docker inspect -f '{{.State.Running}}' $MODSEC_CONTAINER_NAME 2>/dev/null)" != "true" ]; then
    notify "error" "ModSecurity容器未正常运行"
    docker logs --tail 10 $MODSEC_CONTAINER_NAME
    exit 1
  fi

  # 检查iptables规则是否生效
  if ! sudo iptables -t nat -C PREROUTING -p tcp --dport $HOST_PORT -j REDIRECT --to-port $MODSEC_HOST_PORT 2>/dev/null; then
    notify "warning" "iptables规则未正确应用"
    echo -e "请手动执行: sudo iptables -t nat -A PREROUTING -p tcp --dport $HOST_PORT -j REDIRECT --to-port $MODSEC_HOST_PORT"
  fi
  
  # 显示新的完成界面
  echo -e "\n${GREEN}╔═══════════════════════════════════════════════════╗"
  echo -e "║               防护部署成功                      ║"
  echo -e "╚═══════════════════════════════════════════════════╝${NC}\n"
  
  echo -e "${CYAN}◉ 部署信息:${NC}"
  echo -e "  ${BLUE}├─ 靶标容器ID   ${NC}: ${YELLOW}${CONTAINER_ID}${NC}"
  echo -e "  ${BLUE}├─ 原始漏洞端口 ${NC}: ${YELLOW}${HOST_PORT}${NC}"
  echo -e "  ${BLUE}├─ 防护代理端口 ${NC}: ${YELLOW}${MODSEC_HOST_PORT}${NC}"
  echo -e "  ${BLUE}├─ 防护容器名称 ${NC}: ${YELLOW}${MODSEC_CONTAINER_NAME}${NC}"
  echo -e "  ${BLUE}└─ 规则目录     ${NC}: ${YELLOW}${CONFIG_DIR}${NC}\n"

  echo -e "${MAGENTA}◉ 实用命令:${NC}"
  echo -e "  ${BOLD}测试正常访问${NC}: curl -s http://localhost:${HOST_PORT} | head -n 5"
  echo -e "  ${BOLD}测试攻击拦截${NC}: curl -X POST http://localhost:${HOST_PORT} -d 'name=\${233*233}'"
  echo -e "  ${BOLD}查看防护日志${NC}: docker logs ${MODSEC_CONTAINER_NAME} | grep 'id \"100\"'"
  echo -e "  ${BOLD}运行安全测试${NC}: ${CONFIG_DIR}/test.sh"
  echo -e "  ${BOLD}查看防护状态${NC}: ${CONFIG_DIR}/monitor.sh"
  
  # 提供选项菜单
  echo -e "\n${YELLOW}您想现在执行哪个操作?${NC}"
  echo -e "  1) 运行安全测试"
  echo -e "  2) 查看防护状态"
  echo -e "  3) 查看防护日志"
  echo -e "  4) 退出"
  read -p "请选择 [1-4]: " choice
  
  case $choice in
    1) ${CONFIG_DIR}/test.sh ;;
    2) ${CONFIG_DIR}/monitor.sh ;;
    3) docker logs ${MODSEC_CONTAINER_NAME} | grep 'id \"100\"' ;;
    *) echo -e "${GREEN}防护已成功部署，感谢使用!${NC}" ;;
  esac
}

# 执行主函数
main