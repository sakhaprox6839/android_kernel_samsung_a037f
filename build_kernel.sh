#!/bin/bash

# Exit operation if no first argument specified
if [ $# -ne 1 ]; then
    echo "Usage: $0 <operation>"
    echo "Example: ./build_kernel.sh kernelsu"
    echo ""
    echo "List of tasks: gcc, clang, prepare, menuconfig, build, anykernel3"
    exit 1
fi

export USE_CCACHE=1

# Set variable toolchain flags for building
export CROSS_COMPILE=$(pwd)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-buildroot-linux-gnu-
export CC=$(pwd)/prebuilts/clang/host/linux-x86/clang-r416183b/bin/clang
export CLANG_TRIPLE=aarch64-buildroot-linux-gnu-

# Set variable arch flags for building
export ARCH=arm64
export SUBARCH=arm64

# Set variable flags for building
export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# Set variable android version
export PLATFORM_VERSION=13
export ANDROID_MAJOR_VERSION=t

# Set variable user info for building kernel
export KBUILD_BUILD_USER=$(sakhaprox)
export KBUILD_BUILD_HOST=$(sakhaprox)

# Logic for LOCAL_VERSION config
GIT_BRANCH_TEMP=$(git branch --show-current)
if [ "$GIT_BRANCH_TEMP" == "main" ]; then
    GIT_BRANCH=stable
else
    GIT_BRANCH=$(echo $GIT_BRANCH_TEMP)
fi

GIT_TAGS=$(git describe --tag --abbrev=0)

export LOCALVERSION="-$(echo $GIT_BRANCH)-A037F_Kernel-"

export BASH_KBUILD_COMMAND="make -C $(pwd) O=$(pwd)/out"

# Function
case $1 in
    "anykernel3")
        git clone --depth=1 https://github.com/FranklinAzriel/AnyKernel3
        cp -rv out/arch/arm64/boot/Image.gz AnyKernel3
        cd AnyKernel3
        zip -r9 UPDATE-AnyKernel3.zip * -x .git README.md *placeholder
        cd ..
    ;;
    "build")
        $BASH_KBUILD_COMMAND -j$(nproc --all)
    ;;
    "clang")
        wget -nc "https://android.googlesource.com/platform//prebuilts/clang/host/linux-x86/+archive/b669748458572622ed716407611633c5415da25c/clang-r416183b.tar.gz"
	    mkdir -pv prebuilts/clang/host/linux-x86/clang-r416183b/
        tar xfv clang-r416183b.tar.gz -C prebuilts/clang/host/linux-x86/clang-r416183b/
    ;;
    "gcc")
        wget -nc "https://toolchains.bootlin.com/downloads/releases/toolchains/aarch64/tarballs/aarch64--glibc--stable-2021.11-1.tar.bz2"
        mkdir -pv prebuilts/gcc/linux-x86/aarch64/
	    tar xfv aarch64--glibc--stable-2021.11-1.tar.bz2 -C prebuilts/gcc/linux-x86/aarch64/
	    mv prebuilts/gcc/linux-x86/aarch64/aarch64--glibc--stable-2021.11-1 prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
    ;;
    "menuconfig")
        $BASH_KBUILD_COMMAND menuconfig
    ;;
    "kernelsu")
        ./scripts/config --file out/.config --enable CONFIG_KSU
        ./scripts/config --file out/.config --disable CONFIG_KPROBES
        ./scripts/config --file out/.config --disable CONFIG_HAVE_KPROBES
        ./scripts/config --file out/.config --disable CONFIG_KPROBE_EVENTS
    ;;
    "prepare")
        $BASH_KBUILD_COMMAND a03s_defconfig
    ;;
    *)
    echo "Invalid operation!"
    exit 1
esac
