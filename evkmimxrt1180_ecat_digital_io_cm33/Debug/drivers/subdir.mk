################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../drivers/fsl_cache.c \
../drivers/fsl_clock.c \
../drivers/fsl_common.c \
../drivers/fsl_common_arm.c \
../drivers/fsl_dcdc.c \
../drivers/fsl_ecat.c \
../drivers/fsl_ele_base_api.c \
../drivers/fsl_gpc.c \
../drivers/fsl_gpt.c \
../drivers/fsl_lpi2c.c \
../drivers/fsl_lpuart.c \
../drivers/fsl_memory.c \
../drivers/fsl_msgintr.c \
../drivers/fsl_pmu.c \
../drivers/fsl_rgpio.c \
../drivers/fsl_s3mu.c \
../drivers/fsl_soc_src.c \
../drivers/fsl_xbar.c 

C_DEPS += \
./drivers/fsl_cache.d \
./drivers/fsl_clock.d \
./drivers/fsl_common.d \
./drivers/fsl_common_arm.d \
./drivers/fsl_dcdc.d \
./drivers/fsl_ecat.d \
./drivers/fsl_ele_base_api.d \
./drivers/fsl_gpc.d \
./drivers/fsl_gpt.d \
./drivers/fsl_lpi2c.d \
./drivers/fsl_lpuart.d \
./drivers/fsl_memory.d \
./drivers/fsl_msgintr.d \
./drivers/fsl_pmu.d \
./drivers/fsl_rgpio.d \
./drivers/fsl_s3mu.d \
./drivers/fsl_soc_src.d \
./drivers/fsl_xbar.d 

OBJS += \
./drivers/fsl_cache.o \
./drivers/fsl_clock.o \
./drivers/fsl_common.o \
./drivers/fsl_common_arm.o \
./drivers/fsl_dcdc.o \
./drivers/fsl_ecat.o \
./drivers/fsl_ele_base_api.o \
./drivers/fsl_gpc.o \
./drivers/fsl_gpt.o \
./drivers/fsl_lpi2c.o \
./drivers/fsl_lpuart.o \
./drivers/fsl_memory.o \
./drivers/fsl_msgintr.o \
./drivers/fsl_pmu.o \
./drivers/fsl_rgpio.o \
./drivers/fsl_s3mu.o \
./drivers/fsl_soc_src.o \
./drivers/fsl_xbar.o 


# Each subdirectory must supply rules for building sources it contributes
drivers/%.o: ../drivers/%.c drivers/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: MCU C Compiler'
	arm-none-eabi-gcc -std=gnu99 -D__REDLIB__ -DCPU_MIMXRT1189CVM8C -DCPU_MIMXRT1189CVM8C_cm33 -DMCUXPRESSO_SDK -DXIP_EXTERNAL_FLASH=1 -DSDK_DEBUGCONSOLE_UART -DSERIAL_PORT_TYPE_UART=1 -DPRINTF_ADVANCED_ENABLE=1 -DSDK_DEBUGCONSOLE=1 -DMCUX_META_BUILD -DMIMXRT1189_cm33_SERIES -DXIP_BOOT_HEADER_ENABLE=1 -DCR_INTEGER_PRINTF -DPRINTF_FLOAT_ENABLE=0 -D__MCUXPRESSO -D__USE_CMSIS -DDEBUG -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\xip" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\drivers" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\CMSIS" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\CMSIS\m-profile" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\device" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\device\periph" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\drivers\netc" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\utilities" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\utilities\str" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component\silicon_id" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\utilities\debug_console_lite" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component\uart" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component\phy" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source\SSC" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source\SSC\Src" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\board" -O0 -fno-common -g3 -gdwarf-4 -mcpu=cortex-m33 -c -ffunction-sections -fdata-sections -fno-builtin -imacros "C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source\mcux_config.h" -fmerge-constants -fmacro-prefix-map="$(<D)/"= -mcpu=cortex-m33 -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -D__REDLIB__ -fstack-usage -specs=redlib.specs -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


clean: clean-drivers

clean-drivers:
	-$(RM) ./drivers/fsl_cache.d ./drivers/fsl_cache.o ./drivers/fsl_clock.d ./drivers/fsl_clock.o ./drivers/fsl_common.d ./drivers/fsl_common.o ./drivers/fsl_common_arm.d ./drivers/fsl_common_arm.o ./drivers/fsl_dcdc.d ./drivers/fsl_dcdc.o ./drivers/fsl_ecat.d ./drivers/fsl_ecat.o ./drivers/fsl_ele_base_api.d ./drivers/fsl_ele_base_api.o ./drivers/fsl_gpc.d ./drivers/fsl_gpc.o ./drivers/fsl_gpt.d ./drivers/fsl_gpt.o ./drivers/fsl_lpi2c.d ./drivers/fsl_lpi2c.o ./drivers/fsl_lpuart.d ./drivers/fsl_lpuart.o ./drivers/fsl_memory.d ./drivers/fsl_memory.o ./drivers/fsl_msgintr.d ./drivers/fsl_msgintr.o ./drivers/fsl_pmu.d ./drivers/fsl_pmu.o ./drivers/fsl_rgpio.d ./drivers/fsl_rgpio.o ./drivers/fsl_s3mu.d ./drivers/fsl_s3mu.o ./drivers/fsl_soc_src.d ./drivers/fsl_soc_src.o ./drivers/fsl_xbar.d ./drivers/fsl_xbar.o

.PHONY: clean-drivers

