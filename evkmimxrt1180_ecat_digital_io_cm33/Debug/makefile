################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include xip/subdir.mk
-include utilities/str/subdir.mk
-include utilities/debug_console_lite/subdir.mk
-include utilities/subdir.mk
-include startup/subdir.mk
-include source/SSC/Src/subdir.mk
-include source/subdir.mk
-include drivers/netc/netc_hw/subdir.mk
-include drivers/netc/subdir.mk
-include drivers/subdir.mk
-include device/subdir.mk
-include component/uart/subdir.mk
-include component/silicon_id/subdir.mk
-include component/phy/subdir.mk
-include board/subdir.mk
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := evkmimxrt1180_ecat_digital_io_cm33
BUILD_ARTIFACT_EXTENSION := axf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 

# All Target
all:
	+@$(MAKE) --no-print-directory main-build && $(MAKE) --no-print-directory post-build

# Main-build Target
main-build: evkmimxrt1180_ecat_digital_io_cm33.axf

# Tool invocations
evkmimxrt1180_ecat_digital_io_cm33.axf: $(OBJS) $(USER_OBJS) makefile $(OPTIONAL_TOOL_DEPS)
	@echo 'Building target: $@'
	@echo 'Invoking: MCU Linker'
	arm-none-eabi-gcc -nostdlib -Xlinker -no-warn-rwx-segments -Xlinker -Map="evkmimxrt1180_ecat_digital_io_cm33.map" -Xlinker --gc-sections -Xlinker -print-memory-usage -Xlinker --sort-section=alignment -Xlinker --cref -mcpu=cortex-m33 -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -T evkmimxrt1180_ecat_digital_io_cm33_Debug.ld -o "evkmimxrt1180_ecat_digital_io_cm33.axf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) evkmimxrt1180_ecat_digital_io_cm33.axf
	-@echo ' '

post-build:
	-@echo 'Performing post-build steps'
	-[ ! -f ../scripts/image_hash_tool.py ] && : || ( echo "win32" | grep -q win* && py -3 ../scripts/image_hash_tool.py -a sha512 -x .boot_hdr -x .ARM.exidx -s .boot_hdr -o 0x1030 -l 64 -p 0x00 "evkmimxrt1180_ecat_digital_io_cm33.axf" || python3 ../scripts/image_hash_tool.py -a sha512 -x .boot_hdr -x .ARM.exidx -s .boot_hdr -o 0x1030 -l 64 -p 0x00 "evkmimxrt1180_ecat_digital_io_cm33.axf" )
	-@echo ' '

.PHONY: all clean dependents main-build post-build

-include ../makefile.targets
