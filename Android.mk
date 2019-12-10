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

# Kernel build configuration variables
# ====================================
#
#   BUILD_KERNEL                         = Enable building kernel using this Android.mk file
#                                            Can be turned off in case a different build system
#                                            is desired
#   TARGET_KERNEL_ARCH                   = Kernel Arch
#   TARGET_KERNEL_CROSS_COMPILE_PREFIX   = Compiler prefix (e.g. arm-eabi-)
#                                            Defaults to aarch64-linux-android- for arm64
#   TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX = 32-bit compiler prefix for VDSO
#   TARGET_KERNEL_CONFIG                 = Path to defconfig file
#   BOARD_KERNEL_IMAGE_NAME              = Type of kernel image to produce, defaults to Image.gz
#   BOARD_DTBO_IMAGE_NAME                = Name of generated *unsigned* dtbo image, defaults to
#                                            dtbo-$(KERNEL_ARCH).img
#
#   TARGET_KERNEL_LINARO_COMPILE         = Compile kernel with Linaro GCC instead of clang,
#                                          defaults to false
#   TARGET_KERNEL_LINARO_TOOLCHAIN_ROOT  = Root directory of Linaro GCC, should contain
#                                            bin/ and lib64/ directories
#                                            Needs to be set since no default Linaro toolchain
#                                            is supplied with AOSP
#
#   TARGET_KERNEL_CLANG_VERSION          = Different revision of clang from
#                                            prebuilts/clang/[...]/clang-$VERSION to use,
#                                            e.g. r353983c for clang-r353983c
#
#   USE_CCACHE                           = Enable ccache (global Android flag)
#   CCACHE_EXEC                          = Path to ccache executable, defaults to /usr/bin/ccache


ifeq ($(BUILD_KERNEL),true)
ifeq ($(PRODUCT_PLATFORM_SOD),true)
ifeq ($(SOMC_KERNEL_VERSION),4.14)

KERNEL_SRC := $(call my-dir)
# Absolute path - needed for GCC/clang non-AOSP build-system make invocations
KERNEL_SRC_ABS := $(PWD)/$(KERNEL_SRC)

## Internal variables
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
# Absolute path - needed for GCC/clang non-AOSP build-system make invocations
KERNEL_OUT_ABS := $(PWD)/$(KERNEL_OUT)
KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_RELEASE := $(KERNEL_OUT)/include/config/kernel.release

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
KERNEL_DTBS_OUT := $(PRODUCT_OUT)/dtbs

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


KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_HEADERS_INSTALL_STAMP := $(KERNEL_OUT)/.headers_install_stamp

# Set up host toolchains
# ======================

ifneq ($(TARGET_KERNEL_CLANG_VERSION),)
KERNEL_CLANG_VERSION := clang-$(TARGET_KERNEL_CLANG_VERSION)
else
# clang-r353983c is clang 9.0.3
KERNEL_CLANG_VERSION := clang-r353983c
endif
CLANG_HOST_TOOLCHAIN := $(PWD)/prebuilts/clang/host/linux-x86/$(KERNEL_CLANG_VERSION)/bin

TARGET_KERNEL_CLANG_PATH := $(PWD)/prebuilts/clang/host/$(HOST_OS)-x86/$(KERNEL_CLANG_VERSION)
ifeq ($(KERNEL_ARCH),arm64)
    KERNEL_CLANG_TRIPLE := aarch64-linux-gnu-
else ifeq ($(KERNEL_ARCH),arm)
    KERNEL_CLANG_TRIPLE := arm-linux-gnu-
endif

# GCC host toolchain is 4.9 (officially deprecated)
GCC_HOST_TOOLCHAIN := $(PWD)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/x86_64-linux/bin
GCC_HOST_TOOLCHAIN_LIBEXEC := $(PWD)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/libexec/gcc/x86_64-linux/4.8.3

# Clang is the sole usable HOSTCC/CXX on Q
CLANG_HOSTCC := $(CLANG_HOST_TOOLCHAIN)/clang
CLANG_HOSTCXX := $(CLANG_HOST_TOOLCHAIN)/clang++
# Unused for now
#CLANG_HOSTAR := $(CLANG_HOST_TOOLCHAIN)/llvm-ar
#CLANG_HOSTLD := $(CLANG_HOST_TOOLCHAIN)/lld

# Unusable because of non-working symlinks to own resources
#GCC_HOSTCC := $(GCC_HOST_TOOLCHAIN)/gcc
#GCC_HOSTCXX := $(GCC_HOST_TOOLCHAIN)/g++
GCC_HOSTAR := $(GCC_HOST_TOOLCHAIN)/ar
GCC_HOSTLD := $(GCC_HOST_TOOLCHAIN)/ld

