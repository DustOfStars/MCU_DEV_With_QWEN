################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../component/silicon_id/fsl_silicon_id.c \
../component/silicon_id/fsl_silicon_id_soc.c 

C_DEPS += \
./component/silicon_id/fsl_silicon_id.d \
./component/silicon_id/fsl_silicon_id_soc.d 

OBJS += \
./component/silicon_id/fsl_silicon_id.o \
./component/silicon_id/fsl_silicon_id_soc.o 


# Each subdirectory must supply rules for building sources it contributes
component/silicon_id/%.o: ../component/silicon_id/%.c component/silicon_id/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: MCU C Compiler'
	arm-none-eabi-gcc -std=gnu99 -D__REDLIB__ -DCPU_MIMXRT1189CVM8C -DCPU_MIMXRT1189CVM8C_cm33 -DMCUXPRESSO_SDK -DXIP_EXTERNAL_FLASH=1 -DSDK_DEBUGCONSOLE_UART -DSERIAL_PORT_TYPE_UART=1 -DPRINTF_ADVANCED_ENABLE=1 -DSDK_DEBUGCONSOLE=1 -DMCUX_META_BUILD -DMIMXRT1189_cm33_SERIES -DXIP_BOOT_HEADER_ENABLE=1 -DCR_INTEGER_PRINTF -DPRINTF_FLOAT_ENABLE=0 -D__MCUXPRESSO -D__USE_CMSIS -DDEBUG -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\xip" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\drivers" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\CMSIS" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\CMSIS\m-profile" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\device" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\device\periph" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\drivers\netc" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\utilities" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\utilities\str" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component\silicon_id" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\utilities\debug_console_lite" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component\uart" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\component\phy" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source\SSC" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source\SSC\Src" -I"C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\board" -O0 -fno-common -g3 -gdwarf-4 -mcpu=cortex-m33 -c -ffunction-sections -fdata-sections -fno-builtin -imacros "C:\2026HandsOn_Workspace\evkmimxrt1180_ecat_digital_io_cm33\source\mcux_config.h" -fmerge-constants -fmacro-prefix-map="$(<D)/"= -mcpu=cortex-m33 -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -D__REDLIB__ -fstack-usage -specs=redlib.specs -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


clean: clean-component-2f-silicon_id

clean-component-2f-silicon_id:
	-$(RM) ./component/silicon_id/fsl_silicon_id.d ./component/silicon_id/fsl_silicon_id.o ./component/silicon_id/fsl_silicon_id_soc.d ./component/silicon_id/fsl_silicon_id_soc.o

.PHONY: clean-component-2f-silicon_id

