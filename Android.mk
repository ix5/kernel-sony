# Copyright (C) 2012 The CyanogenMod Project
# Copyright (C) 2015 Chirayu Desai
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Android makefile to build kernel as a part of Android Build

ifeq ($(BUILD_KERNEL),true)
ifeq ($(PRODUCT_PLATFORM_SOD),true)
ifeq ($(SOMC_KERNEL_VERSION),4.9)

KERNEL_SRC := $(shell pwd)/$(call my-dir)

## Internal variables
#ifeq ($(OUT_DIR),out)
#KERNEL_OUT := $(shell pwd)/$(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
#else
#KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
#endif
#KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_OUT := $(shell pwd)/$(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_OUT_STAMP := $(KERNEL_OUT)/.mkdir_stamp

TARGET_KERNEL_ARCH := $(strip $(TARGET_KERNEL_ARCH))
ifeq ($(TARGET_KERNEL_ARCH),)
KERNEL_ARCH := $(TARGET_ARCH)
else
KERNEL_ARCH := $(TARGET_KERNEL_ARCH)
endif

# kernel configuration - mandatory:
TARGET_KERNEL_CONFIG ?= $(notdir $(wildcard $(KERNEL_SRC)/arch/$(KERNEL_ARCH)/configs/aosp_*_$(TARGET_DEVICE)_defconfig))
KERNEL_DEFCONFIG := $(TARGET_KERNEL_CONFIG)

KERNEL_DEFCONFIG_ARCH := $(KERNEL_ARCH)
KERNEL_DEFCONFIG_SRC := $(KERNEL_SRC)/arch/$(KERNEL_DEFCONFIG_ARCH)/configs/$(KERNEL_DEFCONFIG)

TARGET_KERNEL_HEADER_ARCH := $(strip $(TARGET_KERNEL_HEADER_ARCH))
ifeq ($(TARGET_KERNEL_HEADER_ARCH),)
KERNEL_HEADER_ARCH := $(KERNEL_ARCH)
else
KERNEL_HEADER_ARCH := $(TARGET_KERNEL_HEADER_ARCH)
endif

KERNEL_HEADER_DEFCONFIG := $(strip $(KERNEL_HEADER_DEFCONFIG))
ifeq ($(KERNEL_HEADER_DEFCONFIG),)
KERNEL_HEADER_DEFCONFIG := $(KERNEL_DEFCONFIG)
endif

# BOARD_KERNEL_IMAGE_NAME=Image.gz-dtb
TARGET_PREBUILT_INT_KERNEL_TYPE := $(BOARD_KERNEL_IMAGE_NAME)
#ifneq ($(BOARD_KERNEL_IMAGE_NAME),)
#  TARGET_PREBUILT_INT_KERNEL_TYPE := $(BOARD_KERNEL_IMAGE_NAME)
#else
#  ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
#    TARGET_PREBUILT_INT_KERNEL_TYPE := Image
#  else
#    ifeq ($(KERNEL_ARCH),arm64)
#      TARGET_PREBUILT_INT_KERNEL_TYPE := Image.gz
#    else
#      TARGET_PREBUILT_INT_KERNEL_TYPE := zImage
#    endif
#  endif
#endif

TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/$(TARGET_PREBUILT_INT_KERNEL_TYPE)

KERNEL_DTB := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/dts/qcom
KERNEL_DTB_OUT := $(PRODUCT_OUT)/dtbs

ifneq ($(BOARD_DTBO_IMAGE_NAME),)
  TARGET_PREBUILT_INT_DTBO_NAME := $(BOARD_DTBO_IMAGE_NAME)
else
  TARGET_PREBUILT_INT_DTBO_NAME := dtbo-$(KERNEL_ARCH).img
endif

KERNEL_DTBO_OUT := $(PRODUCT_OUT)/$(TARGET_PREBUILT_INT_DTBO_NAME)

# Clear this first to prevent accidental poisoning from env
MAKE_FLAGS :=

ifeq ($(KERNEL_ARCH),arm64)
  # Avoid "unsupported RELA relocation: 311" errors (R_AARCH64_ADR_GOT_PAGE)
  MAKE_FLAGS += CFLAGS_MODULE="-fno-pic"
  # TARGET_ARCH=arm64
  #ifeq ($(TARGET_ARCH),arm)
  #  KERNEL_CONFIG_OVERRIDE := CONFIG_ANDROID_BINDER_IPC_32BIT=y
  #endif