KERNEL_HOST_TOOLCHAIN := $(GCC_HOST_TOOLCHAIN)
KERNEL_HOST_TOOLCHAIN_LIBEXEC := $(GCC_HOST_TOOLCHAIN_LIBEXEC)

# On Q, only clang works OOTB as a host bootstrap compiler
KERNEL_HOSTCC := $(CLANG_HOSTCC)
KERNEL_HOSTCXX := $(CLANG_HOSTCXX)
# GCC binutils are still needed
KERNEL_HOSTAR := $(GCC_HOSTAR)
KERNEL_HOSTLD := $(GCC_HOSTLD)

# Set up target toolchains
# ========================

# Target toolchain
# Let's move off gcc, but some tools are still needed
GCC_TOOLCHAIN_ROOT := $(PWD)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
GCC_TOOLCHAIN := $(GCC_TOOLCHAIN_ROOT)/bin
GCC_TOOLCHAIN_32BITS := $(PWD)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin

# Linaro GCC - experimental
LINARO_ROOT := $(TARGET_KERNEL_LINARO_TOOLCHAIN_ROOT)
LINARO_TOOLCHAIN := $(LINARO_ROOT)/bin
LINARO_TOOLCHAIN_STEM := $(LINARO_TOOLCHAIN)/aarch64-linux-gnu-

ifeq ($(TARGET_KERNEL_LINARO_COMPILE),true)
KERNEL_TOOLCHAIN := $(LINARO_TOOLCHAIN)
else
KERNEL_TOOLCHAIN := $(GCC_TOOLCHAIN)
endif
KERNEL_TOOLCHAIN_32BITS := $(GCC_TOOLCHAIN_32BITS)


# Set up cross compilers
# ======================

CLANG_CC := $(TARGET_KERNEL_CLANG_PATH)/bin/clang
LINARO_CC := $(LINARO_TOOLCHAIN_STEM)gcc

ifeq ($(TARGET_KERNEL_LINARO_COMPILE),true)
KERNEL_CC := $(LINARO_CC)
else
# Otherwise, use clang as cross compiler per default
KERNEL_CC := $(CLANG_CC)
endif

# Target architecture cross compile
TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_PREFIX))
ifeq ($(TARGET_KERNEL_CROSS_COMPILE_PREFIX),)
KERNEL_TOOLCHAIN_PREFIX ?= aarch64-linux-android-
else
KERNEL_TOOLCHAIN_PREFIX ?= $(TARGET_KERNEL_CROSS_COMPILE_PREFIX)
endif

# Kernel cross compile toolchain - Used for binutils via $(CROSS_COMPILE)ar, $(CROSS_COMPILE)ld etc.
ifneq ($(KERNEL_TOOLCHAIN_PREFIX),)
  ifeq ($(TARGET_KERNEL_LINARO_COMPILE),true)
    # Linaro GCC uses "aarch64-linux-gnu-" as prefix
    KERNEL_TOOLCHAIN_STEM := $(LINARO_TOOLCHAIN_STEM)
  else
    KERNEL_TOOLCHAIN_STEM := $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)
  endif
endif

# If building for 64-bits with VDSO32 support - 32-bit toolchain here
# Also, if building for AArch64, preferrably set an AArch32 toolchain here.
TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX))
ifeq ($(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX),)
  KERNEL_TOOLCHAIN_32BITS_PREFIX := arm-linux-androideabi-
else
  KERNEL_TOOLCHAIN_32BITS_PREFIX := $(TARGET_KERNEL_CROSS_COMPILE_32BITS_PREFIX)
endif

# Kernel toolchain 32-bits - Use for binutils via $(CROSS_COMPILE)ar, $(CROSS_COMPILE)ld etc.
ifneq ($(KERNEL_TOOLCHAIN_32BITS_PREFIX),)
  KERNEL_TOOLCHAIN_32BITS_STEM := $(KERNEL_TOOLCHAIN_32BITS)/$(KERNEL_TOOLCHAIN_32BITS_PREFIX)
endif

# Set up ccache & host tools
# ==========================

ifneq ($(USE_CCACHE),)
  ifneq ($(CCACHE_EXEC),)
    ccache := $(CCACHE_EXEC)
  else
    # On Q, no prebuilt ccache is shipped. Rely on host:
    ccache := /usr/bin/ccache
  endif
  # Check that the executable is here.
  ccache := $(strip $(wildcard $(ccache)))
endif

# /usr/bin/perl is more reliable than /bin/perl
KERNEL_PERL := /usr/bin/perl
# Set up flex, bison, awk (not allowed by Android's path_interposer)
KERNEL_FLEX := /usr/bin/flex
KERNEL_YACC := /usr/bin/bison
KERNEL_AWK := /usr/bin/awk

