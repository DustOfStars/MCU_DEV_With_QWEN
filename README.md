# 🚀 EtherCAT Learning on NXP RT1180

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: NXP RT1180](https://img.shields.io/badge/Platform-NXP%20RT1180-blue)](https://www.nxp.com/design/design-center/software/development-software/i-mx-software/embedded-software-for-i-mx-applications-processors:IMX-SW)
[![Protocol: EtherCAT](https://img.shields.io/badge/Protocol-EtherCAT-green)](https://www.ethercat.org/en/ethercat.html)
[![Status: Learning](https://img.shields.io/badge/Status-Learning-orange)]()

**A comprehensive learning journey for implementing EtherCAT on NXP i.MX RT1180 MCU**

[中文文档](#-ethercat-学习之旅基于-nxp-rt1180) | [English Docs](#-ethercat-learning-on-nxp-rt1180)

</div>

---

## 📖 Table of Contents / 目录

- [Overview / 项目概述](#-overview--项目概述)
- [Features / 主要特性](#-features--主要特性)
- [Hardware Requirements / 硬件要求](#-hardware-requirements--硬件要求)
- [Software Stack / 软件栈](#-software-stack--软件栈)
- [Quick Start / 快速开始](#-quick-start--快速开始)
- [Project Structure / 项目结构](#-project-structure--项目结构)
- [Learning Path / 学习路径](#-learning-path--学习路径)
- [Resources / 学习资源](#-resources--学习资源)
- [Contributing / 贡献指南](#-contributing--贡献指南)
- [License / 许可证](#-license--许可证)

---

## 🎯 Overview | 项目概述

<details>
<summary><b>🇬🇧 English</b></summary>

Welcome to this **EtherCAT learning project** based on the **NXP i.MX RT1180** microcontroller! 

This repository serves as a comprehensive guide and codebase for understanding, implementing, and mastering EtherCAT communication on embedded systems. Whether you're a student, hobbyist, or professional engineer, this project will help you dive deep into real-time industrial Ethernet protocols.

**What is EtherCAT?**
EtherCAT (Ethernet for Control Automation Technology) is a high-performance industrial Ethernet protocol widely used in automation, robotics, and motion control applications. It offers deterministic communication with cycle times in the microsecond range.

**Why NXP RT1180?**
The NXP i.MX RT1180 features a powerful Arm Cortex-M7 core running at up to 360 MHz, with dedicated Ethernet MAC support, making it an excellent choice for real-time EtherCAT implementations.

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

欢迎来到这个基于 **NXP i.MX RT1180** 微控制器的 **EtherCAT 学习项目**！

本仓库是一个全面的指南和代码库，旨在帮助你理解、实现和掌握嵌入式系统上的 EtherCAT 通信。无论你是学生、爱好者还是专业工程师，这个项目都将帮助你深入探索实时工业以太网协议。

**什么是 EtherCAT？**
EtherCAT（以太网控制自动化技术）是一种高性能的工业以太网协议，广泛应用于自动化、机器人和运动控制应用。它提供确定性通信，周期时间可达微秒级。

**为什么选择 NXP RT1180？**
NXP i.MX RT1180 搭载强大的 Arm Cortex-M7 内核，主频高达 360 MHz，并具有专用的以太网 MAC 支持，是实现实时 EtherCAT 应用的绝佳选择。

</details>

---

## ✨ Features | 主要特性

<details>
<summary><b>🇬🇧 English</b></summary>

- 🎓 **Structured Learning Path**: From basics to advanced topics
- 💻 **Complete Code Examples**: Well-commented source code for each module
- 🔧 **Hardware Abstraction Layer**: Clean HAL for easy porting
- 📊 **Real-time Performance Analysis**: Tools for measuring cycle times
- 🛠️ **Debugging Support**: Built-in diagnostic features
- 📚 **Comprehensive Documentation**: Detailed explanations in both languages
- 🔄 **SOEM/SOES Compatible**: Works with open-source EtherCAT stacks

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

- 🎓 **结构化学习路径**: 从基础到高级主题
- 💻 **完整代码示例**: 每个模块都有详细注释的源代码
- 🔧 **硬件抽象层**: 清晰的 HAL 便于移植
- 📊 **实时性能分析**: 用于测量周期时间的工具
- 🛠️ **调试支持**: 内置诊断功能
- 📚 **全面文档**: 双语详细解释
- 🔄 **兼容 SOEM/SOES**: 支持开源 EtherCAT 协议栈

</details>

---

## 🛠️ Hardware Requirements | 硬件要求

<details>
<summary><b>🇬🇧 English</b></summary>

| Component | Specification | Notes |
|-----------|---------------|-------|
| **MCU Board** | NXP i.MX RT1180-EVK | Official evaluation kit recommended |
| **Ethernet PHY** | Integrated on EVK | 100Mbps full-duplex |
| **EtherCAT Master** | PC with EtherCAT master software | e.g., TwinCAT, SOEM, IgH |
| **Network Cable** | Standard CAT5e/CAT6 | Direct connection or via switch |
| **Debug Probe** | J-Link / DAP-Link | For flashing and debugging |

Optional: Additional EtherCAT slave devices for testing multi-node networks.

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

| 组件 | 规格 | 备注 |
|------|------|------|
| **MCU 开发板** | NXP i.MX RT1180-EVK | 推荐官方评估套件 |
| **以太网 PHY** | 集成在 EVK 上 | 100Mbps 全双工 |
| **EtherCAT 主站** | 带 EtherCAT 主站软件的 PC | 如 TwinCAT、SOEM、IgH |
| **网线** | 标准 CAT5e/CAT6 | 直连或通过交换机 |
| **调试器** | J-Link / DAP-Link | 用于烧录和调试 |

可选：额外的 EtherCAT 从站设备，用于测试多节点网络。

</details>

---

## 💾 Software Stack | 软件栈

<details>
<summary><b>🇬🇧 English</b></summary>

- **IDE**: MCUXpresso IDE / IAR EWARM / Keil MDK
- **SDK**: NXP MCUXpresso SDK for RT1180
- **EtherCAT Stack**: 
  - SOEM (Simple Open EtherCAT Master) - for master mode
  - SOES (Simple Open EtherCAT Slave) - for slave mode
  - Custom lightweight implementation (for learning)
- **Build Tools**: CMake / Make
- **Version Control**: Git

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

- **开发环境**: MCUXpresso IDE / IAR EWARM / Keil MDK
- **SDK**: NXP MCUXpresso SDK for RT1180
- **EtherCAT 协议栈**: 
  - SOEM (Simple Open EtherCAT Master) - 主站模式
  - SOES (Simple Open EtherCAT Slave) - 从站模式
  - 自定义轻量级实现（用于学习）
- **构建工具**: CMake / Make
- **版本控制**: Git

</details>

---

## 🚀 Quick Start | 快速开始

<details>
<summary><b>🇬🇧 English</b></summary>

### Step 1: Clone the Repository
```bash
git clone https://github.com/DustOfStars/EtherCAT_RT1180_Learning.git
cd EtherCAT_RT1180_Learning
```

### Step 2: Setup Environment
```bash
# Install NXP SDK
# Download from NXP website and extract to SDK_PATH

# Initialize submodules (if using SOEM/SOES)
git submodule update --init --recursive
```

### Step 3: Build the Project
```bash
mkdir build && cd build
cmake .. -DTOOLCHAIN=mcuxpresso -DBOARD=rt1180-evk
make -j$(nproc)
```

### Step 4: Flash and Run
```bash
# Using MCUXpresso IDE
# Or command line with J-Link
JLinkExe -device IMXRT1180 -speed 4000 -autoconnect 1
loadfile build/firmware.elf
go
```

### Step 5: Monitor Output
Open your serial terminal (115200 baud) to see debug messages.

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

### 步骤 1: 克隆仓库
```bash
git clone https://github.com/DustOfStars/EtherCAT_RT1180_Learning.git
cd EtherCAT_RT1180_Learning
```

### 步骤 2: 配置环境
```bash
# 安装 NXP SDK
# 从 NXP 官网下载并解压到 SDK_PATH

# 初始化子模块（如果使用 SOEM/SOES）
git submodule update --init --recursive
```

### 步骤 3: 构建项目
```bash
mkdir build && cd build
cmake .. -DTOOLCHAIN=mcuxpresso -DBOARD=rt1180-evk
make -j$(nproc)
```

### 步骤 4: 烧录运行
```bash
# 使用 MCUXpresso IDE
# 或使用命令行通过 J-Link
JLinkExe -device IMXRT1180 -speed 4000 -autoconnect 1
loadfile build/firmware.elf
go
```

### 步骤 5: 监控输出
打开串口终端（波特率 115200）查看调试信息。

</details>

---

## 📁 Project Structure | 项目结构

<details>
<summary><b>🇬🇧 English</b></summary>

```
EtherCAT_RT1180_Learning/
├── docs/                    # Documentation files
│   ├── en/                  # English docs
│   └── zh/                  # Chinese docs
├── src/                     # Source code
│   ├── main.c               # Application entry point
│   ├── ethercat/            # EtherCAT stack integration
│   ├── hal/                 # Hardware Abstraction Layer
│   ├── drivers/             # Peripheral drivers
│   └── utils/               # Utility functions
├── examples/                # Example projects
│   ├── 01_basic_slave/      # Basic slave configuration
│   ├── 02_process_data/     # Process data exchange
│   ├── 03_sdo_communication/# SDO mailbox communication
│   └── 04_sync_managers/    # Sync manager configuration
├── tests/                   # Unit and integration tests
├── tools/                   # Helper scripts and utilities
├── CMakeLists.txt           # CMake build configuration
└── README.md                # This file
```

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

```
EtherCAT_RT1180_Learning/
├── docs/                    # 文档文件
│   ├── en/                  # 英文文档
│   └── zh/                  # 中文文档
├── src/                     # 源代码
│   ├── main.c               # 应用程序入口
│   ├── ethercat/            # EtherCAT 协议栈集成
│   ├── hal/                 # 硬件抽象层
│   ├── drivers/             # 外设驱动
│   └── utils/               # 工具函数
├── examples/                # 示例项目
│   ├── 01_basic_slave/      # 基础从站配置
│   ├── 02_process_data/     # 过程数据交换
│   ├── 03_sdo_communication/# SDO 邮箱通信
│   └── 04_sync_managers/    # 同步管理器配置
├── tests/                   # 单元测试和集成测试
├── tools/                   # 辅助脚本和工具
├── CMakeLists.txt           # CMake 构建配置
└── README.md                # 本文件
```

</details>

---

## 📚 Learning Path | 学习路径

<details>
<summary><b>🇬🇧 English</b></summary>

### Phase 1: Fundamentals 🌱
- Understanding EtherCAT protocol basics
- Network topology and frame structure
- State machine and initialization

### Phase 2: Implementation 💻
- Setting up the development environment
- Configuring Ethernet peripheral on RT1180
- Integrating EtherCAT stack (SOES)

### Phase 3: Advanced Topics 🚀
- Distributed Clocks (DC) synchronization
- CoE (CAN over EtherCAT) implementation
- Real-time performance optimization
- Error handling and diagnostics

### Phase 4: Projects 🏆
- Building a custom EtherCAT slave device
- Multi-axis motion control application
- Integration with PLC systems

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

### 第一阶段：基础知识 🌱
- 理解 EtherCAT 协议基础
- 网络拓扑和帧结构
- 状态机和初始化流程

### 第二阶段：实现 💻
- 搭建开发环境
- 配置 RT1180 以太网外设
- 集成 EtherCAT 协议栈（SOES）

### 第三阶段：高级主题 🚀
- 分布式时钟（DC）同步
- CoE（EtherCAT 上的 CAN）实现
- 实时性能优化
- 错误处理和诊断

### 第四阶段：项目实战 🏆
- 构建自定义 EtherCAT 从站设备
- 多轴运动控制应用
- 与 PLC 系统集成

</details>

---

## 📖 Resources | 学习资源

<details>
<summary><b>🇬🇧 English</b></summary>

### Official Documentation
- [EtherCAT Technology Overview](https://www.ethercat.org/en/technology.htm)
- [NXP RT1180 Reference Manual](https://www.nxp.com/design/design-center/software/development-software/i-mx-software/embedded-software-for-i-mx-applications-processors:IMX-SW)
- [ETG.1020 EtherCAT Protocol Specification](https://www.ethercat.org/en/downloads.htm)

### Open Source Stacks
- [SOEM - Simple Open EtherCAT Master](https://github.com/OpenEtherCATsociety/SOEM)
- [SOES - Simple Open EtherCAT Slave](https://github.com/OpenEtherCATsociety/SOES)

### Tutorials & Books
- "Industrial Ethernet: A Practical Guide" by John M. Carroll
- Online tutorials and community forums

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

### 官方文档
- [EtherCAT 技术概览](https://www.ethercat.org/en/technology.htm)
- [NXP RT1180 参考手册](https://www.nxp.com/design/design-center/software/development-software/i-mx-software/embedded-software-for-i-mx-applications-processors:IMX-SW)
- [ETG.1020 EtherCAT 协议规范](https://www.ethercat.org/en/downloads.htm)

### 开源协议栈
- [SOEM - Simple Open EtherCAT Master](https://github.com/OpenEtherCATsociety/SOEM)
- [SOES - Simple Open EtherCAT Slave](https://github.com/OpenEtherCATsociety/SOES)

### 教程与书籍
- 《工业以太网实用指南》
- 在线教程和社区论坛

</details>

---

## 🤝 Contributing | 贡献指南

<details>
<summary><b>🇬🇧 English</b></summary>

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支（`git checkout -b feature/AmazingFeature`）
3. 提交更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 提交 Pull Request

在贡献之前，请阅读我们的 [行为准则](CODE_OF_CONDUCT.md)。

</details>

---

## 📄 License | 许可证

<details>
<summary><b>🇬🇧 English</b></summary>

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

In short: You can use, modify, and distribute this software freely, but THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

简而言之：您可以自由使用、修改和分发本软件，但软件按"原样"提供，不提供任何形式的担保。

</details>

---

## 📬 Contact | 联系方式

<details>
<summary><b>🇬🇧 English</b></summary>

- **Author**: DustOfStars
- **Issues**: Please use [GitHub Issues](https://github.com/DustOfStars/EtherCAT_RT1180_Learning/issues) for bug reports and feature requests
- **Discussions**: Join our [Discussion Forum](https://github.com/DustOfStars/EtherCAT_RT1180_Learning/discussions) for questions and ideas

⭐ **If you find this project helpful, please give it a star!** ⭐

</details>

<details>
<summary><b>🇨🇳 中文</b></summary>

- **作者**: DustOfStars
- **问题反馈**: 请使用 [GitHub Issues](https://github.com/DustOfStars/EtherCAT_RT1180_Learning/issues) 报告 bug 或请求新功能
- **讨论区**: 加入我们的 [讨论论坛](https://github.com/DustOfStars/EtherCAT_RT1180_Learning/discussions) 提问和分享想法

⭐ **如果您觉得这个项目有帮助，请给个星标！** ⭐

</details>

---

<div align="center">

**Happy Coding! 🎉 | 编码愉快！**

Made with ❤️ by DustOfStars and contributors

[⬆ Back to Top](#-ethercat-learning-on-nxp-rt1180)

</div>
