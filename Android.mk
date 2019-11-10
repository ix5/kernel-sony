# Copyright (C) 2012 The CyanogenMod Project
# Copyright (C) 2015 Chirayu Desai
# Copyright (C) 2018 Felix Elsner
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
ifeq ($(SOMC_KERNEL_VERSION),4.14)

KERNEL_SRC := $(call my-dir)
# Absolute path - needed for GCC/clang non-AOSP build-system make invocations
KERNEL_SRC_ABS := $(PWD)/$(call my-dir)

## Internal variables
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ-$(SOMC_KERNEL_VERSION)
# Absolute path - needed for GCC/clang non-AOSP build-system make invocations
KERNEL_OUT_ABS := $(PWD)/$(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ-$(SOMC_KERNEL_VERSION)
KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_OUT_STAMP := $(KERNEL_OUT)/.mkdir_stamp
KERNEL_DTB_STAMP := $(KERNEL_OUT)/.dtb_stamp

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

ifneq ($(BOARD_KERNEL_IMAGE_NAME),)
  TARGET_PREBUILT_INT_KERNEL_TYPE := $(BOARD_KERNEL_IMAGE_NAME)
else
  ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
    TARGET_PREBUILT_INT_KERNEL_TYPE := Image
  else
    ifeq ($(KERNEL_ARCH),arm64)
      TARGET_PREBUILT_INT_KERNEL_TYPE := Image.gz
    else
      TARGET_PREBUILT_INT_KERNEL_TYPE := zImage
    endif
  endif
endif

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
  ifeq ($(TARGET_ARCH),arm)
    KERNEL_CONFIG_OVERRIDE := CONFIG_ANDROID_BINDER_IPC_32BIT=y
  endif
endif


KERNEL_BIN := $(TARGET_PREBUILT_INT_KERNEL)

KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_HEADERS_INSTALL_STAMP := $(KERNEL_OUT)/.headers_install_stamp

KERNEL_MODULES_INSTALL := system
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules

# Set up host toolchains
# ======================

# clang-r365631 is clang 9.0.3
CLANG_HOST_TOOLCHAIN := $(PWD)/prebuilts/clang/host/linux-x86/clang-r353983c/bin
# GCC host toolchain is 4.9 (officially deprecated)
GCC_HOST_TOOLCHAIN := $(PWD)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/x86_64-linux/bin
GCC_HOST_TOOLCHAIN_LIBEXEC := $(PWD)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/libexec/gcc/x86_64-linux/4.8.3

# Needed for absolute paths
BUILDER_HOME := /home/builder
# TODO: Make linaro path user-settable
LINARO_ROOT := $(BUILDER_HOME)/downloads/linaro/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu
LINARO_TOOLCHAIN := $(LINARO_ROOT)/bin
LINARO_TOOLCHAIN_PATH := $(LINARO_TOOLCHAIN)/aarch64-linux-gnu-
LINARO_TOOLCHAIN_LIBEXEC := $(LINARO_ROOT)/libexec/gcc/aarch64-linux-gnu/7.4.1

CLANG_HOSTCC := $(CLANG_HOST_TOOLCHAIN)/clang
CLANG_HOSTCXX := $(CLANG_HOST_TOOLCHAIN)/clang++

GCC_HOSTCC := $(GCC_HOST_TOOLCHAIN)/gcc
GCC_HOSTCXX := $(GCC_HOST_TOOLCHAIN)/g++
GCC_HOSTAR := $(GCC_HOST_TOOLCHAIN)/ar
GCC_HOSTLD := $(GCC_HOST_TOOLCHAIN)/ld

# Set up cross compilers
# ======================

GCC_CC := $(PWD)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
LINARO_CC := $(LINARO_TOOLCHAIN_PATH)gcc
CLANG_CC := $(CLANG_HOST_TOOLCHAIN)/clang

# Set up target toolchains
# ========================

# Target toolchain
GCC_TOOLCHAIN := $(PWD)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin
GCC_TOOLCHAIN_32BITS := $(PWD)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin

KERNEL_TOOLCHAIN := $(GCC_TOOLCHAIN)
KERNEL_TOOLCHAIN_32BITS := $(GCC_TOOLCHAIN_32BITS)

KERNEL_HOST_TOOLCHAIN := $(GCC_HOST_TOOLCHAIN)
KERNEL_HOST_TOOLCHAIN_LIBEXEC := $(GCC_HOST_TOOLCHAIN_LIBEXEC)

# On Q, only clang works OOTB as a host bootstrap compiler
KERNEL_HOSTCC := $(CLANG_HOSTCC)
KERNEL_HOSTCXX := $(CLANG_HOSTCXX)
# But you could also use the host system-installed gcc
#KERNEL_HOSTCC := /usr/bin/gcc
#KERNEL_HOSTCXX := /usr/bin/g++
# GCC binutils are still needed
KERNEL_HOSTAR := $(GCC_HOSTAR)
KERNEL_HOSTLD := $(GCC_HOSTLD)
# But we can set linaro's GCC as cross compiler
KERNEL_CC := $(LINARO_CC)

# Full host GCC -> not possible on Q
#KERNEL_HOSTCC := $(GCC_HOSTCC)
#KERNEL_HOSTCXX := $(GCC_HOSTCXX)
#KERNEL_HOSTAR := $(GCC_HOSTAR)
#KERNEL_HOSTLD := $(GCC_HOSTLD)

# Target architecture cross compile
# TEMP: Hardcode
#TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_PREFIX))
#KERNEL_TOOLCHAIN_PREFIX ?= $(TARGET_KERNEL_CROSS_COMPILE_PREFIX)
KERNEL_TOOLCHAIN_PREFIX := aarch64-linux-android-
#KERNEL_TOOLCHAIN_PREFIX := aarch64-linux-gnu-
#TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX := arm-linux-androideabi-

# Kernel toolchain - Use for binutils via $(CROSS_COMPILE)ar, $(CROSS_COMPILE)ld etc.
ifneq ($(KERNEL_TOOLCHAIN_PREFIX),)
  KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)