# Configure final compile env
# ===========================

KERNEL_CROSS_COMPILE :=
KERNEL_CROSS_COMPILE += HOSTCC="$(KERNEL_HOSTCC)"
KERNEL_CROSS_COMPILE += HOSTCXX="$(KERNEL_HOSTCXX)"
KERNEL_CROSS_COMPILE += HOSTAR="$(KERNEL_HOSTAR)"
KERNEL_CROSS_COMPILE += HOSTLD="$(KERNEL_HOSTLD)"
# Host tools
KERNEL_CROSS_COMPILE += PERL=$(KERNEL_PERL)
KERNEL_CROSS_COMPILE += LEX=$(KERNEL_FLEX)
KERNEL_CROSS_COMPILE += YACC=$(KERNEL_YACC)
KERNEL_CROSS_COMPILE += AWK=$(KERNEL_AWK)

ifeq ($(TARGET_KERNEL_LINARO_COMPILE),true)
  KERNEL_CROSS_COMPILE += GCC_TOOLCHAIN=$(LINARO_ROOT)
  KERNEL_CROSS_COMPILE += GCC_TOOLCHAIN_DIR=$(LINARO_ROOT)/bin
else
  KERNEL_CROSS_COMPILE += GCC_TOOLCHAIN=$(GCC_TOOLCHAIN_ROOT)
  KERNEL_CROSS_COMPILE += GCC_TOOLCHAIN_DIR=$(GCC_TOOLCHAIN_ROOT)/bin
endif

KERNEL_CROSS_COMPILE += CLANG_TRIPLE=$(KERNEL_CLANG_TRIPLE)

ifneq ($(USE_CCACHE),)
  KERNEL_CROSS_COMPILE += CC="$(ccache) $(KERNEL_CC)"
  # Kernel toolchain - Use for binutils via $(CROSS_COMPILE)ar, $(CROSS_COMPILE)ld etc.
  KERNEL_CROSS_COMPILE += CROSS_COMPILE="$(ccache) $(KERNEL_TOOLCHAIN_STEM)"
  KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(ccache) $(KERNEL_TOOLCHAIN_32BITS_STEM)"
else
  KERNEL_CROSS_COMPILE += CC="$(KERNEL_CC)"
  # Kernel toolchain - Use for binutils via $(CROSS_COMPILE)ar, $(CROSS_COMPILE)ld etc.
  KERNEL_CROSS_COMPILE += CROSS_COMPILE="$(KERNEL_TOOLCHAIN_STEM)"
  KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(KERNEL_TOOLCHAIN_32BITS_STEM)"
endif

# Standard $(MAKE) evaluates to:
# prebuilts/build-tools/linux-x86/bin/ckati --color_warnings --kati_stats MAKECMDGOALS=
# which is forbidden by Android Q's new "path_interposer" tool
KERNEL_PREBUILT_MAKE := $(PWD)/prebuilts/build-tools/linux-x86/bin/make
# clang/GCC (glibc) host toolchain needs to be prepended to $PATH for certain
# host bootstrap tools to be built. Also, binutils such as `ld` and `ar` are
# needed for now.
KERNEL_MAKE_EXTRA_PATH := $(KERNEL_HOST_TOOLCHAIN):$(KERNEL_HOST_TOOLCHAIN_LIBEXEC)

# Clang extra paths
KERNEL_LD_LIBRARY_PATH_OVERRIDE := \
	LD_LIBRARY_PATH=$(TARGET_KERNEL_CLANG_PATH)/lib64:$$LD_LIBRARY_PATH

KERNEL_MAKE := \
   PATH="$(KERNEL_MAKE_EXTRA_PATH):$$PATH" \
   $(KERNEL_LD_LIBRARY_PATH_OVERRIDE) \
   $(KERNEL_PREBUILT_MAKE)


$(KERNEL_OUT_STAMP):
	$(hide) mkdir -p $(KERNEL_OUT)
	$(hide) rm -rf $(KERNEL_DTBS_OUT)
	$(hide) mkdir -p $(KERNEL_DTBS_OUT)
	$(hide) rm -rf $(KERNEL_DTBO_OUT)
	$(hide) touch $@

# Internal implementation of make-kernel-target
# $(1): output path (The value passed to O=)
# $(2): target to build (eg. defconfig, modules, dtbo.img)
define internal-make-kernel-target
$(KERNEL_MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC_ABS) O=$($1) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(2)
endef

# Make a kernel target
# $(1): The kernel target to build (eg. defconfig, modules, modules_install)
define make-kernel-target
$(call internal-make-kernel-target,$(KERNEL_OUT_ABS),$(1))
endef

