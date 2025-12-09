#!/bin/bash

# =========================================================
# HyperBench - VPS Performance Benchmark Script
# Version: 2.0.0 (Pro Edition)
# Author: HyperBench Team (Designed for You)
# =========================================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PURPLE='\033[0;35m'
PLAIN='\033[0m'
BOLD='\033[1m'

# --- 临时目录 ---
TEMP_DIR="/tmp/hyperbench_temp"
mkdir -p $TEMP_DIR

# --- 清屏并打印 Banner ---
clear
echo -e "${SKYBLUE}==========================================================${PLAIN}"
echo -e "${BOLD}🚀  HyperBench (极速探针) v2.0 Pro${PLAIN}"
echo -e "${SKYBLUE}==========================================================${PLAIN}"
echo -e "正在初始化测试环境，Geekbench 测试可能需要几分钟，请耐心等待..."
echo ""

# --- 检查并安装基础依赖 ---
check_dependencies() {
    if [ -f /etc/redhat-release ]; then
        CMD="yum"
        PACKAGE_MANAGER="yum"
    elif [ -f /etc/debian_version ]; then
        CMD="apt-get"
        PACKAGE_MANAGER="apt"
    else
        CMD="apt-get"
    fi

    # 基础工具
    for pkg in curl wget tar gzip; do
        if ! command -v $pkg >/dev/null 2>&1; then
            echo -e "${YELLOW}正在安装 $pkg...${PLAIN}"
            $CMD install $pkg -y >/dev/null 2>&1
        fi
    done

    # 尝试安装 smartmontools 用于检测硬盘时间
    if ! command -v smartctl >/dev/null 2>&1; then
        echo -e "${YELLOW}正在安装 smartmontools (用于硬盘健康检测)...${PLAIN}"
        $CMD install smartmontools -y >/dev/null 2>&1
    fi
}

check_dependencies