endif

# If building for 64-bits with VDSO32 support - 32-bit toolchain here
# Also, if building for AArch64, preferrably set an AArch32 toolchain here.
TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX))
ifeq ($(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX),)
  KERNEL_TOOLCHAIN_32BITS_PREFIX := arm-linux-androideabi-
else
  KERNEL_TOOLCHAIN_32BITS_PREFIX := $(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX)
endif

ifneq ($(KERNEL_TOOLCHAIN_32BITS_PREFIX),)
  KERNEL_TOOLCHAIN_32BITS_PATH := $(KERNEL_TOOLCHAIN_32BITS)/$(KERNEL_TOOLCHAIN_32BITS_PREFIX)
endif

ifneq ($(USE_CCACHE),)
  # On Q, no prebuilt ccache is shipped
  #ccache := $(PWD)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache
  ccache := /usr/bin/ccache
  # Check that the executable is here.
  ccache := $(strip $(wildcard $(ccache)))
endif

# /usr/bin/perl is more reliable than /bin/perl
KERNEL_PERL := /usr/bin/perl
# Set up flex (not allowed by Android's path_interposer)
KERNEL_FLEX := /usr/bin/flex
KERNEL_YACC := /usr/bin/bison
KERNEL_AWK := /usr/bin/awk

KERNEL_CROSS_COMPILE :=
#ifeq ($(TARGET_KERNEL_CLANG_COMPILE),true)
#  KERNEL_CROSS_COMPILE += CC="$(CLANG_CC)"
#  KERNEL_CROSS_COMPILE += CLANG_TRIPLE="aarch64-linux-gnu"
#endif
#KERNEL_CROSS_COMPILE += CC="$(CLANG_CC)"
#KERNEL_CROSS_COMPILE += CC="$(KERNEL_CC)"
KERNEL_CROSS_COMPILE += HOSTCC="$(KERNEL_HOSTCC)"
KERNEL_CROSS_COMPILE += HOSTAR="$(KERNEL_HOSTAR)"
KERNEL_CROSS_COMPILE += HOSTLD="$(KERNEL_HOSTLD)"
KERNEL_CROSS_COMPILE += HOSTCXX="$(KERNEL_HOSTCXX)"
# Host tools
KERNEL_CROSS_COMPILE += PERL=$(KERNEL_PERL)
KERNEL_CROSS_COMPILE += LEX=$(KERNEL_FLEX)
KERNEL_CROSS_COMPILE += YACC=$(KERNEL_YACC)
KERNEL_CROSS_COMPILE += AWK=$(KERNEL_AWK)
ifneq ($(USE_CCACHE),)
  KERNEL_CROSS_COMPILE += CROSS_COMPILE="$(ccache) $(KERNEL_TOOLCHAIN_PATH)"
  KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(ccache) $(KERNEL_TOOLCHAIN_32BITS_PATH)"
