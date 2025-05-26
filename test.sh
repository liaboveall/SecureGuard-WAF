#!/bin/bash

# 🔧 项目测试脚本
# 用于验证所有组件是否正常工作

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
PASSED=0
FAILED=0

# 测试函数
test_function() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "测试 $test_name ... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ 通过${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ 失败${NC}"
        ((FAILED++))
    fi
}

# 开始测试
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         项目组件测试脚本               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

# 1. 测试文件结构
echo -e "${YELLOW}🔍 检查项目文件结构...${NC}"
test_function "主控制脚本" "[ -f '$SCRIPT_DIR/main.sh' ]"
test_function "全局配置文件" "[ -f '$SCRIPT_DIR/config/global.conf' ]"
test_function "通用工具库" "[ -f '$SCRIPT_DIR/utils/common.sh' ]"
test_function "CVE-2016-10134脚本" "[ -f '$SCRIPT_DIR/scripts/cve-2016-10134.sh' ]"
test_function "CVE-2020-17530脚本" "[ -f '$SCRIPT_DIR/scripts/cve-2020-17530.sh' ]"
test_function "CVE-2021-21389脚本" "[ -f '$SCRIPT_DIR/scripts/cve-2021-21389.sh' ]"
test_function "CVE-2021-22205脚本" "[ -f '$SCRIPT_DIR/scripts/cve-2021-22205.sh' ]"
test_function "README文档" "[ -f '$SCRIPT_DIR/README.md' ]"
test_function "LICENSE文件" "[ -f '$SCRIPT_DIR/LICENSE' ]"

echo ""

# 2. 测试脚本语法
echo -e "${YELLOW}📝 检查脚本语法...${NC}"
test_function "主控制脚本语法" "bash -n '$SCRIPT_DIR/main.sh'"
test_function "通用工具库语法" "bash -n '$SCRIPT_DIR/utils/common.sh'"
test_function "CVE-2016-10134语法" "bash -n '$SCRIPT_DIR/scripts/cve-2016-10134.sh'"
test_function "CVE-2020-17530语法" "bash -n '$SCRIPT_DIR/scripts/cve-2020-17530.sh'"
test_function "CVE-2021-21389语法" "bash -n '$SCRIPT_DIR/scripts/cve-2021-21389.sh'"
test_function "CVE-2021-22205语法" "bash -n '$SCRIPT_DIR/scripts/cve-2021-22205.sh'"

echo ""

# 3. 测试配置文件
echo -e "${YELLOW}⚙️ 检查配置文件...${NC}"
test_function "全局配置可读取" "source '$SCRIPT_DIR/config/global.conf'"
test_function "工具库可加载" "source '$SCRIPT_DIR/utils/common.sh'"

echo ""

# 4. 测试系统依赖
echo -e "${YELLOW}🛠️ 检查系统依赖...${NC}"
test_function "Docker已安装" "command -v docker"
test_function "Docker Compose已安装" "docker compose version || docker-compose version"
test_function "curl已安装" "command -v curl"
test_function "grep已安装" "command -v grep"
test_function "awk已安装" "command -v awk"

echo ""

# 5. 测试目录权限
echo -e "${YELLOW}🔐 检查目录权限...${NC}"
test_function "config目录可读" "[ -r '$SCRIPT_DIR/config' ]"
test_function "scripts目录可读" "[ -r '$SCRIPT_DIR/scripts' ]"
test_function "utils目录可读" "[ -r '$SCRIPT_DIR/utils' ]"
test_function "logs目录可写" "[ -w '$SCRIPT_DIR/logs' ] || mkdir -p '$SCRIPT_DIR/logs'"

echo ""

# 显示测试结果
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║             测试结果统计               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo -e "通过测试: ${GREEN}$PASSED${NC}"
echo -e "失败测试: ${RED}$FAILED${NC}"
echo -e "总计测试: $((PASSED + FAILED))"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 所有测试通过！项目已准备好使用${NC}"
    echo -e "${BLUE}🚀 运行 './main.sh' 开始使用工具${NC}"
else
    echo ""
    echo -e "${RED}❌ 有 $FAILED 个测试失败，请检查上述问题${NC}"
    exit 1
fi
