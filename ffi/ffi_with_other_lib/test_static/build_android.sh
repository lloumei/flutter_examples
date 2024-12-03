#! /usr/bin/env bash

# 参考：
# https://developer.android.com/ndk/guides/other_build_systems?hl=zh-cn

set -e

SOURCE_DIR=`realpath .`
OUTPUT_DIR=$SOURCE_DIR/output/android

if [[ -d "$OUTPUT_DIR" ]]; then
  rm -rf $OUTPUT_DIR
fi

mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

ALL_ARCH="arm64 armv7a x86_64 x86"

TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/$NDK_PLATFORM
TARGET=
API=21

function collect_bin {

    local arch=$1
    local target_dir=
    case "$arch" in
        arm64)
            target_dir=$OUTPUT_DIR/jniLibs/arm64-v8a
        ;;
        armv7a)
            target_dir=$OUTPUT_DIR/jniLibs/armeabi-v7a
        ;;
        x86)
            target_dir=$OUTPUT_DIR/jniLibs/x86
        ;;
        x86_64)
            target_dir=$OUTPUT_DIR/jniLibs/x86_64
        ;;
        *)
            echo "unsupported arch: $arch"
            exit 1
        ;;
    esac

    mkdir -p ${target_dir}
    mkdir -p ${target_dir}/include

    cp $SOURCE_DIR/*.h ${target_dir}/include
    cp $OUTPUT_DIR/$arch/*.a ${target_dir}
}

for ARCH in $ALL_ARCH
do
    if [[ "$ARCH" = "arm64" ]]; then
        TARGET=aarch64-linux-android
    elif [[ "$ARCH" = "armv7a" ]]; then
        TARGET=armv7a-linux-androideabi
    elif [[ "$ARCH" = "x86_64" ]]; then
        TARGET=x86_64-linux-android
    elif [[ "$ARCH" = "x86" ]]; then
        TARGET=i686-linux-android
    else 
        echo "unknown architecture $ARCH";
        exit 1
    fi

    CC="$TOOLCHAIN/bin/clang --target=$TARGET$API"
    AR=$TOOLCHAIN/bin/llvm-ar

    OUTPUT_NAME="libtest_static.a"

    echo "ARCH=$ARCH"
    echo "API=$API"
    echo "OUTPUT_NAME=$OUTPUT_NAME"
    echo "CC=$CC"
    echo "AR=$AR"

    mkdir -p $OUTPUT_DIR/$ARCH
    cd $OUTPUT_DIR/$ARCH

    $CC -c $SOURCE_DIR/test_static.c
    $AR -rv $OUTPUT_NAME test_static.o

    # 收集文件
    collect_bin $ARCH

    cd -
done