# Make a DTBO target
# $(1): The DTBO target to build (eg. dtbo.img, defconfig)
define make-dtbo-target
$(call internal-make-kernel-target,$(PRODUCT_OUT)/dtbo,$(1))
endef

# Make a DTB targets
# $(1): The DTB target to build (eg. dtbs, defconfig)
define make-dtb-target
$(call internal-make-kernel-target,$(KERNEL_DTBS_OUT),$(1))
endef

$(KERNEL_CONFIG): $(KERNEL_OUT_STAMP) $(KERNEL_DEFCONFIG_SRC)
	@echo "Building Kernel Config"
	$(call make-kernel-target,$(KERNEL_DEFCONFIG))
	$(call make-kernel-target,savedefconfig)

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL_STAMP)
	@echo "Building Kernel"
	$(call make-kernel-target,$(TARGET_PREBUILT_INT_KERNEL_TYPE))

# Install it
$(PRODUCT_OUT)/kernel: $(TARGET_PREBUILT_INT_KERNEL) | $(ACP)
	$(ACP) $(TARGET_PREBUILT_INT_KERNEL) $(PRODUCT_OUT)/kernel

$(KERNEL_DTB_STAMP): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG) | $(ACP)
	$(hide) if grep -q '^CONFIG_OF=y' $(KERNEL_CONFIG) ; then \
				echo "Building DTBs" ; \
				$(call make-kernel-target,dtbs) ;
			else \
				echo "DTBs not enabled" ; \
			fi ;
	$(ACP) -fp $(KERNEL_DTB)/*.dtb $(KERNEL_DTBS_OUT)/
	$(hide) touch $@

$(TARGET_KERNEL_DTB): $(KERNEL_DTB_STAMP)

$(KERNEL_HEADERS_INSTALL_STAMP): $(KERNEL_OUT_STAMP) $(KERNEL_CONFIG)
	@echo "Building Kernel Headers"
	$(hide) if [ ! -z "$(KERNEL_HEADER_DEFCONFIG)" ]; then \
			rm -f ../$(KERNEL_CONFIG); \
			$(call make-kernel-target,$(KERNEL_HEADER_DEFCONFIG)) ; \
			$(call make-kernel-target,headers_install) ; \
			fi
	$(hide) if [ "$(KERNEL_HEADER_DEFCONFIG)" != "$(KERNEL_DEFCONFIG)" ]; then \
			echo "Used a different defconfig for header generation"; \
			rm -f ../$(KERNEL_CONFIG); \
			$(call make-kernel-target,$(KERNEL_DEFCONFIG)) ; \
			fi
	$(hide) if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then \
			echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'"; \
			echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_OUT_ABS)/.config; \
			$(call make-kernel-target,oldconfig) ; \
			fi
	$(hide) touch $@

# Provide this rule because there are dependencies on this throughout the repo
$(KERNEL_HEADERS_INSTALL): $(KERNEL_HEADERS_INSTALL_STAMP)

.PHONY: kernelheaders
kernelheaders: $(KERNEL_HEADERS_INSTALL)

.PHONY: kerneltags
kerneltags: $(KERNEL_CONFIG)
	$(call make-kernel-target,tags)

# Warning: Use with caution as this will modify your kernel source!
.PHONY: kernelsavedefconfig
kernelsavedefconfig: $(KERNEL_OUT)
	$(call make-kernel-target,$(KERNEL_DEFCONFIG))
	env KCONFIG_NOTIMESTAMP=true \
		 $(call make-kernel-target,savedefconfig)
	$(ACP) $(KERNEL_OUT)/defconfig $(KERNEL_DEFCONFIG_SRC)

# DTBO
ifeq ($(TARGET_NEEDS_DTBOIMAGE),true)
MKDTIMG := $(HOST_OUT_EXECUTABLES)/mkdtimg$(HOST_EXECUTABLE_SUFFIX)

define build-dtboimage-target
$(call pretty,"Building DTBO image: $(BOARD_PREBUILT_DTBOIMAGE)")
$(MKDTIMG) create $@ --page_size=$(BOARD_KERNEL_PAGESIZE) $$(find "$$KERNEL_DTB" -name '*.dtbo')
$(hide) chmod a+r $@
endef

$(BOARD_PREBUILT_DTBOIMAGE): $(MKDTIMG) $(TARGET_KERNEL_DTB)
	$(build-dtboimage-target)

.PHONY: dtboimage
dtboimage: $(TARGET_PREBUILT_DTBO)
endif # TARGET_NEEDS_DTBOIMAGE

endif # Sony Kernel version
endif # Sony AOSP devices
endif # BUILD_KERNEL
