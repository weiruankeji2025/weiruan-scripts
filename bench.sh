#!/bin/bash

# =========================================================
# 脚本名称：威软科技 VPS 性能极速测试脚本 (WeiRuan Bench)
# 开发者：威软科技 (WeiRuan Technology)
# 版本：v1.0.0
# =========================================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
SKYBLUE='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- 辅助函数：绘制分割线 ---
draw_line() {
    printf "${CYAN}============================================================${NC}\n"
}

# --- 辅助函数：Logo 展示 ---
show_logo() {
    clear
    echo -e "${SKYBLUE}"
    echo "  __          __   _ _____                       "
    echo "  \ \        / /  (_)  __ \                      "
    echo "   \ \  /\  / /___ _| |__) |_   _  __ _ _ __     "
    echo "    \ \/  \/ / _ \ |  _  /| | | |/ _\` | '_ \    "
    echo "     \  /\  /  __/ | | \ \| |_| | (_| | | | |   "
    echo "      \/  \/ \___|_|_|  \_\\__,_|\__,_|_| |_|   "
    echo "                                                 "
    echo "          WeiRuan Technology - 威 软 科 技        "
    echo -e "${NC}"
    echo -e "${PURPLE}      >>> 正在初始化威软云端监测系统... <<< ${NC}"
    echo ""
    sleep 1
}

# --- 1. 获取系统信息 ---
get_system_info() {
    draw_line
    echo -e "${YELLOW} [ 系统基础信息 ] ${NC}"
    
    # 操作系统
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release)
    else
        OS_NAME=$(uname -s)
    fi
    
    # 内核版本
    KERNEL=$(uname -r)
    
    # CPU 信息
    CPU_MODEL=$(awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed 's/^[ \t]*//')
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    
    # 运行时间
    UPTIME=$(uptime -p | sed 's/up //')
    
    echo -e " 操作系统 : ${GREEN}$OS_NAME${NC}"
    echo -e " 内核版本 : ${GREEN}$KERNEL${NC}"
    echo -e " CPU 型号 : ${GREEN}$CPU_MODEL${NC}"
    echo -e " CPU 核心 : ${GREEN}$CPU_CORES Cores${NC}"
    echo -e " 运行时间 : ${GREEN}$UPTIME${NC}"
}

# --- 2. 内存与磁盘测试 ---
get_resource_usage() {
    draw_line
    echo -e "${YELLOW} [ 资源与 I/O 测试 ] ${NC}"

    # 内存
    MEM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
    MEM_USED=$(free -m | awk '/Mem:/ { print $3 }')
    MEM_FREE=$(free -m | awk '/Mem:/ { print $4 }')
    
    # 简单的进度条逻辑
    PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    BAR_LENGTH=20
    FILLED=$((PERCENT * BAR_LENGTH / 100))
    UNFILLED=$((BAR_LENGTH - FILLED))
    BAR=$(printf "%0.s#" $(seq 1 $FILLED))
    SPACE=$(printf "%0.s-" $(seq 1 $UNFILLED))

    echo -e " 内存大小 : ${BOLD}${MEM_TOTAL} MB${NC}"
    echo -e " 内存占用 : [${BLUE}${BAR}${NC}${SPACE}] ${PERCENT}% (已用 ${MEM_USED} MB)"

    # 磁盘 I/O (DD 测试)
    echo -e " 正在测试磁盘 I/O 性能 (请稍候)..."
    DISK_SPEED=$(dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    rm -f test_$$
    echo -e " I/O 速度 : ${SKYBLUE}$DISK_SPEED${NC}"
}

# --- 3. 网络测速 (使用 Speedtest-cli) ---
network_test() {
    draw_line
    echo -e "${YELLOW} [ 网络连接测速 ] ${NC}"
    
    # 检查是否安装 python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}未检测到 Python3，跳过详细测速，仅进行 Ping 测试。${NC}"
    else
        echo -e " 正在连接最近的 Speedtest 节点..."
        # 下载官方 CLI 脚本并运行
        curl -s -L https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py > speedtest_runner.py
        chmod +x speedtest_runner.py
        
        # 捕获输出
        SPEED_OUTPUT=$(python3 speedtest_runner.py --simple)
        
        PING=$(echo "$SPEED_OUTPUT" | grep "Ping" | awk '{print $2, $3}')
        DOWNLOAD=$(echo "$SPEED_OUTPUT" | grep "Download" | awk '{print $2, $3}')
        UPLOAD=$(echo "$SPEED_OUTPUT" | grep "Upload" | awk '{print $2, $3}')
        
        echo -e " 延迟 (Ping): ${GREEN}$PING${NC}"
        echo -e " 下载 (Dl)  : ${SKYBLUE}$DOWNLOAD${NC}"
        echo -e " 上传 (Ul)  : ${PURPLE}$UPLOAD${NC}"
        
        rm -f speedtest_runner.py
    fi
    
    # 获取 IP 归属地 (简单版)
    IPV4=$(curl -s4m 5 ip.sb)
    if [[ -n "$IPV4" ]]; then
        echo -e " 公网 IPv4  : ${GREEN}$IPV4${NC}"
    else
        echo -e " 公网 IPv4  : ${RED}检测失败${NC}"
    fi
}

# --- 主程序执行 ---
show_logo
get_system_info
get_resource_usage
network_test

draw_line
echo -e "${BOLD} 测试完成！${NC}"
echo -e " 数据生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e " ${CYAN}由 [威软科技] 提供技术支持${NC}"
echo -e " ${CYAN}官网: www.weiruan-tech-demo.com (示例)${NC}"
draw_line
echo ""