endif



# TARGET_PREBUILT_INT_KERNEL=$(KERNEL_OUT)/arch/arm64/boot/Image.gz-dtb
KERNEL_BIN := $(TARGET_PREBUILT_INT_KERNEL)

KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_HEADERS_INSTALL_STAMP := $(KERNEL_OUT)/.headers_install_stamp

KERNEL_MODULES_INSTALL := system
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules

# Target architecture cross compile
# TARGET_KERNEL_CROSS_COMPILE_PREFIX=aarch64-linux-android-
TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_PREFIX))
#ifeq ($(TARGET_KERNEL_CROSS_COMPILE_PREFIX),)
#KERNEL_TOOLCHAIN_PREFIX ?= arm-eabi-
#else
#KERNEL_TOOLCHAIN_PREFIX ?= $(TARGET_KERNEL_CROSS_COMPILE_PREFIX)
#endif
KERNEL_TOOLCHAIN_PREFIX ?= $(TARGET_KERNEL_CROSS_COMPILE_PREFIX)

# clang-r365631 is clang 9.0.6

#export GCC_CC=../../prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
#export CLANG_CC=../../prebuilts/clang/host/linux-x86/clang-4691093/bin/clang
#export CROSS_COMPILE_ARM32=../../prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

CLANG_CC := $(shell pwd)/prebuilts/clang/host/linux-x86/clang-r365631/bin/clang
CLANG_CCXX := $(shell pwd)/prebuilts/clang/host/linux-x86/clang-r365631/bin/clang++

#KERNEL_TOOLCHAIN := $(shell pwd)/prebuilts/clang/host/linux-x86/clang-r365631/bin/clang
KERNEL_TOOLCHAIN := $(shell pwd)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin

# KERNEL_TOOLCHAIN most likely empty
#ifeq ($(KERNEL_TOOLCHAIN),)
#KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN_PREFIX)
#else
#ifneq ($(KERNEL_TOOLCHAIN_PREFIX),)
#KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)
#endif
#endif
KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)

# If building for 64-bits with VDSO32 support - 32-bit toolchain here
# Also, if building for AArch64, preferrably set an AArch32 toolchain here.
# TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX=arm-linux-androideabi-
TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX))
#ifeq ($(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX),)
#KERNEL_TOOLCHAIN_32BITS_PREFIX ?= arm-linux-androideabi-
#else
#KERNEL_TOOLCHAIN_32BITS_PREFIX ?= $(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX)
#endif

ifeq ($(KERNEL_TOOLCHAIN_32BITS),)
KERNEL_TOOLCHAIN_32BITS_PATH := $(KERNEL_TOOLCHAIN_32BITS_PREFIX)
else
ifneq ($(KERNEL_TOOLCHAIN_32BITS_PREFIX),)
KERNEL_TOOLCHAIN_32BITS_PATH := $(KERNEL_TOOLCHAIN_32BITS)/$(KERNEL_TOOLCHAIN_32BITS_PREFIX)
endif
endif

ifneq ($(USE_CCACHE),)
    #ccache := $(shell pwd)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache
    # Prebuilt ccache is no longer shipped with Android since Q
    ccache := /usr/bin/ccache
    # Check that the executable is here.
    ccache := $(strip $(wildcard $(ccache)))
endif

#KERNEL_CROSS_COMPILE := CROSS_COMPILE="$(ccache) $(KERNEL_TOOLCHAIN_PATH)"
KERNEL_CROSS_COMPILE := CC="$(CLANG_CC)" CLANG_TRIPLE="aarch64-linux-gnu" CLANG_CC="$(CLANG_CC)" CLANG_CCXX="$(CLANG_CCXX)" CROSS_COMPILE="$(KERNEL_TOOLCHAIN_PATH)"
#KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(KERNEL_TOOLCHAIN_32BITS_PATH)"
#KERNEL_CROSS_COMPILE := CROSS_COMPILE="/home/builder/omni/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
#KERNEL_CROSS_COMPILE := CROSS_COMPILE="prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
#KERNEL_CROSS_COMPILE := CROSS_COMPILE="aarch64-linux-android-"
#KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="/home/builder/omni/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
#KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
#KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="arm-linux-androideabi-"
KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(KERNEL_TOOLCHAIN_32BITS_PATH)"
#ccache =

