#!/bin/bash

# =========================================================
# HyperBench - VPS Performance Benchmark Script
# Version: 1.2.0
# Author: HyperBench Team (Designed for You)
# =========================================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'

# --- 清屏并打印 Banner ---
clear
echo -e "${SKYBLUE}==========================================================${PLAIN}"
echo -e "${BOLD}🚀  HyperBench (极速探针) v1.2.0${PLAIN}"
echo -e "${SKYBLUE}==========================================================${PLAIN}"
echo -e "正在初始化测试环境，请稍候..."
echo ""

# --- 检查并安装基础依赖 ---
check_dependencies() {
    if [ -f /etc/redhat-release ]; then
        CMD="yum"
    elif [ -f /etc/debian_version ]; then
        CMD="apt-get"
    else
        CMD="apt-get" # Fallback
    fi

    # 检查 curl
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${YELLOW}正在安装 curl...${PLAIN}"
        $CMD update -y >/dev/null 2>&1
        $CMD install curl -y >/dev/null 2>&1
    fi

    # 检查 wget
    if ! command -v wget >/dev/null 2>&1; then
        echo -e "${YELLOW}正在安装 wget...${PLAIN}"
        $CMD install wget -y >/dev/null 2>&1
    fi
    
    # 检查 python3 (用于 speedtest)
    if ! command -v python3 >/dev/null 2>&1; then
         echo -e "${YELLOW}正在安装 python3...${PLAIN}"
         $CMD install python3 -y >/dev/null 2>&1
    fi
}

check_dependencies

# --- 1. 获取系统信息 ---
get_system_info() {
    echo -e "${BOLD}💻 系统信息预览 (System Info)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    
    # CPU 型号
    cpu_model=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
    if [ -z "$cpu_model" ]; then cpu_model=$(lscpu | grep 'Model name' | cut -d: -f2 | sed 's/^[ \t]*//'); fi
    
    # 核心数
    cores=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
    
    # 架构
    arch=$(uname -m)
    
    # 虚拟化
    virt=$(systemd-detect-virt 2>/dev/null || echo "Unknown")
    
    # 内存
    ram_total=$(free -m | grep Mem | awk '{print $2}')
    ram_used=$(free -m | grep Mem | awk '{print $3}')
    swap_total=$(free -m | grep Swap | awk '{print $2}')
    
    # 硬盘
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    
    # 在线时间
    uptime_info=$(uptime -p | sed 's/up //')
    
    # TCP 拥塞控制
    tcp_cc=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    
    echo -e " 核心架构 : ${SKYBLUE}$arch ($virt)${PLAIN}"
    echo -e " CPU 型号 : ${SKYBLUE}$cpu_model${PLAIN}"
    echo -e " CPU 核心 : ${SKYBLUE}$cores Cores${PLAIN}"
    echo -e " 内存容量 : ${SKYBLUE}${ram_used}MB / ${ram_total}MB${PLAIN} (Swap: ${swap_total}MB)"
    echo -e " 硬盘空间 : ${SKYBLUE}${disk_used} / ${disk_total}${PLAIN}"
    echo -e " TCP 算法 : ${SKYBLUE}${tcp_cc}${PLAIN}"
    echo -e " 在线时间 : ${SKYBLUE}${uptime_info}${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 2. 磁盘 I/O 测试 (使用 dd 快速模拟) ---
test_disk_io() {
    echo -e "${BOLD}💾 硬盘 I/O 性能测试 (Disk I/O - Quick)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    echo -e "正在测试写入速度 (1GB file)..."
    
    # 运行 dd 测试
    io_test=$(dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # 清理临时文件
    rm -f test_$$
    
    echo -e " 写入速度 : ${GREEN}${io_test}${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 3. 网络测速 (使用 speedtest-cli) ---
test_network() {
    echo -e "${BOLD}🌐 全球网络测速 (Speedtest.net)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    echo -e "正在安装/运行 Speedtest，请稍候..."

    # 下载官方 CLI 脚本
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py > speedtest_cli.py
    chmod +x speedtest_cli.py

    echo -e " 节点名称              | 上传速度 (Upload) | 下载速度 (Download) | 延迟 (Ping)"
    echo -e " --------------------|------------------|--------------------|-----------"
    
    run_speedtest() {
        local name=$1
        # 简单输出处理，实际生产脚本会解析 JSON
        # 这里为了演示，直接运行最近节点
        output=$(python3 speedtest_cli.py --simple)
        ping=$(echo "$output" | grep 'Ping' | awk '{print $2, $3}')
        dl=$(echo "$output" | grep 'Download' | awk '{print $2, $3}')
        ul=$(echo "$output" | grep 'Upload' | awk '{print $2, $3}')
        
        printf " %-20s | %-16s | %-18s | %s\n" "$name" "$ul" "$dl" "$ping"
    }

    # 默认测速 (自动选择最近节点)
    run_speedtest "[自动] 最近节点"

    # 清理
    rm -f speedtest_cli.py
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 4. 流媒体解锁检测 (Curl 简单探测) ---
check_unlock() {
    echo -e "${BOLD}🎬 流媒体与 AI 解锁检测 (Unlock Status)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    
    check_url() {
        local url=$1
        local name=$2
        # -o /dev/null 丢弃输出, -s 静默, -w %{http_code} 获取状态码
        code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "$url")
        if [[ "$code" == "200" ]] || [[ "$code" == "301" ]] || [[ "$code" == "302" ]]; then
            echo -e " $name      : ${GREEN}✅ Yes${PLAIN}"
        elif [[ "$code" == "403" ]]; then
             # 403 通常意味着 IP 被识别但被拒绝，或者需要登录，视具体服务而定
             # 对于 ChatGPT，403 通常意味着 Cloudflare 拦截
            echo -e " $name      : ${RED}❌ No (403 Forbidden)${PLAIN}"
        else
            echo -e " $name      : ${RED}❌ No (Error: $code)${PLAIN}"
        fi
    }

    # ChatGPT (检测 API 访问)
    # 注意：准确检测需要更复杂的脚本，这里仅做连通性测试
    check_url "https://chat.openai.com/cdn-cgi/trace" "ChatGPT (Web)"
    
    # YouTube
    check_url "https://www.youtube.com" "YouTube     "
    
    # Netflix (仅做基础连通性检查，不代表能看自制剧)
    check_url "https://www.netflix.com/title/80018499" "Netflix     "

    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 主程序执行流 ---

get_system_info
test_disk_io
test_network
check_unlock

echo ""
echo -e " 测试完成时间 : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e " ${BOLD}感谢使用 HyperBench!${PLAIN}"
echo -e "${SKYBLUE}==========================================================${PLAIN}"