else
  KERNEL_CROSS_COMPILE += CROSS_COMPILE="$(KERNEL_TOOLCHAIN_PATH)"
  KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(KERNEL_TOOLCHAIN_32BITS_PATH)"
endif
#KERNEL_CROSS_COMPILE += CROSS_COMPILE="$(KERNEL_TOOLCHAIN_PATH)"
#KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(KERNEL_TOOLCHAIN_32BITS_PATH)"

# Standard $(MAKE) evaluates to:
# prebuilts/build-tools/linux-x86/bin/ckati --color_warnings --kati_stats MAKECMDGOALS=
# which is forbidden by Android Q's new "path_interposer" tool
KERNEL_PREBUILT_MAKE := $(PWD)/prebuilts/build-tools/linux-x86/bin/make
# clang/GCC (glibc) host toolchain needs to be prepended to $PATH for certain
# host bootstrap tools to be built. Also, binutils such as `ld` and `ar` are
# needed for now.
KERNEL_MAKE_EXTRA_PATH := "$(KERNEL_HOST_TOOLCHAIN):$(KERNEL_HOST_TOOLCHAIN_LIBEXEC)"
KERNEL_MAKE := \
	PATH="$(KERNEL_MAKE_EXTRA_PATH):$$PATH" \
	$(KERNEL_PREBUILT_MAKE)

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

$(KERNEL_OUT_STAMP):
	$(hide) mkdir -p $(KERNEL_OUT)
	$(hide) rm -rf $(KERNEL_MODULES_OUT)
	$(hide) mkdir -p $(KERNEL_MODULES_OUT)
	$(hide) rm -rf $(KERNEL_DTB_OUT)
	$(hide) mkdir -p $(KERNEL_DTB_OUT)
	$(hide) rm -rf $(KERNEL_DTBO_OUT)
	$(hide) touch $@

$(KERNEL_CONFIG): $(KERNEL_OUT_STAMP) $(KERNEL_DEFCONFIG_SRC)
	@echo "Building Kernel Config"
	$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)

# TODO: Use non-PHONY target for qcom wifi modules
ifeq ($(TARGET_KERNEL_MODULES),)
    TARGET_KERNEL_MODULES := no-external-modules
endif
.PHONY: $(TARGET_KERNEL_MODULES)
$(TARGET_KERNEL_MODULES):
	$(hide) if grep -q 'CONFIG_MODULES=y' $(KERNEL_CONFIG) ; \
			then \
				echo "Building Kernel Modules" ; \
				$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) modules && \
				$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) modules_install && \
				$(mv-modules) && \
				$(clean-module-folder) ; \
			else \
				echo "Kernel Modules not enabled" ; \
			fi ;

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL_STAMP)
	@echo "Building Kernel"
	$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)