define mv-modules
    mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`;\
    if [ "$$mdpath" != "" ];then\
        mpath=`dirname $$mdpath`;\
        ko=`find $$mpath/kernel -type f -name *.ko`;\
        for i in $$ko; do $(KERNEL_TOOLCHAIN_PATH)strip --strip-unneeded $$i;\
        mv $$i $(KERNEL_MODULES_OUT)/; done;\
    fi
endef

define clean-module-folder
    mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`;\
    if [ "$$mdpath" != "" ];then\
        mpath=`dirname $$mdpath`; rm -rf $$mpath;\
    fi
endef

# Who tf uses mac for this?
#ifeq ($(HOST_OS),darwin)
#ifeq (1,$(filter 1,$(shell echo "$$(( $(PLATFORM_SDK_VERSION) >= 24 ))" )))
#  MAKE_FLAGS += C_INCLUDE_PATH=$(shell pwd)/external/elfutils/libelf/
#else
#  MAKE_FLAGS += C_INCLUDE_PATH=$(shell pwd)/external/elfutils/src/libelf/
#endif
#endif

#ifeq ($(TARGET_KERNEL_MODULES),)
#    TARGET_KERNEL_MODULES := no-external-modules
#endif

$(KERNEL_OUT_STAMP):
	$(hide) mkdir -p $(KERNEL_OUT)
	$(hide) rm -rf $(KERNEL_MODULES_OUT)
	$(hide) mkdir -p $(KERNEL_MODULES_OUT)
	$(hide) rm -rf $(KERNEL_DTB_OUT)
	$(hide) mkdir -p $(KERNEL_DTB_OUT)
	$(hide) rm -rf $(KERNEL_DTBO_OUT)
	$(hide) touch $@

#$(KERNEL_CONFIG): $(KERNEL_OUT_STAMP) $(KERNEL_DEFCONFIG_SRC)
#	@echo "Building Kernel Config"
#	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)
#	$(hide) if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then \
#			echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'"; \
#			echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_OUT)/.config; \
#			$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) oldconfig; fi

#MAKE := $(shell pwd)/prebuilts/build-tools/linux-x86/bin/make

$(KERNEL_CONFIG): $(KERNEL_OUT_STAMP) $(KERNEL_DEFCONFIG_SRC)
	@echo "Building Kernel Config"
	@echo "Path: $(PATH)"
	@echo make: $(shell "which make")
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)

#	$(hide) if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then \
#			echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'"; \
#			echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_OUT)/.config; \
#			$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) oldconfig; fi
#	which gcc
#	gcc -xc -E -v -

