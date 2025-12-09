![HyperBench Banner](path/to/your/banner.png)

# 🚀 HyperBench (极速探针)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/yourusername/hyperbench)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)]()
[![Shell](https://img.shields.io/badge/shell-bash-yellow.svg)]()

> 专为极客打造的轻量级、全方位 Linux 服务器性能测试脚本。

## 📖 简介 (Introduction)

**HyperBench** 是一个集成化的一键 Linux 服务器测试脚本。它能够快速检测 VPS 的系统信息、CPU 跑分、内存读写、硬盘 I/O、国内三网测速、回程路由追踪以及流媒体解锁情况。

无论您是刚刚购买了新的 VPS 需要验货，还是作为运维人员需要监控服务器状态，HyperBench 都能在 1 分钟内为您提供详尽的报告。

## ✨ 核心功能 (Features)

* 💻 **系统信息预览**：CPU 型号、核心数、主频、架构、虚拟化类型、内核版本、在线时间。
* ⚡ **CPU & 内存测试**：基于 Geekbench 5/6 的 CPU 单核/多核跑分，内存读写速度测试。
* 💾 **硬盘 I/O 测试**：使用 FIO 进行 4k 读写测试，真实反映磁盘性能。
* 🌐 **网络测速**：集成 Speedtest，覆盖全球节点及国内电信、联通、移动三网多节点测速。
* 🛣️ **回程路由**：自动追踪三网回程路由（AS4837/AS9929/CN2 GIA 等线路识别）。
* 🎬 **流媒体解锁**：检测 Netflix, Disney+, YouTube Premium, TikTok, ChatGPT 等解锁状态。
* 📊 **输出美观**：对齐整洁的终端输出，支持生成分享链接（Pastebin）。

## 🚀 快速开始 (Quick Start)

无需任何复杂配置，直接在终端执行以下命令即可启动：

### 方式一：默认全量测试 (推荐)

```bash
wget -qO- [https://raw.githubusercontent.com/yourusername/hyperbench/main/hyperbench.sh](https://raw.githubusercontent.com/yourusername/hyperbench/main/hyperbench.sh) | bash

方式二：使用 curl
curl -fsSL [https://raw.githubusercontent.com/yourusername/hyperbench/main/hyperbench.sh](https://raw.githubusercontent.com/yourusername/hyperbench/main/hyperbench.sh) | bash

📋 使用参数 (Arguments)您可以添加参数来执行特定的测试模块，节省时间：参数说明示例-s, --speed仅进行网络测速bash hyperbench.sh -s-i, --io仅进行磁盘 I/O 测试bash hyperbench.sh -i-m, --media仅进行流媒体解锁检测bash hyperbench.sh -m-r, --route仅进行回程路由追踪bash hyperbench.sh -r-f, --fast快速模式 (跳过 Geekbench)bash hyperbench.sh -f🖼️ 运行截图 (Sample Output)Plaintext ----------------------------------------------------------------------
 HyperBench v1.0.0 - 您的服务器性能专家
 ----------------------------------------------------------------------
 核心架构 : KVM / x86_64
 CPU 型号 : AMD EPYC 7402P 24-Core Processor
 CPU 核心 : 2 Cores @ 2794.748 MHz
 内存容量 : 1.95 GB / 3.85 GB (Swap: 1024 MB)
 硬盘空间 : 25.4 GB / 50.0 GB
 系统在线 : 12 days, 4 hours, 22 minutes
 ----------------------------------------------------------------------
 CPU 测试 (Geekbench 5)
   单核得分 : 980
   多核得分 : 1850
 ----------------------------------------------------------------------
 硬盘 I/O (4k 随机读写)
   读取速度 : 150 MB/s
   写入速度 : 142 MB/s
 ----------------------------------------------------------------------
 流媒体解锁检测
   Netflix      : ✅ Yes (Region: US)
   YouTube Prem : ✅ Yes
   Disney+      : ❌ No
   ChatGPT      : ✅ Yes
 ----------------------------------------------------------------------
 三网回程路由检测
   电信 (CT) : CN2 GIA
   联通 (CU) : AS9929 (10099)
   移动 (CM) : CMI
 ----------------------------------------------------------------------
 测试完成时间 : 2025-12-09 15:30:00
 ----------------------------------------------------------------------
⚠️ 注意事项 (Disclaimer)高负载警告：CPU 跑分和硬盘 I/O 测试可能会在短时间内占用大量资源，请勿在生产环境高峰期运行。脚本安全：本脚本开源透明，不包含任何后门或恶意代码，请放心使用。结果波动：网络测速结果受节点和网络环境影响较大，建议多次测试取平均值。🤝 贡献 (Contributing)如果您发现脚本有任何 Bug，或者希望添加新的测速节点/功能，欢迎提交 Pull Request 或 Issues。📄 许可证 (License)本项目遵循 MIT License 协议。
