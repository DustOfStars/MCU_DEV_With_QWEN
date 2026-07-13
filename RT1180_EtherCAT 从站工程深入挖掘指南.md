# RT1180 EtherCAT 从站工程深入挖掘指南
## evkmimxrt1180_ecat_digital_io_cm33 完整分析

---

## 目录

1. [工程概述](#1-工程概述)
2. [系统架构](#2-系统架构)
3. [启动流程详解](#3-启动流程详解)
4. [关键数据结构](#4-关键数据结构)
5. [核心功能模块](#5-核心功能模块)
6. [EtherCAT 状态机](#6-ethercat-状态机)
7. [过程数据通信](#7-过程数据通信)
8. [对象字典与 CoE 协议](#8-对象字典与-coe-协议)
9. [中断处理机制](#9-中断处理机制)
10. [同步与看门狗](#10-同步与看门狗)
11. [硬件抽象层](#11-硬件抽象层)
12. [调试与故障排查](#12-调试与故障排查)

---

## 1. 工程概述

### 1.1 工程目标

本工程是基于 **NXP MIMXRT1189** 双核 Cortex-M33 微控制器的 **EtherCAT 从站设备** 参考实现，运行在 **CM33 核心**上。主要功能包括：

- **EtherCAT 从站通信**：支持标准 EtherCAT 协议栈（Beckhoff SSC V5.13）
- **数字 I/O 控制**：通过 EtherCAT 控制板载 LED（GPIO4_27）
- **CoE 协议支持**：CANopen over EtherCAT，支持 SDO 和 PDO 通信
- **多种同步模式**：支持 FreeRun、SM Sync、DC Sync0/Sync1

### 1.2 核心特性

| 特性 | 配置值 | 说明 |
|------|--------|------|
| MCU | MIMXRT1189CM33 | 双核 Cortex-M33 @ 480MHz |
| EtherCAT PHY | 双端口 RMII | 集成于 SoC，支持线型拓扑 |
| SSC 版本 | V5.13 | Beckhoff Slave Stack Code |
| 过程数据输入 | 64 字节 (0x40) | Sync Manager 3 |
| 过程数据输出 | 64 字节 (0x40) | Sync Manager 2 |
| 邮箱协议 | CoE (SDO+PDO) | 支持紧急报文 |
| 同步模式 | FreeRun/SM/DC | 可配置 |
| 应用对象 | LED 控制 | 0x6000(输入), 0x7000(输出) |

### 1.3 工程目录结构

```
evkmimxrt1180_ecat_digital_io_cm33/
├── board/                      # 板级支持包
│   ├── board.c/h              # 板级初始化
│   ├── clock_config.c/h       # 时钟配置
│   ├── pin_mux.c/h            # 引脚复用配置
│   ├── hardware_init.c        # EtherCAT 硬件初始化 ⭐
│   └── app.h                  # 应用定义（LED GPIO）
├── source/                     # 应用源代码
│   ├── digital_io.c           # 主应用逻辑 ⭐
│   ├── ecat_hw.h              # EtherCAT 硬件抽象层
│   └── SSC/                   # Beckhoff SSC 源码
│       └── Src/
│           ├── ecatappl.c     # EtherCAT 应用层 ⭐
│           ├── ecatslv.c      # EtherCAT 状态机 ⭐
│           ├── coeappl.c      # CoE 应用层
│           ├── mailbox.c      # 邮箱处理
│           ├── sdoserv.c      # SDO 服务
│           ├── objdef.c       # 对象字典定义
│           ├── digital_ioObjects.h  # 应用对象定义 ⭐
│           └── ecat_def.h     # SSC 配置头文件 ⭐
├── drivers/                    # NXP 外设驱动
│   ├── fsl_ecat.c/h           # EtherCAT 控制器驱动 ⭐
│   ├── fsl_rgpio.h            # 快速 GPIO 驱动
│   ├── fsl_gpt.h              # 通用定时器驱动
│   └── fsl_xbar.h             # 交叉开关矩阵
├── startup/                    # 启动文件
│   └── startup_mimxrt1189_cm33.c
├── device/                     # 器件相关文件
├── component/                  # 中间件组件
├── CMSIS/                      # ARM CMSIS 标准
└── Debug/                      # 编译输出
    ├── evkmimxrt1180_ecat_digital_io_cm33_Debug.ld  # 链接脚本
    └── evkmimxrt1180_ecat_digital_io_cm33_Debug.map # 内存映射
```

---

## 2. 系统架构

### 2.1 软件层次架构

```
┌─────────────────────────────────────────────────────────┐
│                    应用层 (Application)                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ digital_io.c│  │digital_io   │  │  applInterface  │ │
│  │  (main)     │  │ Objects.h   │  │   (回调接口)    │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────┤
│              EtherCAT 应用层 (ecatappl.c)                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ MainInit()  │  │ MainLoop()  │  │ PDI_Isr()       │ │
│  │ ECAT_App    │  │ PDO_Map     │  │ Sync0/1_Isr     │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────┤
│         EtherCAT 状态机层 (ecatslv.c / mailbox.c)        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ ESM 状态机  │  │ 邮箱处理    │  │ 对象字典管理    │ │
│  │ INIT→OP     │  │ CoE/FoE     │  │ SDO/PDO 服务    │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────┤
│              硬件抽象层 (ecat_hw.h / fsl_ecat.c)         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ ESC 寄存器  │  │ DPRAM 访问  │  │ MDIO/PHY 配置   │ │
│  │ 读写宏      │  │ 同步原语    │  │ 中断控制        │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────┤
│                 硬件层 (MIMXRT1189 SoC)                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ EtherCAT    │  │ Dual PHY    │  │ GPT/XBAR/NVIC   │ │
│  │ Controller  │  │ (RMII)      │  │ 中断控制器      │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 2.2 数据流架构

```
                    EtherCAT 主站
                        │
                        ▼
        ┌───────────────────────────────┐
        │  EtherCAT 帧 (Ethernet)       │
        │  - FMMU 映射                  │
        │  - SyncManager 配置           │
        └───────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  ESC (EtherCAT Slave Ctrl)    │
        │  - 寄存器空间 (0x0000-0x1FFF) │
        │  - DPRAM (0x2000-0x3FFF)      │
        │  - 邮箱缓冲区                 │
        └───────────────────────────────┘
                        │
          ┌─────────────┴─────────────┐
          │                           │
    SM2 (输出)                   SM3 (输入)
    0x1000-0x1FFF              0x2000-0x2FFF
          │                           │
          ▼                           │
   ┌─────────────┐                    │
   │PDO_Output   │                    │
   │Mapping()    │                    │
   │ - HW_EscRead│                    │
   │ - APPL_     │                    │
   │   OutputMap │                    │
   └─────────────┘                    │
          │                           │
          ▼                           │
   ┌─────────────┐                    │
   │ LED_status  │◄───────────────────┤
   │ (全局变量)  │                    │
   └─────────────┘                    │
          │                           │
          ▼                           ▼
   ┌─────────────┐            ┌─────────────┐
   │ RGPIO4_27   │            │PDO_Input    │
   │ (LED 驱动)  │            │Mapping()    │
   └─────────────┘            │ - MEMCPY    │
                              │ - HW_EscWri │
                              └─────────────┘
                                      │
                                      ▼
                               EtherCAT 主站
```

### 2.3 内存布局（基于链接脚本分析）

```
Flash (0x28000000 起始):
┌───────────────────────────────────────┐
│ 0x0000 - 0x0400: Boot Header         │ ← IVT (中断向量表)
│ 0x0400 - 0x0800: FCB                 │ ← FlexSPI 配置块 (含 LUT)
│ 0x0800 - 0x1000: XMCD (可选)         │ ← 扩展内存配置
│ 0x1000 - 0x2000: Container Header    │ ← 镜像容器 (标志 0x00000213)
│ 0x2000 - 0xXXXX: 代码段 (.text)      │ ← ResetISR, main, 应用代码
│ 0xXXXX - 0xYYYY: 只读数据 (.rodata)  │ ← 常量、字符串、对象字典
└───────────────────────────────────────┘

RAM (0x20000000 起始):
┌───────────────────────────────────────┐
│ 0x0000 - 0x0400: 向量表重定位        │
│ 0x0400 - 0x0800: 数据段 (.data)      │ ← 已初始化全局变量
│ 0x0800 - 0x1000: BSS 段 (.bss)       │ ← 未初始化全局变量
│ 0x1000 - 0xXXXX: 堆 (Heap)           │ ← 动态分配
│ 0xXXXX - 0xYYYY: 栈 (Stack)          │ ← 函数调用栈
│   - 主栈 (MSP): 0x20000000 + 64KB   │
│   - 进程栈 (PSP): 用于线程模式      │
└───────────────────────────────────────┘

关键变量地址（从 MAP 文件）:
- LED_status:        0x20000xxx (BSS)
- aPdOutputData:     0x20000xxx (64 字节输出缓冲区)
- aPdInputData:      0x20000xxx (64 字节输入缓冲区)
- Obj0x7000:         0x20000xxx (输出对象)
- Obj0x6000:         0x20000xxx (输入对象)
```

---

## 3. 启动流程详解

### 3.1 完整启动序列

```
┌─────────────────────────────────────────────────────────────┐
│ 阶段 1: BootROM 加载 (0x00000000)                          │
├─────────────────────────────────────────────────────────────┤
│ 1. BootROM 执行                                            │
│    - 检测启动模式 (Boot Pins)                              │
│    - 选择 FlexSPI Port A/B                                 │
│    - 读取 Flash 镜像头部                                   │
│                                                             │
│ 2. 解析 Boot Header                                        │
│    ├─ IVT (0x000): 中断向量表                              │
│    │  - 初始 SP 值                                          │
│    │  - Reset_Handler 地址                                  │
│    │                                                         │
│    ├─ FCB (0x400): FlexSPI 配置块                          │
│    │  - serialNorType = 1 (SFDP 设备)                       │
│    │  - readSampleClkSrc = 1 (Loopback)                     │
│    │  - csHoldDelay = 3, csSetupDelay = 3                  │
│    │  - columAddrWidth = 0 (24-bit)                         │
│    │  - controllerMiscOption = 0x40 (差分 CLK)              │
│    │  - deviceType = 1 (Serial NOR)                         │
│    │  - sflashPadType = 4 (Quad SPI)                        │
│    │  - LUT 查找表 (读/写/擦除命令)                         │
│    │    · 读：0xEB (Quad I/O, 6 dummy)                      │
│    │    · 写使能：0x06                                      │
│    │    · 扇区擦除：0x20                                    │
│    │    · 页编程：0x02                                      │
│    │                                                         │
│    └─ Container (0x1000): 程序镜像                         │
│       - 标志：0x00000213                                     │
│         · Bit0-3=0x3: CM33 核心                             │
│         · Bit4-7=0x1: SHA512 签名                           │
│         · Bit8-11=0x2: 未加密                               │
│       - 镜像大小、加载地址、入口点                          │
│                                                             │
│ 3. 加载镜像到 RAM                                           │
│    - 复制 .text 和 .rodata 到 Flash 执行位置                │
│    - 复制 .data 到 RAM (0x20000000)                         │
│    - 清零 .bss 段                                            │
│                                                             │
│ 4. 跳转到 Reset_Handler                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 阶段 2: 启动文件 (startup_mimxrt1189_cm33.c)               │
├─────────────────────────────────────────────────────────────┤
│ Reset_Handler 执行:                                         │
│ 1. 设置模式（Thread 模式，使用 MSP）                        │
│ 2. 初始化浮点单元 (FPU)                                     │
│    - CPACR = 0x00F00000 (启用 CP10/CP11)                    │
│    - DSBBAR 配置                                             │
│ 3. 调用 SystemInit()                                        │
│    - 配置时钟系统                                          │
│    - 初始化 PLL                                              │
│    - 设置系统时钟为 480MHz                                  │
│ 4. 调用 __main (ARM 库初始化)                               │
│    - 复制 .data 段到 RAM                                     │
│    - 清零 .bss 段                                            │
│ 5. 跳转到 main()                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 阶段 3: 应用初始化 (digital_io.c)                          │
├─────────────────────────────────────────────────────────────┤
│ main() 函数 (#if USE_DEFAULT_MAIN):                        │
│                                                             │
│ 1. HW_Init() - 硬件初始化                                   │
│    ├─ BOARD_InitBootPins()                                  │
│    │  - 配置 EtherCAT PHY 引脚 (RMII)                       │
│    │  - 配置 LED GPIO (RGPIO4_27)                           │
│    │  - 配置 XBAR 信号路由                                  │
│    │                                                         │
│    ├─ BOARD_BootClockRUN()                                  │
│    │  - 设置系统时钟 480MHz                                  │
│    │  - 配置 Bus/Flash 时钟分频                             │
│    │                                                         │
│    ├─ BOARD_InitDebugConsole()                              │
│    │  - 初始化 UART 用于 PRINTF                             │
│    │                                                         │
│    ├─ Ecat_KickOff() - EtherCAT 控制器使能                  │
│    │  - BLK_CTRL_WAKEUPMIX->ECAT_MISC_CFG                   │
│    │    · RMII_REF_CLK_DIR0/1 = 1 (输出参考时钟)            │
│    │    · RMII_SEL0/1 = 1 (选择 RMII 模式)                  │
│    │    · EEPROM_SIZE_OPTION = 1 (64KB EEPROM 仿真)         │
│    │    · PHY_OFFSET = 2 (PHY 寄存器偏移)                   │
│    │    · GLB_EN = 1, GLB_RST = 0 (使能，释放复位)          │
│    │                                                         │
│    ├─ PHY 复位序列                                          │
│    │  - RGPIO4_25, RGPIO4_13 拉低 15ms                      │
│    │  - 拉高后等待 90ms                                      │
│    │                                                         │
│    ├─ MDIO 配置 (双端口 PHY)                                │
│    │  Port 0:                                               │
│    │    - 页寄存器 31 = 0x07 (扩展页)                       │
│    │    - LED 控制 19 |= 0x08 (自定义 LED)                  │
│    │    - LED 行为 17 |= 0x28 (LINK100 + ACK)               │
│    │  Port 1: 相同配置                                      │
│    │                                                         │
│    ├─ PHY EEE 禁用                                          │
│    │  - 节能以太网可能导致时序问题                          │
│    │                                                         │
│    ├─ XBAR 配置 (Sync 信号路由)                             │
│    │  - XBAR1_InputEcatSyncOut0 → DMA4MuxReq154            │
│    │  - XBAR1_InputEcatSyncOut1 → DMA4MuxReq155            │
│    │  - 上升沿触发，中断使能                                │
│    │                                                         │
│    ├─ AL Event Mask 初始化                                  │
│    │  - 写入 0x93 验证                                       │
│    │  - 清零所有中断屏蔽                                    │
│    │                                                         │
│    ├─ GPT1 定时器配置 (1ms 基准)                            │
│    │  - 时钟源：IPG_CLK_ROOT                                 │
│    │  - 分频：100                                            │
│    │  - 比较值：gptFreq / 100000 (10μs tick)               │
│    │  - 中断：GPT1_IRQn 使能                                │
│    │                                                         │
│    └─ 中断使能                                              │
│       - ECAT_INT_IRQn (PDI 中断)                            │
│       - XBAR1_CH0_CH1_IRQn (Sync0/1 中断)                   │
│       - GPT1_IRQn (定时器中断)                              │
│                                                             │
│ 2. MainInit() - EtherCAT 栈初始化                           │
│    ├─ ECAT_Init()                                           │
│    │  - 初始化 ESC 接口                                     │
│    │  - 重置 EtherCAT 状态机                                │
│    │                                                         │
│    ├─ COE_ObjInit()                                         │
│    │  - 初始化对象字典                                      │
│    │  - 注册应用对象 (0x6000, 0x7000, 0xF000)              │
│    │                                                         │
│    ├─ 系统时间测量校准                                      │
│    │  - 循环 1000 次读取 ESC_SYSTEMTIME                     │
│    │  - 计算最小读取延迟 u32SystemTimeReadFailure           │
│    │                                                         │
│    └─ bInitFinished = TRUE                                  │
│                                                             │
│ 3. 进入主循环                                               │
│    bRunApplication = TRUE                                   │
│    do {                                                     │
│        MainLoop();                                          │
│    } while (bRunApplication == TRUE);                       │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 关键初始化代码分析

#### HW_Init() 详细流程

```c
UINT16 HW_Init(void)
{
    // 1. 板级硬件初始化
    BOARD_InitBootPins();      // 引脚复用配置
    BOARD_BootClockRUN();      // 时钟配置 (480MHz)
    BOARD_InitDebugConsole();  // UART 调试控制台
    
    PRINTF("Start the SSC digital_io example...\r\n");
    
    // 2. EtherCAT PHY 复位
    RGPIO_PinInit(RGPIO4, 25, &pinConfig);  // PHY 复位 0
    RGPIO_PinInit(RGPIO4, 13, &pinConfig);  // PHY 复位 1
    SDK_DelayAtLeastUs(15000, ...);         // 保持复位 15ms
    
    // 3. EtherCAT 控制器使能
    Ecat_KickOff();
    /* 
     * BLK_CTRL_WAKEUPMIX->ECAT_MISC_CFG 配置:
     * - RMII_REF_CLK_DIR0/1 = 1: PHY 参考时钟由 MAC 提供
     * - RMII_SEL0/1 = 1: 选择 RMII 接口模式
     * - EEPROM_SIZE_OPTION = 1: 64KB EEPROM 仿真空间
     * - PHY_OFFSET = 2: PHY 寄存器基地址偏移
     * - GLB_EN = 1: 全局使能 EtherCAT 模块
     * - GLB_RST = 0: 释放全局复位
     */
    
    // 4. 释放 PHY 复位
    RGPIO_PinWrite(RGPIO4, 25, 1);
    RGPIO_PinWrite(RGPIO4, 13, 1);
    SDK_DelayAtLeastUs(90000, ...);  // 等待 PHY 稳定 90ms
    
    // 5. Port 0 PHY 配置
    ECAT_EscMdioWrite(ECAT, 0x00, 31, 0x07);  // 选择页 7
    ECAT_EscMdioRead(ECAT, 0x00, 19, &led_status);
    ECAT_EscMdioWrite(ECAT, 0x00, 19, led_status | (1 << 3));  // 自定义 LED
    ECAT_EscMdioRead(ECAT, 0x00, 17, &led_status);
    ECAT_EscMdioWrite(ECAT, 0x00, 17, led_status | (1<<3)|(1<<5));  // LINK+ACK
    
    // 6. Port 1 PHY 配置 (相同)
    ECAT_EscMdioWrite(ECAT, 0x01, 31, 0x07);
    // ... 相同配置
    
    // 7. 禁用 PHY EEE 模式 (节能以太网)
    // 防止 EEE 导致的链路延迟问题
    ECAT_EscMdioWrite(ECAT, 0x00, 31, 4);   // 页 4
    ECAT_EscMdioWrite(ECAT, 0x00, 16, 0x4077);
    // ... 多步配置
    
    // 8. LED GPIO 初始化
    RGPIO_PinInit(RGPIO4, 27, &pinConfig);  // LED
    RGPIO_PinInit(RGPIO4, 26, &pinConfig);  // 备用
    
    // 9. XBAR 配置 (Sync 信号路由)
    XBAR_Init(kXBAR_DSC1);
    XBAR_SetSignalsConnection(kXBAR1_InputEcatSyncOut0, kXBAR1_OutputDma4MuxReq154);
    // 配置上升沿触发，中断使能
    
    // 10. AL Event Mask 初始化
    do {
        intMask = 0x93;
        HW_EscWriteDWord(intMask, ESC_AL_EVENTMASK_OFFSET);
        intMask = 0;
        HW_EscReadDWord(intMask, ESC_AL_EVENTMASK_OFFSET);
    } while (intMask != 0x93);  // 验证写入成功
    
    HW_EscWriteDWord(0x00, ESC_AL_EVENTMASK_OFFSET);  // 暂时屏蔽所有中断
    
    // 11. GPT1 定时器配置 (1ms 基准)
    GPT_GetDefaultConfig(&gptConfig);
    GPT_Init(GPT1, &gptConfig);
    gptFreq = CLOCK_GetRootClockFreq(kCLOCK_Root_Gpt1);
    GPT_SetClockDivider(GPT1, 100);  // 分频 100
    GPT_SetOutputCompareValue(GPT1, kGPT_OutputCompare_Channel1, gptFreq/100000);
    GPT_EnableInterrupts(GPT1, kGPT_OutputCompare1InterruptEnable);
    EnableIRQ(GPT1_IRQn);
    
    // 12. 使能中断
    EnableIRQ(ECAT_INT_IRQn);         // EtherCAT PDI 中断
    NVIC_EnableIRQ(XBAR1_CH0_CH1_IRQn); // Sync0/1 中断
    GPT_StartTimer(GPT1);             // 启动定时器
    
    return 0;
}
```

---

## 4. 关键数据结构

### 4.1 过程数据缓冲区

```c
// ecatappl.c
UINT16 aPdOutputData[(MAX_PD_OUTPUT_SIZE>>1)];  // 64 字节输出缓冲区
UINT16 aPdInputData[(MAX_PD_INPUT_SIZE>>1)];    // 64 字节输入缓冲区

// MAX_PD_OUTPUT_SIZE = 0x40 (64 字节)
// MAX_PD_INPUT_SIZE = 0x40 (64 字节)
```

**内存布局：**
```
aPdOutputData (0x2000xxxx):
┌────────────────────────────────┐
│ Byte 0-1: PDO 输出字 0          │
│ Byte 2-3: PDO 输出字 1          │
│ ...                            │
│ Byte 62-63: PDO 输出字 31       │
└────────────────────────────────┘
         │
         │ APPL_OutputMapping()
         ▼
┌────────────────────────────────┐
│ LED_status (Byte 0)            │ ← 实际使用的 1 字节
│  Bit0: LED 状态                │
│  Bit1-7: 保留                  │
└────────────────────────────────┘
```

### 4.2 应用对象定义

```c
// digital_ioObjects.h

// 对象 0x6000: 输入对象 (LED 状态反馈)
typedef struct {
    UINT16 u16SubIndex0;    // = 1
    BOOLEAN LED;            // SubIndex 1: LED 输入状态
} TOBJ6000;

PROTO TOBJ6000 Obj0x6000 = {1, 0x01};

// 对象 0x7000: 输出对象 (LED 控制)
typedef struct {
    UINT16 u16SubIndex0;    // = 1
    BOOLEAN LED;            // SubIndex 1: LED 输出控制
} TOBJ7000;

PROTO TOBJ7000 Obj0x7000 = {1, 0x01};

// PDO 映射配置
// RxPDO (0x1600): 映射 0x7000:01:08 (8 位 LED 输出)
TOBJ1600 RxPDO0x1600 = {1, 0x70000101};

// TxPDO (0x1A00): 映射 0x6000:01:08 (8 位 LED 输入)
TOBJ1A00 TxPDO0x1A00 = {1, 0x60000101};

// SyncManager 分配
TOBJ1C12 sRxPDOassign = {1, {0x1600}};  // SM2 → RxPDO
TOBJ1C13 sTxPDOassign = {1, {0x1A00}};  // SM3 → TxPDO
```

### 4.3 EtherCAT 状态机变量

```c
// ecatslv.c / ecatappl.c 中的关键状态变量

// 状态机控制
UINT8 bEcatWaitForAlControlRes;    // 等待 AL Control 响应
UINT16 EsmTimeoutCounter;          // 状态机超时计数器 (ms)
BOOL bLocalErrorFlag;              // 本地错误标志

// 同步模式
BOOL bEscIntEnabled;               // ESC 中断使能标志
BOOL bDcSyncActive;                // DC 同步激活标志
BOOL bDcRunning;                   // DC 运行标志
BOOL bEcatFirstOutputsReceived;    // 首次输出接收标志

// 过程数据控制
BOOL bEcatOutputUpdateRunning;     // 输出更新运行标志
BOOL bEcatInputUpdateRunning;      // 输入更新运行标志
UINT16 nPdOutputSize;              // 输出数据大小 (字节)
UINT16 nPdInputSize;               // 输入数据大小 (字节)

// Sync 监控
UINT16 u16SmSync0Counter;          // SM-Sync0 计数器
UINT16 u16SmSync0Value;            // SM-Sync0 期望值
UINT16 Sync0WdCounter;             // Sync0 看门狗计数器
UINT16 Sync1WdCounter;             // Sync1 看门狗计数器

// 周期时间测量
UINT32 u32CycleTimeStartValue;     // 周期开始时间
UINT32 u32MinCycleTimeValue;       // 最小周期时间
BOOL bMinCycleTimeMeasurementStarted;
```

### 4.4 邮箱结构

```c
// mailbox.h
typedef struct MBX {
    UINT16 Length;          // 邮箱长度 (字节数 - 2)
    UINT16 Address;         // 目标地址
    UINT8 Channel;          // 通道号 (Bit0-3: 类型，Bit4-7: 通道)
    UINT8 Priority;         // 优先级
    union {
        UINT8 Data[1];      // 数据域
        struct {
            UINT16 Num;     // CoE: 索引
            UINT8 Cmd;      // CoE: 命令
            UINT8 Res;      // CoE: 保留
        } CoE;
    };
} TMBX, *PMBX;

// CoE 命令定义
#define COE_SDOREQUEST      0x01
#define COE_SDORESPONSE     0x02
#define COE_SDOINFORMATION  0x03
#define COE_SDOCOMPLETE     0x04
```

---

## 5. 核心功能模块

### 5.1 主循环 (MainLoop)

```c
// ecatappl.c
void MainLoop(void)
{
    // 1. 检查初始化完成
    if (bInitFinished == FALSE) return;
    
    // 2. FreeRun 模式处理 (无中断)
    if (!bEscIntEnabled && !bDcSyncActive) {
        // 检查输出事件
        UINT16 ALEvent = HW_GetALEventRegister();
        if (ALEvent & PROCESS_OUTPUT_EVENT) {
            bEcatFirstOutputsReceived = TRUE;
            if (bEcatOutputUpdateRunning) {
                PDO_OutputMapping();  // 处理输出
            }
        }
        
        DISABLE_ESC_INT();
        ECAT_Application();  // 执行应用逻辑
        
        if (bEcatInputUpdateRunning && nPdInputSize > 0) {
            PDO_InputMapping();  // 处理输入
        }
        ENABLE_ESC_INT();
    }
    
    // 3. 定时器检查 (1ms 基准)
    UINT32 CurTimer = HW_GetTimer();
    if (CurTimer >= ECAT_TIMER_INC_P_MS) {
        ECAT_CheckTimer();  // 看门狗、LED 指示
        HW_ClearTimer();
    }
    
    // 4. 时间戳同步
    if (u32CheckForDcOverrunCnt >= CHECK_DC_OVERRUN_IN_MS) {
        COE_SyncTimeStamp();
    }
    
    // 5. EtherCAT 主处理
    ECAT_Main();  // 状态机、邮箱、SM 处理
    
    // 6. CoE 后台处理
    COE_Main();
    CheckIfEcatError();
    
    // 7. 应用回调 (如果注册)
    if (pAPPL_MainLoop != NULL) {
        pAPPL_MainLoop();
    }
}
```

**执行频率：** 尽可能快（典型 100μs-1ms 周期）

### 5.2 输出处理链 (PDO_OutputMapping)

```c
// ecatappl.c
void PDO_OutputMapping(void)
{
    // 1. 周期时间测量 (如果启用)
    if (MEASUREMENT_ACTIVE) {
        u32TimeValue = GetSystemTimeDelay(0);
        HandleCycleTimeMeasurement();
    }
    
    // 2. 从 ESC DPRAM 读取输出数据
    HW_EscReadIsr((MEM_ADDR *)aPdOutputData, nEscAddrOutputData, nPdOutputSize);
    /*
     * nEscAddrOutputData: SM2 基地址 (通常 0x1000)
     * nPdOutputSize: 输出数据长度 (64 字节)
     * HW_EscReadIsr: 中断安全的 ESC 读函数
     */
    
    // 3. 调用应用层输出映射
    APPL_OutputMapping((UINT16*) aPdOutputData);
    /*
     * digital_io.c:
     * void APPL_OutputMapping(UINT16 *pData)
     * {
     *     MEMCPY(&LED_status, pData, SIZEOF(LED_status));
     * }
     */
    
    // 4. 更新周期时间测量
    if (MEASUREMENT_ACTIVE) {
        u32TimeValue = GetSystemTimeDelay(u32TimeValue);
        // 更新 CalcAndCopyTime
    }
}
```

**执行时机：** SM2 事件中断或主循环轮询

### 5.3 输入处理链 (PDO_InputMapping)

```c
// ecatappl.c
void PDO_InputMapping(void)
{
    // 1. 周期时间测量
    if (MEASUREMENT_ACTIVE) {
        u32TimeValue = GetSystemTimeDelay(0);
    }
    
    // 2. 调用应用层输入映射
    APPL_InputMapping((UINT16*)aPdInputData);
    /*
     * digital_io.c:
     * void APPL_InputMapping(UINT16 *pData)
     * {
     *     MEMCPY(pData, &LED_status, SIZEOF(LED_status));
     * }
     */
    
    // 3. 写入 ESC DPRAM
    HW_EscWriteIsr((MEM_ADDR *)aPdInputData, nEscAddrInputData, nPdInputSize);
    /*
     * nEscAddrInputData: SM3 基地址 (通常 0x2000)
     * nPdInputSize: 输入数据长度 (64 字节)
     */
    
    // 4. 更新周期时间测量
    if (MEASUREMENT_ACTIVE) {
        u32TimeValue = GetSystemTimeDelay(u32TimeValue);
        // 更新 CalcAndCopyTime 和 MinCycleTime
    }
}
```

**执行时机：** Sync0/Sync1 中断或主循环轮询

### 5.4 应用逻辑 (APPL_Application)

```c
// digital_io.c
void APPL_Application(void)
{
    // 直接驱动 LED GPIO
    RGPIO_PinWrite(GPIO_LED, GPIO_LED_PIN, LED_status & 0x01);
    /*
     * GPIO_LED = RGPIO4
     * GPIO_LED_PIN = 27
     * LED_status & 0x01: 取最低位
     */
}
```

**执行时机：** ECAT_Application() 中调用，每个应用周期一次

---

## 6. EtherCAT 状态机

### 6.1 状态转换图

```
                    ┌──────────────┐
                    │    INIT      │
                    │  (0x01)      │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         │ ALControl       │ ALControl       │
         │ (Error)         │ (Transition)    │
         ▼                 ▼                 ▼
┌────────────────┐ ┌──────────────┐ ┌──────────────┐
│  BOOTSTRAP     │ │    PREOP     │ │   ERROR      │
│   (0x07)       │ │   (0x02)     │ │   STATE      │
└────────────────┘ └──────┬───────┘ └──────────────┘
                          │
              ┌───────────┼───────────┐
              │           │           │
              │ ALControl │ ALControl │
              │ (Error)   │ (SafeOP)  │
              ▼           ▼           │
       ┌──────────────┐ ┌──────────────┐
       │    ERROR     │ │    SAFEOP    │
       │    STATE     │ │   (0x04)     │
       └──────────────┘ └──────┬───────┘
                               │
                    ┌──────────┼──────────┐
                    │          │          │
                    │ ALControl│ ALControl│
                    │ (Error)  │ (OP)     │
                    ▼          ▼          │
             ┌──────────────┐ ┌──────────────┐
             │    ERROR     │ │     OP       │
             │    STATE     │ │   (0x08)     │
             └──────────────┘ └──────┬───────┘
                                     │
                              Watchdog│ Error
                              Timeout │ Local
                                      ▼
                               ┌──────────────┐
                               │   SAFEOP     │
                               │   (0x04)     │
                               └──────────────┘
```

### 6.2 状态转换处理函数

```c
// digital_io.c 中实现的应用层回调

// INIT → PREOP: 启动邮箱处理
UINT16 APPL_StartMailboxHandler(void)
{
    return ALSTATUSCODE_NOERROR;  // 允许转换
}

// PREOP → INIT: 停止邮箱处理
UINT16 APPL_StopMailboxHandler(void)
{
    return ALSTATUSCODE_NOERROR;
}

// PREOP → SAFEOP: 启动输入处理
UINT16 APPL_StartInputHandler(UINT16 *pIntMask)
{
    // 可适配 AL Event Mask
    return ALSTATUSCODE_NOERROR;
}

// SAFEOP → PREOP: 停止输入处理
UINT16 APPL_StopInputHandler(void)
{
    return ALSTATUSCODE_NOERROR;
}

// SAFEOP → OP: 启动输出处理
UINT16 APPL_StartOutputHandler(void)
{
    return ALSTATUSCODE_NOERROR;
}

// OP → SAFEOP: 停止输出处理
UINT16 APPL_StopOutputHandler(void)
{
    return ALSTATUSCODE_NOERROR;
}

// 错误确认通知
void APPL_AckErrorInd(UINT16 stateTrans)
{
    // 错误被主站确认时的回调
}

// PDO 映射计算
UINT16 APPL_GenerateMapping(UINT16 *pInputSize, UINT16 *pOutputSize)
{
    // 扫描 0x1C12/0x1C13 计算 PDO 大小
    // 本例：Input=1 字节，Output=1 字节
}
```

### 6.3 状态机内部处理 (ECAT_Main)

```c
// ecatslv.c 简化流程
void ECAT_Main(void)
{
    // 1. 读取 AL Control 寄存器
    UINT16 ALControl = HW_GetALControl();
    
    // 2. 检查状态请求
    if (ALControl & 0x000F) {  // 新的状态请求
        UINT8 ReqState = ALControl & 0x000F;
        
        // 3. 验证状态转换
        if (IsValidTransition(CurrentState, ReqState)) {
            
            // 4. 调用应用层回调
            switch (ReqState) {
                case STATE_PREOP:
                    Error = APPL_StartMailboxHandler();
                    break;
                case STATE_SAFEOP:
                    Error = APPL_StartInputHandler(&IntMask);
                    break;
                case STATE_OP:
                    Error = APPL_StartOutputHandler();
                    break;
                // ...
            }
            
            // 5. 更新状态
            if (Error == ALSTATUSCODE_NOERROR) {
                CurrentState = ReqState;
                HW_WriteALStatus(CurrentState);
                
                // 6. 使能相应 SyncManager
                EnableSyncManagers(ReqState);
            } else {
                // 转换失败
                HW_WriteALStatus(CurrentState | 0x10);
                HW_WriteALStatusCode(Error);
            }
        }
    }
    
    // 3. 处理邮箱
    if (MbxCycle()) {
        // 处理 CoE/SoE/FoE/EoE 邮箱
    }
    
    // 4. 检查看门狗
    CheckWatchdog();
}
```

---

## 7. 过程数据通信

### 7.1 SyncManager 配置

```
SyncManager 0: Mailbox Out (Master → Slave)
  - 地址：0x0800
  - 大小：256 字节
  - 方向：写入 (Slave 读取)
  - 模式：邮箱

SyncManager 1: Mailbox In (Slave → Master)
  - 地址：0x0900
  - 大小：256 字节
  - 方向：读取 (Slave 写入)
  - 模式：邮箱

SyncManager 2: Process Data Out (Master → Slave)
  - 地址：0x1000
  - 大小：64 字节
  - 方向：写入 (Slave 读取)
  - 模式：标准模式，1-Buffer
  - 关联 PDO：RxPDO (0x1600) → 0x7000:01

SyncManager 3: Process Data In (Slave → Master)
  - 地址：0x2000
  - 大小：64 字节
  - 方向：读取 (Slave 写入)
  - 模式：标准模式，1-Buffer
  - 关联 PDO：TxPDO (0x1A00) → 0x6000:01
```

### 7.2 FMMU 映射

```
FMMU 0: 映射输出 PDO
  - 逻辑地址：由主站配置 (例如 0x10000000)
  - 物理地址：0x1000 (SM2)
  - 长度：64 字节
  - 方向：写入

FMMU 1: 映射输入 PDO
  - 逻辑地址：由主站配置 (例如 0x10000040)
  - 物理地址：0x2000 (SM3)
  - 长度：64 字节
  - 方向：读取
```

### 7.3 PDO 映射配置示例

**主站配置序列：**
```
1. 写入 0x1C12:01 = 0x1600  (SM2 分配 RxPDO)
2. 写入 0x1C13:01 = 0x1A00  (SM3 分配 TxPDO)
3. 写入 0x1600:01 = 0x70000108  (RxPDO 映射 0x7000:01, 8 位)
4. 写入 0x1A00:01 = 0x60000108  (TxPDO 映射 0x6000:01, 8 位)
5. 写入 0x1C12:00 = 0x01  (激活 SM2 分配)
6. 写入 0x1C13:00 = 0x01  (激活 SM3 分配)
```

**PDO 数据格式：**
```
输出 PDO (Master → Slave, 1 字节):
┌────────┐
│ Bit0   │ → LED 控制 (0=OFF, 1=ON)
│ Bit1-7 │ → 保留
└────────┘

输入 PDO (Slave → Master, 1 字节):
┌────────┐
│ Bit0   │ ← LED 状态反馈
│ Bit1-7 │ ← 保留
└────────┘
```

---

## 8. 对象字典与 CoE 协议

### 8.1 对象字典结构

```c
// objdef.h
typedef struct OBJECT {
    struct OBJECT *Next;          // 下一对象指针
    struct OBJECT *Parent;        // 父对象指针
    UINT16 Index;                 // 对象索引
    TSDOINFOENTRYDESC EntryDesc;  // 条目描述
    TSDOINFOENTRYDESC *pEntryDesc;// 子条目描述数组
    UCHAR *pName;                 // 对象名称
    void *pVarPtr;                // 变量指针
    UINT8 (*pfnRead)(...);        // 读回调函数
    UINT8 (*pfnWrite)(...);       // 写回调函数
    UINT16 Flags;                 // 标志位
} TOBJECT, *PTOBJECT;
```

### 8.2 应用对象详解

#### 对象 0x6000 (输入对象)

```c
// digital_ioObjects.h
索引：0x6000
名称："Obj0x6000"
类型：RECORD
子条目数：1

SubIndex 0:
  - 类型：UNSIGNED8
  - 访问：只读
  - 值：0x01 (子条目数量)

SubIndex 1 (LED):
  - 类型：BOOLEAN
  - 访问：只读，TX-PDO 映射
  - 默认值：0x01
  - 读回调：ReadObject0x6000()
  
读操作实现：
UINT8 ReadObject0x6000(UINT16 index, UINT8 subindex, 
                       UINT32 dataSize, UINT16 *pData)
{
    if (subindex == 0) {
        *pData = 1;  // 返回子条目数
    } else if (subindex == 1) {
        MEMCPY(pData, &LED_status, dataSize);  // 返回 LED 状态
    }
    return 0;  // 成功
}
```

#### 对象 0x7000 (输出对象)

```c
索引：0x7000
名称："Obj0x7000"
类型：RECORD
子条目数：1

SubIndex 0:
  - 类型：UNSIGNED8
  - 访问：只读
  - 值：0x01

SubIndex 1 (LED):
  - 类型：BOOLEAN
  - 访问：读写，RX-PDO 映射
  - 默认值：0x01
  - 写回调：WriteObject0x7000()
  
写操作实现：
UINT8 WriteObject0x7000(UINT16 index, UINT8 subindex,
                        UINT32 dataSize, UINT16 *pData)
{
    if (subindex == 0) {
        return ABORTIDX_READ_ONLY_ENTRY;  // SubIndex 0 不可写
    } else if (subindex == 1) {
        MEMCPY(&LED_status, pData, dataSize);  // 保存 LED 状态
        RGPIO_PinWrite(GPIO_LED, GPIO_LED_PIN, LED_status & 0x01);
    } else {
        return ABORTIDX_VALUE_EXCEEDED;  // 无效子索引
    }
    return 0;  // 成功
}
```

### 8.3 SDO 通信流程

**SDO 下载 (写) 示例：主站写入 0x7000:01 = 0x01**

```
1. 主站发送 SDO Download Request:
   ┌────────────────────────────────┐
   │ Index: 0x7000                  │
   │ SubIndex: 0x01                 │
   │ Command: 0x2F (Expedited)      │
   │ Data: 0x01000000               │
   └────────────────────────────────┘

2. 从站处理:
   MBX_ProcessCoE() → COE_SdoRequest()
   → OBJ_Write() → WriteObject0x7000()
   → 更新 LED_status → 驱动 GPIO

3. 从站响应 SDO Download Response:
   ┌────────────────────────────────┐
   │ Index: 0x7000                  │
   │ SubIndex: 0x01                 │
   │ Command: 0x60 (Response)       │
   │ Data: 0x00000000               │
   └────────────────────────────────┘
```

**SDO 上传 (读) 示例：主站读取 0x6000:01**

```
1. 主站发送 SDO Upload Request:
   ┌────────────────────────────────┐
   │ Index: 0x6000                  │
   │ SubIndex: 0x01                 │
   │ Command: 0x40 (Upload)         │
   └────────────────────────────────┘

2. 从站处理:
   MBX_ProcessCoE() → COE_SdoRequest()
   → OBJ_Read() → ReadObject0x6000()
   → 读取 LED_status

3. 从站响应 SDO Upload Response:
   ┌────────────────────────────────┐
   │ Index: 0x6000                  │
   │ SubIndex: 0x01                 │
   │ Command: 0x43 (Expedited)      │
   │ Data: LED_status 值            │
   └────────────────────────────────┘
```

### 8.4 对象字典初始化

```c
// objdef.c
void COE_ObjInit(void)
{
    // 1. 初始化标准对象
    InitStandardObjects();  // 0x1000-0x1FFF, 0x1Cxx
    
    // 2. 注册应用对象
    RegisterApplicationObjects(ApplicationObjDic);
    /*
     * ApplicationObjDic[] 包含:
     * - 0x1600: RxPDO 映射
     * - 0x1A00: TxPDO 映射
     * - 0x1C12: SM2 分配
     * - 0x1C13: SM3 分配
     * - 0x6000: LED 输入
     * - 0x7000: LED 输出
     * - 0xF000: 模块化设备配置
     */
    
    // 3. 设置默认值
    SetDefaultValues();
}
```

---

## 9. 中断处理机制

### 9.1 中断源概览

| 中断源 | NVIC IRQ | 优先级 | 处理函数 | 说明 |
|--------|----------|--------|----------|------|
| ECAT_INT | ECAT_INT_IRQn | 高 | ECAT_INT_IRQHandler | EtherCAT PDI 中断 |
| Sync0/1 | XBAR1_CH0_CH1_IRQn | 高 | XBAR1_CH0_CH1_IRQHandler | DC 同步中断 |
| Timer | GPT1_IRQn | 中 | GPT1_IRQHandler | 1ms 定时器中断 |

### 9.2 ECAT 中断处理

```c
// hardware_init.c
void ECAT_INT_IRQHandler(void)
{
    PDI_Isr();  // 调用 SSC 中断处理
    SDK_ISR_EXIT_BARRIER;
}

// ecatappl.c
void PDI_Isr(void)
{
    // 1. 读取 AL Event 寄存器
    UINT16 ALEvent = HW_GetALEventRegister_Isr();
    ALEvent = SWAPWORD(ALEvent);
    
    // 2. 处理 Sync1 事件
    if (ALEvent & SYNC1_EVENT) {
        Sync1_Isr();
        SyncAcknowledgePending = TRUE;
    }
    
    // 3. 处理 SM2 (输出) 事件
    if (bEscIntEnabled && (ALEvent & PROCESS_OUTPUT_EVENT)) {
        if (bDcRunning && bDcSyncActive) {
            u16SmSync0Counter = 0;  // 重置 Sync 计数器
        }
        
        bEcatFirstOutputsReceived = TRUE;
        
        if (bEcatOutputUpdateRunning) {
            PDO_OutputMapping();  // 处理输出数据
        } else {
            // 仅确认事件 (非 OP 状态)
            HW_EscReadDWordIsr(u32dummy, nEscAddrOutputData);
        }
        
        // SM Sync 模式下执行应用
        if (sSyncManOutPar.u16SyncType == SYNCTYPE_SM_SYNCHRON) {
            ECAT_Application();
        }
        
        // 处理输入 (SM Sync 模式)
        if (bEcatInputUpdateRunning && nPdInputSize > 0 &&
            (sSyncManInPar.u16SyncType == SYNCTYPE_SM_SYNCHRON ||
             sSyncManInPar.u16SyncType == SYNCTYPE_SM2_SYNCHRON)) {
            PDO_InputMapping();
        }
        
        // 检查周期超限
        ALEvent = HW_GetALEventRegister_Isr();
        if (ALEvent & PROCESS_OUTPUT_EVENT) {
            sSyncManOutPar.u16CycleExceededCounter++;
        }
    }
    
    // 4. 处理 Sync0 事件
    if (ALEvent & SYNC0_EVENT) {
        Sync0_Isr();
        SyncAcknowledgePending = TRUE;
    }
    
    // 5. 确认 Sync 事件
    if (SyncAcknowledgePending) {
        volatile UINT32 SyncState = 0;
        HW_EscReadDWord(SyncState, ESC_DC_SYNC_STATUS);
    }
    
    // 6. 更新同步错误状态
    COE_UpdateSyncErrorStatus();
}
```

### 9.3 Sync0 中断处理

```c
// ecatappl.c
void Sync0_Isr(void)
{
    // 1. 重置 Sync0 看门狗
    Sync0WdCounter = 0;
    
    if (bDcSyncActive) {
        // 2. 输入锁存检查
        BOOL bCallInputMapping = FALSE;
        if (bEcatInputUpdateRunning && LatchInputSync0Value > 0 && nPdInputSize > 0) {
            if (LatchInputSync0Value > LatchInputSync0Counter) {
                LatchInputSync0Counter++;
            }
            if (LatchInputSync0Value == LatchInputSync0Counter) {
                bCallInputMapping = TRUE;
            }
        }
        
        // 3. SM-Sync 监控
        if (u16SmSync0Value > 0) {
            if (u16SmSync0Counter > u16SmSync0Value) {
                // Sync 丢失，增加错误计数器
                if (nPdOutputSize > 0) {
                    sSyncManOutPar.u16SmEventMissedCounter += 3;
                }
            }
            u16SmSync0Counter++;
        }
        
        // 4. 执行应用逻辑
        ECAT_Application();
        
        // 5. 触发输入映射 (如果配置)
        if (bCallInputMapping) {
            PDO_InputMapping();
            if (LatchInputSync0Value == 1) {
                LatchInputSync0Counter = 0;
            }
        }
    }
    
    COE_UpdateSyncErrorStatus();
}
```

### 9.4 Sync1 中断处理

```c
// ecatappl.c
void Sync1_Isr(void)
{
    // 1. 重置 Sync1 看门狗
    Sync1WdCounter = 0;
    
    // 2. 输入映射 (如果配置为 Sync1 锁存)
    if (bEcatInputUpdateRunning && nPdInputSize > 0 &&
        sSyncManInPar.u16SyncType == SYNCTYPE_DCSYNC1 &&
        LatchInputSync0Value == 0) {
        PDO_InputMapping();
    }
    
    // 3. 重置 Sync0 锁存计数器
    LatchInputSync0Counter = 0;
}
```

### 9.5 定时器中断处理

```c
// hardware_init.c
void GPT1_IRQHandler(void)
{
    // 1. 清除中断标志
    GPT_ClearStatusFlags(GPT1, kGPT_OutputCompare1Flag);
    
    // 2. 调用定时器检查 (如果使能)
#if ECAT_TIMER_INT
    ECAT_CheckTimer();
#endif
    
    // 3. 递增定时器计数
    EcatTimerCnt++;
    
    SDK_ISR_EXIT_BARRIER;
}

// ecatappl.c
void ECAT_CheckTimer(void)
{
    // 1. 递减状态机超时计数器
    if (bEcatWaitForAlControlRes && (EsmTimeoutCounter > 0)) {
        EsmTimeoutCounter--;
    }
    
    // 2. 更新 LED 指示
    ECAT_SetLedIndication();
    
    // 3. 检查 DC 看门狗
    DC_CheckWatchdog();
    
    // 4. 递增诊断计数器
    // ...
}
```

---

## 10. 同步与看门狗

### 10.1 同步模式配置

**通过 0x1C32 (Sync0 配置) 和 0x1C33 (Sync1 配置):**

```
0x1C32: Sync0 配置
  SubIndex 1 (Sync Type):
    0x00: FreeRun (无同步)
    0x01: SM Synchronous (SM 事件同步)
    0x10: DC Sync0 (分布式时钟 Sync0)
    0x20: DC Sync1 (分布式时钟 Sync1)
  
  SubIndex 2 (Cycle Time): Sync0 周期时间 (ns)
  SubIndex 10 (Shift Time): Shift 时间 (ns)

0x1C33: Sync1 配置
  SubIndex 1 (Sync Type): 同上
  SubIndex 2 (Cycle Time): Sync1 周期时间 (ns)
```

### 10.2 各种同步模式详解

#### 模式 1: FreeRun (无同步)

```
特点:
- bEscIntEnabled = FALSE
- bDcSyncActive = FALSE
- 应用在主循环中执行

时序:
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  MainLoop   │  MainLoop   │  MainLoop   │  MainLoop   │
│  - ECAT_    │  - ECAT_    │  - ECAT_    │  - ECAT_    │
│    Application()          │    Application()          │
│  - PDO_In/  │  - PDO_In/  │  - PDO_In/  │  - PDO_In/  │
│    OutMap   │    OutMap   │    OutMap   │    OutMap   │
└─────────────┴─────────────┴─────────────┴─────────────┘
     ↑               ↑               ↑               ↑
     │               │               │               │
  SM 事件        SM 事件        SM 事件        SM 事件
  (轮询)        (轮询)        (轮询)        (轮询)

周期：取决于主循环执行速度 (典型 100μs-1ms)
```

#### 模式 2: SM Synchronous (SM 事件同步)

```
特点:
- bEscIntEnabled = TRUE
- bDcSyncActive = FALSE
- 应用在 SM2 中断中执行

时序:
┌─────┬─────────┬─────┬─────┬─────┬─────────┬─────┬─────┐
│Idle │ SM2 ISR │Idle │Idle │Idle │ SM2 ISR │Idle │Idle │
│     │ -PDO_Out│     │     │     │ -PDO_Out│     │     │
│     │ -ECAT_  │     │     │     │ -ECAT_  │     │     │
│     │  App    │     │     │     │  App    │     │     │
│     │ -PDO_In │     │     │     │ -PDO_In │     │     │
└─────┴─────────┴─────┴─────┴─────┴─────────┴─────┴─────┘
      ↑                               ↑
      │                               │
   SM2 事件                       SM2 事件
   (中断触发)                   (中断触发)

周期：由主站配置的 SM 刷新周期决定
```

#### 模式 3: DC Sync0 (分布式时钟 Sync0)

```
特点:
- bEscIntEnabled = TRUE
- bDcSyncActive = TRUE
- 应用在 Sync0 中断中执行
- 最高精度同步

时序:
┌───┬──────┬───────┬───┬───┬──────┬───────┬───┬───┬──────┐
│   │Sync0 │       │   │   │Sync0  │       │   │   │Sync0 │
│   │ ISR  │       │   │   │ ISR   │       │   │   │ ISR  │
│   │-App  │       │   │   │-App   │       │   │   │-App  │
│   │-InMap│       │   │   │-InMap │       │   │   │-InMap│
├───┼──────┼───────┼───┼───┼──────┼───────┼───┼───┼──────┤
│   │      │SM2 ISR│   │   │       │SM2 ISR │   │   │      │
│   │      │-OutMap│   │   │       │-OutMap │   │   │      │
└───┴──────┴───────┴───┴───┴──────┴───────┴───┴───┴──────┘
    ↑               ↑       ↑               ↑
    │               │       │               │
  Sync0          SM2     Sync0          SM2
  (应用周期)   (输出)   (应用周期)   (输出)

周期：由 DC Sync0 周期决定 (典型 125μs, 250μs, 500μs, 1ms)
相位：Sync0 相对于 SM2 有固定相位偏移 (Shift Time)
```

### 10.3 看门狗机制

#### 过程数据看门狗

```c
// ecatslv.c
void DC_CheckWatchdog(void)
{
    static UINT16 WdCounter = 0;
    
    // 1. 检查 Sync 看门狗
    if (bDcSyncActive) {
        // Sync0 看门狗
        if (Sync0WdCounter > Sync0WdLimit) {
            // Sync0 丢失
            TriggerWatchdogError();
        }
        
        // Sync1 看门狗
        if (Sync1WdCounter > Sync1WdLimit) {
            // Sync1 丢失
            TriggerWatchdogError();
        }
    }
    
    // 2. 检查 SM 看门狗 (如果使能)
    if (SmWatchdogEnabled) {
        if (SmWdCounter > SmWdLimit) {
            // SM 事件丢失
            TriggerWatchdogError();
        }
    }
    
    // 3. 递增计数器
    WdCounter++;
    Sync0WdCounter++;
    Sync1WdCounter++;
}

// 看门狗超时处理
void TriggerWatchdogError(void)
{
    // 1. 设置本地错误标志
    bLocalErrorFlag = TRUE;
    
    // 2. 触发状态转换 (OP → SafeOP)
    ECAT_StateChange(STATE_SAFEOP, ALSTATUSCODE_WATCHDOG);
    
    // 3. 关闭输出
    APPL_StopOutputHandler();
    bEcatOutputUpdateRunning = FALSE;
    
    // 4. 重置输出到安全状态
    memset(aPdOutputData, 0, nPdOutputSize);
}
```

#### 看门狗配置参数

```
0x10F1: Watchdog 配置
  SubIndex 1: Watchdog 模式
    0: 禁用
    1: 使能 (Process Data)
    2: 使能 (Sync0/1)
  
  SubIndex 2: Sync Error Limit (默认 10)
    - 允许的连续 Sync 丢失次数
  
  SubIndex 3: Watchdog Time (μs)
    - 看门狗超时时间

0x10F3: Sync Error 配置
  SubIndex 1: Sync Error Counter
    - 当前 Sync 错误计数
  
  SubIndex 2: Sync Error Limit
    - 最大允许错误数
```

---

## 11. 硬件抽象层

### 11.1 ESC 访问宏

```c
// ecat_hw.h

// AL Event 寄存器读取
#define HW_GetALEventRegister()     ECAT_GetALEventRegister(ECAT)
#define HW_GetALEventRegister_Isr() ECAT_GetALEventRegister(ECAT)

// ESC 通用读写
#define HW_EscRead(pData, Address, Len)    ECAT_EscRead(ECAT, pData, Address, Len)
#define HW_EscWrite(pData, Address, Len)   ECAT_EscWrite(ECAT, pData, Address, Len)

// ESC 中断安全读写
#define HW_EscReadIsr(pData, Address, Len)    ECAT_EscRead(ECAT, pData, Address, Len)
#define HW_EscWriteIsr(pData, Address, Len)   ECAT_EscWrite(ECAT, pData, Address, Len)

// 32 位访问
#define HW_EscReadDWord(DWordValue, Address)    ECAT_EscReadDWord(ECAT, DWordValue, Address)
#define HW_EscWriteDWord(DWordValue, Address)   ECAT_EscWriteDWord(ECAT, DWordValue, Address)

// 邮箱内存访问
#define HW_EscReadMbxMem(pData, Address, Len)   ECAT_EscRead(ECAT, pData, Address, Len)
#define HW_EscWriteMbxMem(pData, Address, Len)  ECAT_EscWrite(ECAT, pData, Address, Len)
```

### 11.2 ESC 寄存器映射

```c
// 关键 ESC 寄存器偏移 (ecat_def.h)

// AL Status 相关
#define ESC_AL_STATUS_OFFSET        0x0130  // AL Status 寄存器
#define ESC_AL_STATUS_CODE_OFFSET   0x0134  // AL Status Code 寄存器
#define ESC_AL_CONTROL_OFFSET       0x0120  // AL Control 寄存器
#define ESC_AL_EVENT_MASK_OFFSET    0x0204  // AL Event Mask 寄存器

// System Time
#define ESC_SYSTEMTIME_OFFSET       0x0910  // 系统时间 (64 位)

// DC 相关
#define ESC_DC_SYNC_STATUS          0x09A0  // Sync 状态寄存器
#define ESC_DC_SYSTEM_TIME          0x0910  // DC 系统时间

// SyncManager 控制
#define ESC_SM0_PHYSICAL_START      0x0800  // SM0 起始地址
#define ESC_SM1_PHYSICAL_START      0x0900  // SM1 起始地址
#define ESC_SM2_PHYSICAL_START      0x1000  // SM2 起始地址
#define ESC_SM3_PHYSICAL_START      0x2000  // SM3 起始地址

// EEPROM 仿真
#define ESC_EEPROM_CONTROL          0x0502  // EEPROM 控制寄存器
#define ESC_EEPROM_DATA             0x0508  // EEPROM 数据寄存器
```

### 11.3 中断控制

```c
// hardware_init.c

// 使能所有 ESC 相关中断
void ENABLE_ESC_INT(void)
{
    NVIC_EnableIRQ(ECAT_INT_IRQn);         // PDI 中断
    NVIC_EnableIRQ(XBAR1_CH0_CH1_IRQn);    // Sync0/1 中断
    NVIC_EnableIRQ(GPT1_IRQn);             // 定时器中断
}

// 禁用所有 ESC 相关中断
void DISABLE_ESC_INT(void)
{
    NVIC_DisableIRQ(XBAR1_CH0_CH1_IRQn);
    NVIC_DisableIRQ(ECAT_INT_IRQn);
    NVIC_DisableIRQ(GPT1_IRQn);
}

// AL Event Mask 配置
// 0x93 = Bit0(SM0) + Bit1(SM1) + Bit4(SM2) + Bit7(Latch) + Bit8(DC Sync)
#define AL_EVENT_MASK_INIT  0x0093

// 常用事件掩码
#define PROCESS_OUTPUT_EVENT  0x0010  // SM2 事件
#define PROCESS_INPUT_EVENT   0x0020  // SM3 事件
#define SYNC0_EVENT           0x0100  // Sync0 事件
#define SYNC1_EVENT           0x0200  // Sync1 事件
```

### 11.4 定时器实现

```c
// hardware_init.c

// 全局定时器计数
UINT32 EcatTimerCnt;

// 获取当前定时器值 (单位：ECAT_TIMER_INC_P_MS)
UINT16 HW_GetTimer(void)
{
    return EcatTimerCnt;
}

// 清除定时器
void HW_ClearTimer(void)
{
    EcatTimerCnt = 0;
}

// GPT1 配置:
// - 时钟源：IPG_CLK_ROOT (假设 120MHz)
// - 分频：100 → 1.2MHz (0.833μs/tick)
// - 比较值：1.2MHz / 100000 = 12 → 10μs 中断
// - ECAT_TIMER_INC_P_MS = 0x01 → 每 10 次中断 = 100μs
//   或根据实际配置调整为 1ms
```

---

## 12. 调试与故障排查

### 12.1 调试工具

#### J-Link + J-Scope

```
连接方式:
J-Link → SWD 接口
  - SWDIO: Pin XX
  - SWCLK: Pin XX
  - GND
  - 3.3V (可选)

J-Scope 配置:
- 采样率：10MS/s
- 触发：GPIO 翻转或变量监视
- 通道：
  CH1: LED_status 变化
  CH2: PDO_OutputMapping 执行
  CH3: PDO_InputMapping 执行
  CH4: ECAT_Application 执行
```

#### 调试打印

```c
// 启用调试打印
#define PRINTF(...)  DbgConsole_Printf(__VA_ARGS__)

// 关键位置添加打印
void PDO_OutputMapping(void)
{
    PRINTF("PDO_Out: Size=%d, Data=0x%02X\r\n", nPdOutputSize, aPdOutputData[0]);
    // ...
}

void ECAT_Main(void)
{
    PRINTF("ECAT_State: %d, ALCode=0x%04X\r\n", CurrentState, ALStatusCode);
    // ...
}
```

### 12.2 常见问题排查表

| 问题现象 | 可能原因 | 排查步骤 | 解决方案 |
|---------|---------|---------|---------|
| 无法进入 PREOP | 邮箱配置错误 | 1. 检查 SM0/SM1 配置<br>2. 验证邮箱大小<br>3. 查看 AL Status Code | 修正 SyncManager 配置 |
| 无法进入 SAFEOP | 输入配置错误 | 1. 检查 SM3 配置<br>2. 验证 PDO 映射<br>3. 查看 0x1C13 | 修正输入 PDO 配置 |
| 无法进入 OP | 输出配置错误 | 1. 检查 SM2 配置<br>2. 验证 PDO 映射<br>3. 查看 0x1C12 | 修正输出 PDO 配置 |
| 频繁掉到 SafeOP | 看门狗超时 | 1. 检查 Sync 事件<br>2. 验证周期时间<br>3. 查看 0x10F1 | 调整看门狗时间或修复同步 |
| PDO 数据不更新 | 映射错误 | 1. 检查 PDO 映射对象<br>2. 验证 APPL_Map 函数<br>3. 抓包分析 | 修正 PDO 映射配置 |
| LED 不亮 | GPIO 配置错误 | 1. 检查引脚复用<br>2. 验证 GPIO 初始化<br>3. 测量电压 | 修正 pin_mux 配置 |
| 通信不稳定 | PHY 配置问题 | 1. 检查 RMII 时钟<br>2. 验证 MDIO 配置<br>3. 查看误码率 | 优化 PHY 配置 |
| Sync 丢失 | DC 配置错误 | 1. 检查 Sync 类型<br>2. 验证周期配置<br>3. 查看 0x1C32/33 | 修正 DC 配置 |

### 12.3 关键寄存器检查点

#### 启动后检查

```
1. AL Status (0x130): 应为 0x01 (INIT)
2. AL Status Code (0x134): 应为 0x0000
3. DL Status (0x110): 检查链路状态
   - Bit0: Physical Link Active
   - Bit8: COM Gateway Active

4. SM0 Control (0x800): 
   - Bit4: Direction = 1 (Write)
   - Bit6-7: Mode = 01 (Mailbox)

5. SM1 Control (0x810):
   - Bit4: Direction = 0 (Read)
   - Bit6-7: Mode = 01 (Mailbox)
```

#### 运行中检查

```
1. AL Event (0x220): 当前待处理事件
   - Bit0-1: SM0/SM1 邮箱事件
   - Bit4-5: SM2/SM3 过程数据事件
   - Bit8-9: Sync0/1 事件

2. AL Event Mask (0x204): 中断屏蔽配置
   - 正常运行时应使能相关事件

3. DC Sync Status (0x9A0):
   - Bit0: Sync0 状态
   - Bit1: Sync1 状态

4. 对象字典验证:
   - 0x1C12:00: SM2 分配激活
   - 0x1C13:00: SM3 分配激活
   - 0x1600:01: RxPDO 映射正确
   - 0x1A00:01: TxPDO 映射正确
```

### 12.4 Wireshark 抓包分析

#### 捕获设置

```
接口：连接到 EtherCAT 网络的网卡
过滤器：ethercat 或 udp.port == 34980

显示过滤器:
- ethercat.cmd == 0x01 (APWR)
- ethercat.idx == 0x0130 (AL Status)
- ethercat.data contains 00:08 (OP 状态)
```

#### 典型报文分析

**状态转换请求：**
```
Frame XX: EtherCAT Protocol
    Command: APRW (Auto Increment Physical Read Write)
    Index: 0x0120 (AL Control)
    Data: 0x0400 (请求 SAFEOP)
    
Response:
    Command: APRW
    Index: 0x0120
    Data: 0x0400 (确认 SAFEOP)
```

**PDO 数据交换：**
```
Frame XX: EtherCAT Protocol
    Command: APWR (Auto Increment Physical Write)
    Index: 0x1000 (SM2 Output)
    Data: 01 00 00 ... (LED=ON)
    
Frame YY: EtherCAT Protocol
    Command: APRD (Auto Increment Physical Read)
    Index: 0x2000 (SM3 Input)
    Data: 01 00 00 ... (LED 状态反馈)
```

### 12.5 性能优化建议

```
1. 减少主循环开销:
   - 将非必要操作移至后台
   - 优化 PDO 映射计算
   - 使用 DMA 传输 (如果支持)

2. 中断优化:
   - 合理设置中断优先级
   - 减少 ISR 执行时间
   - 使用嵌套向量中断

3. 内存优化:
   - 将频繁访问变量放入 DTCM
   - 对齐数据结构
   - 避免动态分配

4. 同步优化:
   - 选择合适的 Sync 模式
   - 优化 Shift Time 配置
   - 减少抖动
```

---

## 附录 A: 关键宏定义汇总

```c
// ecat_def.h 中的关键配置

#define USE_DEFAULT_MAIN                1   // 使用默认 main 函数
#define COE_SUPPORTED                   1   // 支持 CoE 协议
#define MAX_PD_INPUT_SIZE               0x40  // 64 字节输入
#define MAX_PD_OUTPUT_SIZE              0x40  // 64 字节输出
#define ECAT_TIMER_INC_P_MS             0x01  // 定时器增量

#define SYNCTYPE_FREE_RUN               0x00
#define SYNCTYPE_SM_SYNCHRON            0x01
#define SYNCTYPE_DCSYNC0                0x10
#define SYNCTYPE_DCSYNC1                0x20

#define STATE_INIT                      0x01
#define STATE_PREOP                     0x02
#define STATE_SAFEOP                    0x04
#define STATE_OP                        0x08
#define STATE_BOOTSTRAP                 0x07

#define ALSTATUSCODE_NOERROR            0x0000
#define ALSTATUSCODE_WATCHDOG           0x0032
#define ALSTATUSCODE_INVALIDINPUTMAPPING 0x0033
#define ALSTATUSCODE_INVALIDOUTPUTMAPPING 0x0034
```

## 附录 B: 参考文档

1. **EtherCAT 协议规范**: ETG.1000, ETG.1020
2. **Beckhoff SSC 文档**: ET9300, SSC V5.13 Release Notes
3. **NXP RT1180 参考手册**: IMXRT1180RM
4. **CiA 402 规范**: 设备配置文件
5. **IEEE 802.3**: Ethernet 物理层标准

---

*文档版本：v1.0*
*生成日期：2024*
*基于工程：evkmimxrt1180_ecat_digital_io_cm33*