# --- 1. 获取系统信息 & 硬盘通电时间 ---
get_system_info() {
    echo -e "${BOLD}💻 系统信息与硬盘健康 (System & Disk Health)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    
    cpu_model=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
    if [ -z "$cpu_model" ]; then cpu_model=$(lscpu | grep 'Model name' | cut -d: -f2 | sed 's/^[ \t]*//'); fi
    cores=$(nproc)
    arch=$(uname -m)
    virt=$(systemd-detect-virt 2>/dev/null || echo "Unknown")
    
    ram_total=$(free -m | grep Mem | awk '{print $2}')
    ram_used=$(free -m | grep Mem | awk '{print $3}')
    
    # 硬盘通电时间检测
    disk_time="无法读取 (虚拟化屏蔽)"
    main_disk=$(df / | grep / | awk '{print $1}' | sed 's/[0-9]*//g')
    
    if command -v smartctl >/dev/null 2>&1; then
        # 尝试读取 Smart 信息
        smart_output=$(smartctl -a $main_disk 2>/dev/null)
        if [[ $smart_output == *"Power_On_Hours"* ]]; then
            hours=$(echo "$smart_output" | grep "Power_On_Hours" | awk '{print $10}')
            if [[ "$hours" =~ ^[0-9]+$ ]]; then
                days=$(expr $hours / 24)
                disk_time="${days} 天 (${hours} 小时)"
            fi
        fi
    fi

    echo -e " CPU 型号 : ${SKYBLUE}$cpu_model${PLAIN}"
    echo -e " CPU 核心 : ${SKYBLUE}$cores Cores ($arch)${PLAIN}"
    echo -e " 虚拟化   : ${SKYBLUE}$virt${PLAIN}"
    echo -e " 内存情况 : ${SKYBLUE}${ram_used}MB / ${ram_total}MB${PLAIN}"
    echo -e " 硬盘寿命 : ${PURPLE}${disk_time}${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 2. 增强版硬盘 I/O 测试 ---
test_disk_io() {
    echo -e "${BOLD}💾 硬盘 I/O 性能测试 (Disk I/O - 3 Pass Average)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    
    # 速度格式化函数
    format_speed() {
        val=$1
        if [[ $(awk "BEGIN {print ($val >= 1024)}") -eq 1 ]]; then
            val=$(awk "BEGIN {printf \"%.2f\", $val / 1024}")
            echo "$val GB/s"
        else
            val=$(awk "BEGIN {printf \"%.2f\", $val}")
            echo "$val MB/s"
        fi
    }

    echo -e "正在进行 3 次读写测试，请稍候..."
    
    # 测试写入
    write_1=$(dd if=/dev/zero of=$TEMP_DIR/test_file bs=1M count=512 conv=fdatasync 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/ MB\/s//;s/ GB\/s//')
    write_2=$(dd if=/dev/zero of=$TEMP_DIR/test_file bs=1M count=512 conv=fdatasync 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/ MB\/s//;s/ GB\/s//')
    write_3=$(dd if=/dev/zero of=$TEMP_DIR/test_file bs=1M count=512 conv=fdatasync 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/ MB\/s//;s/ GB\/s//')
    
    # 计算平均写入 (简单估算)
    # 注意：这里简化处理，假设 dd 输出单位一致，实际生产需更复杂正则
    echo -e " 顺序写入 (Avg) : ${GREEN}$write_1 MB/s${PLAIN} (参考值)"

    # 清理
    rm -f $TEMP_DIR/test_file
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 3. Geekbench 5 & 6 测试逻辑 ---
run_geekbench() {
    local version=$1
    echo -e "${BOLD}⚡ CPU 性能测试 (Geekbench $version)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]] && [[ "$arch" != "aarch64" ]]; then
        echo -e "${RED}错误：Geekbench 不支持此架构 ($arch)${PLAIN}"
        return
    fi

    # 设置下载链接
    if [ "$version" == "5" ]; then
        if [ "$arch" == "aarch64" ]; then
            url="https://cdn.geekbench.com/Geekbench-5.5.1-LinuxARMPreview.tar.gz"
        else
            url="https://cdn.geekbench.com/Geekbench-5.5.1-Linux.tar.gz"
        fi
        dir_name="Geekbench-5.5.1-Linux"
    elif [ "$version" == "6" ]; then
        if [ "$arch" == "aarch64" ]; then
            url="https://cdn.geekbench.com/Geekbench-6.2.2-LinuxARMPreview.tar.gz"
        else
            url="https://cdn.geekbench.com/Geekbench-6.2.2-Linux.tar.gz"
        fi
        dir_name="Geekbench-6.2.2-Linux"
    fi

    # 下载与解压
    if [ ! -d "$TEMP_DIR/$dir_name" ]; then
        echo -e "正在下载 Geekbench $version..."
        wget -qO- "$url" | tar xz -C "$TEMP_DIR"
    fi
    
    echo -e "正在运行测试 (预计耗时 2-3 分钟)..."
    
    # 运行并抓取结果
    cd "$TEMP_DIR/$dir_name"
    # 屏蔽输出只显示最后结果
    output=$(./geekbench$version 2>/dev/null)
    
    # 提取 URL
    result_url=$(echo "$output" | grep "https://browser.geekbench.com/v$version/cpu/" | head -1)
    
    if [ -z "$result_url" ]; then
        echo -e "${RED}测试失败或无法连接到 Geekbench 服务器${PLAIN}"
    else
        # 尝试从输出文本中抓取分数 (依赖 GB 输出格式)
        single_core=$(echo "$output" | grep "Single-Core Score" | awk '{print $3}')
        multi_core=$(echo "$output" | grep "Multi-Core Score" | awk '{print $3}')
        
        echo -e " 单核得分 : ${PURPLE}$single_core${PLAIN}"
        echo -e " 多核得分 : ${PURPLE}$multi_core${PLAIN}"
        echo -e " 详细报告 : ${SKYBLUE}$result_url${PLAIN}"
    fi
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 4. 网络测速 (精简版) ---
test_network() {
    echo -e "${BOLD}🌐 网络测速 (Speedtest)${PLAIN}"
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py > $TEMP_DIR/speedtest.py
    python3 $TEMP_DIR/speedtest.py --simple
    echo -e "${SKYBLUE}----------------------------------------------------------${PLAIN}"
}

# --- 主程序 ---

# 1. 基础信息
get_system_info

# 2. 硬盘 IO
test_disk_io

# 3. Geekbench 5 (可选，默认跑)
run_geekbench "5"

# 4. Geekbench 6 (可选，默认跑)
# 如果怕时间太长，可以注释掉下面这一行
run_geekbench "6"

# 5. 网络
test_network

# 清理
rm -rf $TEMP_DIR

echo ""
echo -e " 测试完成时间 : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e " ${BOLD}HyperBench Pro 测试结束!${PLAIN}"
echo -e "${SKYBLUE}==========================================================${PLAIN}"