.PHONY: TARGET_KERNEL_BINARIES
TARGET_KERNEL_BINARIES: $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL_STAMP) | $(ACP)
	@echo "Building Kernel"
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)
	$(hide) if grep -q 'CONFIG_OF=y' $(KERNEL_CONFIG) ; \
			then \
				echo "Building DTBs" ; \
				$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) dtbs ; \
			else \
				echo "DTBs not enabled" ; \
			fi ;
	$(ACP) -fp $(KERNEL_DTB)/*.dtb $(KERNEL_DTB_OUT)/
	$(hide) if grep -q 'CONFIG_MODULES=y' $(KERNEL_CONFIG) ; \
			then \
				echo "Building Kernel Modules" ; \
				$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) modules && \
				$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) modules_install && \
				$(mv-modules) && \
				$(clean-module-folder) ; \
			else \
				echo "Kernel Modules not enabled" ; \
			fi ;

# TODO: We don't use modules so maybe drop this crap entirely
.PHONY: $(TARGET_KERNEL_MODULES)
$(TARGET_KERNEL_MODULES):
	$(hide) if grep -q 'CONFIG_MODULES=y' $(KERNEL_CONFIG) ; \
			then \
				echo "Building Kernel Modules" ; \
				$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) modules && \
				$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) modules_install && \
				$(mv-modules) && \
				$(clean-module-folder) ; \
			else \
				echo "Kernel Modules not enabled" ; \
			fi ;
#	$(mv-modules)
#	$(clean-module-folder)

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL_STAMP)
	@echo "Building Kernel"
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)

# .config: CONFIG_OF=y
# TODO: Make rule for buliding dtbs?
# Kinda not necessary since we're already building Image.gz-dtb:
# common/CommonConfig.mk
# BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
$(TARGET_KERNEL_DTB): $(ACP)
	$(hide) if grep -q 'CONFIG_OF=y' $(KERNEL_CONFIG) ; \
			then \
				echo "Building DTBs" ; \
				$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) dtbs ; \
			else \
				echo "DTBs not enabled" ; \
			fi ;
	$(ACP) -fp $(KERNEL_DTB)/*.dtb $(KERNEL_DTB_OUT)/

$(KERNEL_HEADERS_INSTALL_STAMP): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG)
	@echo "Building Kernel Headers"
	$(hide) if [ ! -z "$(KERNEL_HEADER_DEFCONFIG)" ]; then \
			rm -f ../$(KERNEL_CONFIG); \
			$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_HEADER_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_HEADER_DEFCONFIG); \
			$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_HEADER_ARCH) $(KERNEL_CROSS_COMPILE) headers_install; fi
	$(hide) if [ "$(KERNEL_HEADER_DEFCONFIG)" != "$(KERNEL_DEFCONFIG)" ]; then \
			echo "Used a different defconfig for header generation"; \
			rm -f ../$(KERNEL_CONFIG); \
			$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG); fi
	$(hide) if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then \
			echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'"; \
			echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_OUT)/.config; \
			$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) oldconfig; fi

# provide this rule because there are dependencies on this throughout the repo
$(KERNEL_HEADERS_INSTALL): $(KERNEL_HEADERS_INSTALL_STAMP)

.PHONY: kerneltags
kerneltags: $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) tags

.PHONY: kernelconfig
kernelconfig: $(KERNEL_OUT_STAMP)
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		 $(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
		 $(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) savedefconfig
	cp $(KERNEL_OUT)/defconfig $(KERNEL_DEFCONFIG_SRC)

ifeq ($(TARGET_NEEDS_DTBOIMAGE),true)
TARGET_PREBUILT_DTBO := $(KERNEL_DTBO_OUT)
$(TARGET_PREBUILT_DTBO): TARGET_KERNEL_BINARIES $(AVBTOOL)
	echo -e ${CL_GRN}"Building DTBO.img"${CL_RST}
	$(KERNEL_SRC)/scripts/mkdtboimg.py create $(KERNEL_DTBO_OUT) --page_size=${BOARD_KERNEL_PAGESIZE} `find $(KERNEL_DTB) -name "*.dtbo"`
	$(AVBTOOL) add_hash_footer \
		--image $@ \
		--partition_size $(BOARD_DTBOIMG_PARTITION_SIZE) \
		--partition_name dtbo $(INTERNAL_AVB_DTBO_SIGNING_ARGS) \
		$(BOARD_AVB_DTBO_ADD_HASH_FOOTER_ARGS)
endif # TARGET_NEEDS_DTBOIMAGE

## Install it
#out/target/.../zImage: $(sort $(shell find -L $(KERNEL_SRCDIR)))
#.PHONY: $(PRODUCT_OUT)/kernel
#$(PRODUCT_OUT)/kernel: $(KERNEL_BIN) | $(ACP)
#	@# Use Android's "cp" replacement, "acp".
#	@# See https://android.googlesource.com/platform/build/+/master/tools/acp/README
#	$(ACP) $(KERNEL_BIN) $(PRODUCT_OUT)/kernel
#	@#cp $(KERNEL_BIN) $(PRODUCT_OUT)/kernel

$(PRODUCT_OUT)/kernel:
	cp kernel/sony/msm-4.9/common-kernel/kernel-dtb-kagura $(PRODUCT_OUT)/kernel

ifeq ($(TARGET_NEEDS_DTBOIMAGE),true)
.PHONY: $(PRODUCT_OUT)/dtbo.img
$(PRODUCT_OUT)/dtbo.img: $(KERNEL_DTBO_OUT)
	$(ACP) $(KERNEL_DTBO_OUT) $(PRODUCT_OUT)/dtbo.img
endif # TARGET_NEEDS_DTBOIMAGE
#	cp $(KERNEL_DTBO_OUT) $(PRODUCT_OUT)/dtbo.img

endif # Sony Kernel version
endif # Sony AOSP devices
endif # BUILD_KERNEL