$(KERNEL_DTB_STAMP): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG) | $(ACP)
	$(hide) if grep -q 'CONFIG_OF=y' $(KERNEL_CONFIG) ; \
			then \
				echo "Building DTBs" ; \
				$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) dtbs ; \
			else \
				echo "DTBs not enabled" ; \
			fi ;
	$(ACP) -fp $(KERNEL_DTB)/*.dtb $(KERNEL_DTB_OUT)/
	$(hide) touch $@

$(TARGET_KERNEL_DTB): $(KERNEL_DTB_STAMP)

$(KERNEL_HEADERS_INSTALL_STAMP): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG)
	@echo "Building Kernel Headers"
	$(hide) if [ ! -z "$(KERNEL_HEADER_DEFCONFIG)" ]; then \
			rm -f ../$(KERNEL_CONFIG); \
			$(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_HEADER_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_HEADER_DEFCONFIG); \
			$(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_HEADER_ARCH) $(KERNEL_CROSS_COMPILE) headers_install; fi
	$(hide) if [ "$(KERNEL_HEADER_DEFCONFIG)" != "$(KERNEL_DEFCONFIG)" ]; then \
			echo "Used a different defconfig for header generation"; \
			rm -f ../$(KERNEL_CONFIG); \
			$(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG); fi
	$(hide) if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then \
			echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'"; \
			echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_OUT_ABS)/.config; \
			$(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) oldconfig; fi
	$(hide) touch $@

# provide this rule because there are dependencies on this throughout the repo
$(KERNEL_HEADERS_INSTALL): $(KERNEL_HEADERS_INSTALL_STAMP)

.PHONY: kerneltags
kerneltags: $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG)
	$(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) tags

.PHONY: kernelconfig
kernelconfig: $(KERNEL_OUT_STAMP) | $(ACP)
	$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_DEFCONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		 $(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
		 $(KERNEL_MAKE) -C $(KERNEL_SRC_ABS) O=$(KERNEL_OUT_ABS) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) savedefconfig
	$(ACP) $(KERNEL_OUT)/defconfig $(KERNEL_DEFCONFIG_SRC)

ifeq ($(TARGET_NEEDS_DTBOIMAGE),true)
TARGET_PREBUILT_DTBO := $(KERNEL_DTBO_OUT)
$(TARGET_PREBUILT_DTBO): $(TARGET_KERNEL_DTB) $(AVBTOOL)
	echo -e ${CL_GRN}"Building DTBO.img"${CL_RST}
	$(KERNEL_SRC_ABS)/scripts/mkdtboimg.py create $(KERNEL_DTBO_OUT) --page_size=${BOARD_KERNEL_PAGESIZE} `find $(KERNEL_DTB) -name "*.dtbo"`
	$(AVBTOOL) add_hash_footer \
		--image $@ \
		--partition_size $(BOARD_DTBOIMG_PARTITION_SIZE) \
		--partition_name dtbo $(INTERNAL_AVB_DTBO_SIGNING_ARGS) \
		$(BOARD_AVB_DTBO_ADD_HASH_FOOTER_ARGS)
endif # TARGET_NEEDS_DTBOIMAGE

## Install it
$(PRODUCT_OUT)/kernel: $(KERNEL_BIN) | $(ACP)
	$(ACP) $(KERNEL_BIN) $(PRODUCT_OUT)/kernel

ifeq ($(TARGET_NEEDS_DTBOIMAGE),true)
$(PRODUCT_OUT)/dtbo.img: $(KERNEL_DTBO_OUT)
	$(ACP) $(KERNEL_DTBO_OUT) $(PRODUCT_OUT)/dtbo.img
endif # TARGET_NEEDS_DTBOIMAGE

endif # Sony Kernel version
endif # Sony AOSP devices
endif # BUILD_KERNEL
